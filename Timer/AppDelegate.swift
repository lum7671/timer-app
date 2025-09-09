import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {
  private var controllers: [MVTimerController] = []
  private var currentlyInDock: MVTimerController?

  private var staysOnTop = false {
    didSet {
      for window in NSApplication.shared.windows {
        window.level = self.windowLevel()
      }
    }
  }

  override init() {
    super.init()
    self.registerDefaults()
    print("🚀 AppDelegate.init() 호출됨")
    
    // CLI 설정 확인을 init에서 시도
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      print("🔧 init에서 CLI 설정 확인 시도")
      if let controller = self.controllers.first {
        self.checkAndApplyLauncherSettings(to: controller)
      } else {
        print("❌ controllers가 비어있음")
      }
    }
  }

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    print("🚀 AppDelegate.applicationDidFinishLaunching 호출됨")
    
    let controller = MVTimerController()
    controllers.append(controller)
    self.addBadgeToDock(controller: controller)

    NSUserNotificationCenter.default.delegate = self

    let notificationCenter = NotificationCenter.default

    notificationCenter.addObserver(
      self,
      selector: #selector(handleClose),
      name: NSWindow.willCloseNotification,
      object: nil
    )

    notificationCenter.addObserver(
      self,
      selector: #selector(handleUserDefaultsChange),
      name: UserDefaults.didChangeNotification,
      object: nil
    )

    notificationCenter.addObserver(
      self,
      selector: #selector(handleOcclusionChange),
      name: NSWindow.didChangeOcclusionStateNotification,
      object: nil
    )

    print("🔧 Command line arguments 확인을 0.1초 후에 예약합니다...")
    // Command line arguments에서 타이머 설정 확인
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      print("🔧 DispatchQueue.main.asyncAfter 블록 실행됨")
      self.checkAndApplyCommandLineSettings(to: controller)
    }

    staysOnTop = UserDefaults.standard.bool(forKey: MVUserDefaultsKeys.staysOnTop)
    
    print("🚀 AppDelegate.applicationDidFinishLaunching 완료")
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    for window in NSApplication.shared.windows {
      window.makeKeyAndOrderFront(self)
    }
    return true
  }

  func userNotificationCenter(
    _ center: NSUserNotificationCenter,
    shouldPresent notification: NSUserNotification) -> Bool {
    true
  }

  func addBadgeToDock(controller: MVTimerController) {
    if currentlyInDock != controller {
      self.removeBadgeFromDock()
    }
    currentlyInDock = controller
    controller.showInDock(true)
  }

  func removeBadgeFromDock() {
    if currentlyInDock != nil {
      currentlyInDock!.showInDock(false)
    }
  }

  @objc func newDocument(_ sender: AnyObject?) {
    let controller = MVTimerController(closeToWindow: NSApplication.shared.keyWindow)
    controller.window?.level = self.windowLevel()
    controllers.append(controller)
  }

  @objc func handleClose(_ notification: Notification) {
    if let window = notification.object as? NSWindow,
      let controller = window.windowController as? MVTimerController,
      controller != currentlyInDock,
      let index = controllers.firstIndex(of: controller) {
          controllers.remove(at: index)
    }
  }

  @objc func handleOcclusionChange(_ notification: Notification) {
    if let window = notification.object as? NSWindow,
      let controller = window.windowController as? MVTimerController {
      controller.windowVisibilityChanged(window.isVisible)
    }
  }

  @objc func handleUserDefaultsChange(_ notification: Notification) {
    staysOnTop = UserDefaults.standard.bool(forKey: MVUserDefaultsKeys.staysOnTop)
  }

  func windowLevel() -> NSWindow.Level {
    staysOnTop ? .floating : .normal
  }

  private func registerDefaults() {
    UserDefaults.standard.register(defaults: [MVUserDefaultsKeys.staysOnTop: false])
  }

  private func checkAndApplyCommandLineSettings(to controller: MVTimerController) {
    let arguments = CommandLine.arguments
    
    print("🔍 Command line arguments 확인 중...")
    print("🔍 Arguments: \(arguments)")
    
    var shouldStart = false
    
    // --start 옵션 확인
    if arguments.contains("--start") {
      shouldStart = true
      print("▶️ 자동 시작 옵션 감지됨")
    }
    
    // --time 옵션 찾기
    if let timeIndex = arguments.firstIndex(of: "--time"),
       timeIndex + 1 < arguments.count {
      let timeString = arguments[timeIndex + 1]
      print("⏰ Command line에서 설정된 시간 적용: \(timeString)")
      
      // 직접 시간 설정 적용
      controller.setTimerToTime(timeString)
      
      // 자동 시작이 요청된 경우
      if shouldStart {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          print("▶️ 타이머 자동 시작")
          controller.startTimer()
        }
      }
      return
    }
    
    // --seconds 옵션 찾기
    if let secondsIndex = arguments.firstIndex(of: "--seconds"),
       secondsIndex + 1 < arguments.count,
       let seconds = Double(arguments[secondsIndex + 1]) {
      print("⏰ Command line에서 설정된 초 단위 타이머 적용: \(seconds)초")
      
      // 기존 초 단위 설정 적용
      controller.setTimerFromLauncher(seconds)
      
      // 자동 시작이 요청된 경우
      if shouldStart {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          print("▶️ 타이머 자동 시작")
          controller.startTimer()
        }
      }
      return
    }
    
    print("📝 Command line arguments에서 타이머 설정을 찾을 수 없습니다. 기본값 사용")
  }

  private func checkAndApplyLauncherSettings(to controller: MVTimerController) {
    // 기본 UserDefaults 사용
    let defaults = UserDefaults.standard
    
    print("🔍 CLI 설정 확인 중...")
    
    // CLI에서 설정한 값이 있는지 확인
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
        controller.setTimerToTime(timeString)
        
        // 설정 완료 후 플래그 제거
        defaults.removeObject(forKey: "LauncherShouldSetTimer")
        defaults.removeObject(forKey: "LauncherSetTimeString")
      } else if seconds > 0 {
        print("⏰ CLI에서 설정된 타이머 적용: \(seconds)초")
        
        // 기존 초 단위 설정 적용
        controller.setTimerFromLauncher(seconds)
        
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
}
