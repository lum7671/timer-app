import AVFoundation
import Cocoa

class MVTimerController: NSWindowController {
  private var mainView: MVMainView!
  private var clockView: MVClockView!

  private var audioPlayer: AVAudioPlayer? // player must be kept in memory
  private var soundURL = Bundle.main.url(forResource: "alert-sound", withExtension: "caf")

  convenience init() {
    let mainView = MVMainView(frame: NSRect.zero)

    let window = MVWindow(mainView: mainView)

    self.init(window: window)

    self.mainView = mainView
    self.mainView.controller = self
    self.clockView = MVClockView()
    self.clockView.target = self
    self.clockView.action = #selector(handleClockTimer)
    self.mainView.addSubview(clockView)

    self.windowFrameAutosaveName = "TimerWindowAutosaveFrame"

    window.makeKeyAndOrderFront(self)
    
    // CLI 설정 확인 및 적용
    print("🚀 MVTimerController 생성됨, CLI 설정 확인 중...")
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.checkAndApplyLauncherSettingsFromController()
    }
  }

  convenience init(closeToWindow: NSWindow?) {
    self.init()

    if closeToWindow != nil {
      var point = closeToWindow!.frame.origin
      point.x += CGFloat(Int(arc4random_uniform(UInt32(80))) - 40)
      point.y += CGFloat(Int(arc4random_uniform(UInt32(80))) - 40)
      self.window?.setFrameOrigin(point)
    }
  }

  deinit {
    self.clockView.target = nil
    self.clockView.stop()
  }

  func showInDock(_ state: Bool) {
    self.clockView.inDock = state
    self.mainView.menuItem?.state = state ? .on : .off
  }

  func windowVisibilityChanged(_ visible: Bool) {
    clockView.windowIsVisible = visible
  }

  func playAlarmSound() {
    if soundURL != nil {
        audioPlayer = try? AVAudioPlayer(contentsOf: soundURL!)
        //audioPlayer?.volume = self.volume
        audioPlayer?.play()
    }
  }

  @objc func handleClockTimer(_ clockView: MVClockView) {
    let notification = NSUserNotification()
    notification.title = "It's time! 🕘"

    NSUserNotificationCenter.default.deliver(notification)

    NSApplication.shared.requestUserAttention(.criticalRequest)

    playAlarmSound()
  }

  override func keyUp(with theEvent: NSEvent) {
    self.clockView.keyUp(with: theEvent)
  }

  override func keyDown(with event: NSEvent) {
  }

  func pickSound(_ index: Int) {
    let sound: String?
    switch index {
    case -1:
        sound = nil

    case 0:
        sound = "alert-sound"

    case 1:
        sound = "alert-sound-2"

    case 2:
        sound = "alert-sound-3"

    default:
        sound = "alert-sound"
    }
    if sound != nil {
        self.soundURL = Bundle.main.url(forResource: sound, withExtension: "caf")

        // 'preview'
        playAlarmSound()
    } else {
        self.soundURL = nil
    }
  }

  // CLI 런처에서 타이머 시간을 설정하는 메서드
  func setTimerFromLauncher(_ seconds: Double) {
    guard seconds > 0 else { 
      print("⚠️ 잘못된 시간 값: \(seconds)")
      return 
    }
    
    print("🎯 MVTimerController에서 타이머 설정 중: \(seconds)초")
    
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      print("🎯 클럭뷰에 시간 설정: \(seconds)초")
      
      // 강제로 windowIsVisible을 true로 설정하여 UI 업데이트 보장
      self.clockView.windowIsVisible = true
      self.clockView.seconds = CGFloat(seconds)
      
      // 추가로 UI 업데이트 강제 실행
      if let updateMethod = self.clockView.value(forKey: "updateLabels") as? () -> Void {
        updateMethod()
      }
      if let layoutMethod = self.clockView.value(forKey: "layoutSubviews") as? () -> Void {
        layoutMethod()
      }
      
      let minutes = Int(seconds / 60)
      let remainingSeconds = Int(seconds.truncatingRemainder(dividingBy: 60))
      print("⏰ CLI에서 설정된 타이머 시간 적용됨: \(Int(seconds))초 (\(minutes)분 \(remainingSeconds)초)")
      
      // 창을 포그라운드로 가져오기
      self.window?.makeKeyAndOrderFront(nil)
    }
  }

  // CLI 런처에서 특정 시간(HH:MM)으로 타이머를 설정하는 메서드
  func setTimerToTime(_ timeString: String) {
    print("🔧 setTimerToTime 시작: \(timeString)")
    
    let components = timeString.split(separator: ":")
    guard components.count == 2,
          let hour = Int(components[0]),
          let minute = Int(components[1]),
          hour >= 0, hour < 24,
          minute >= 0, minute < 60 else {
      print("⚠️ 잘못된 시간 형식: \(timeString) (HH:MM 형식이어야 함)")
      return
    }
    
    let calendar = Calendar.current
    let now = Date()
    
    let nowFormatter = DateFormatter()
    nowFormatter.dateFormat = "HH:mm:ss"
    print("🔧 현재 시간: \(nowFormatter.string(from: now))")
    
    var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
    dateComponents.hour = hour
    dateComponents.minute = minute
    dateComponents.second = 0
    
    guard let targetTime = calendar.date(from: dateComponents) else {
      print("⚠️ 타겟 시간 생성 실패: \(timeString)")
      return
    }
    
    print("🔧 초기 타겟 시간: \(nowFormatter.string(from: targetTime))")
    
    // 만약 지정된 시간이 현재 시간보다 이전이면 다음날로 설정
    let finalTargetTime = targetTime <= now ? 
      calendar.date(byAdding: .day, value: 1, to: targetTime) ?? targetTime : targetTime
    
    print("🔧 최종 타겟 시간: \(nowFormatter.string(from: finalTargetTime))")
    
    let secondsUntilTarget = finalTargetTime.timeIntervalSinceNow
    
    guard secondsUntilTarget > 0 else {
      print("⚠️ 타겟 시간이 현재 시간보다 이전입니다")
      return
    }
    
    print("🎯 특정 시간으로 타이머 설정: \(timeString) (현재로부터 \(Int(secondsUntilTarget))초 후)")
    print("🔧 clockView.seconds에 설정할 값: \(secondsUntilTarget)")
    
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      // 강제로 windowIsVisible을 true로 설정하여 UI 업데이트 보장
      self.clockView.windowIsVisible = true
      self.clockView.seconds = CGFloat(secondsUntilTarget)
      
      // UI 강제 업데이트
      self.clockView.setNeedsDisplay(self.clockView.bounds)
      
      let hours = Int(secondsUntilTarget / 3600)
      let minutes = Int((secondsUntilTarget.truncatingRemainder(dividingBy: 3600)) / 60)
      let seconds = Int(secondsUntilTarget.truncatingRemainder(dividingBy: 60))
      
      let formatter = DateFormatter()
      formatter.dateFormat = "HH:mm:ss"
      let targetTimeStr = formatter.string(from: finalTargetTime)
      
      if hours > 0 {
        print("⏰ 타이머가 \(targetTimeStr)로 설정됨 (\(hours)시간 \(minutes)분 \(seconds)초 후)")
      } else {
        print("⏰ 타이머가 \(targetTimeStr)로 설정됨 (\(minutes)분 \(seconds)초 후)")
      }
      
      // 창을 포그라운드로 가져오기
      self.window?.makeKeyAndOrderFront(nil)
    }
  }
  
  func checkAndApplyLauncherSettingsFromController() {
    print("🔍 MVTimerController에서 CLI 설정 확인 중...")
    
    let defaults = UserDefaults.standard
    let shouldSetTimer = defaults.bool(forKey: "LauncherShouldSetTimer")
    let timeString = defaults.string(forKey: "LauncherSetTimeString")
    let seconds = defaults.double(forKey: "LauncherSetSeconds")
    
    print("🔍 LauncherShouldSetTimer: \(shouldSetTimer)")
    print("🔍 LauncherSetTimeString: \(timeString ?? "nil")")
    print("🔍 LauncherSetSeconds: \(seconds)")
    
    if shouldSetTimer {
      if let timeString = timeString, !timeString.isEmpty {
        print("⏰ CLI에서 설정된 시간 적용: \(timeString)")
        
        // 직접 시간 설정 적용
        self.setTimerToTime(timeString)
        
        // 설정 완료 후 플래그 제거
        defaults.removeObject(forKey: "LauncherShouldSetTimer")
        defaults.removeObject(forKey: "LauncherSetTimeString")
      } else if seconds > 0 {
        print("⏰ CLI에서 설정된 타이머 적용: \(seconds)초")
        
        // 기존 초 단위 설정 적용
        self.setTimerFromLauncher(seconds)
        
        // 설정 완료 후 플래그 제거
        defaults.removeObject(forKey: "LauncherShouldSetTimer")
        defaults.removeObject(forKey: "LauncherSetSeconds")
      }
      defaults.synchronize()
      
      print("✅ CLI 설정 적용 완료 및 정리됨")
    } else {
      print("📝 CLI 설정이 없거나 기본값 사용")
    }
  }
  
  // CLI에서 타이머를 자동으로 시작하는 메서드
  func startTimer() {
    print("▶️ startTimer 호출됨")
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      // handleClick을 사용해서 타이머 시작/정지 토글
      self.clockView.handleClick()
      print("▶️ handleClick 호출됨")
    }
  }
}
