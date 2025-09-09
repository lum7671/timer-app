import ArgumentParser
import Foundation
import Cocoa
import AVFoundation

@main
struct TimerCLI: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "timer",
        abstract: "macOS Timer CLI - 지정된 시간에 알람을 설정합니다",
        version: "1.7.0"
    )
    
    @Option(name: .shortAndLong, help: "알람 시간 (HH:MM 형식)")
    var time: String?
    
    @Option(name: [.customShort("d"), .customLong("duration")], help: "알람까지 남은 시간 (분 단위)")
    var duration: Int?
    
    @Option(name: .shortAndLong, help: "알람 메시지")
    var message: String = "알람 시간입니다! ⏰"
    
    @Option(name: [.customShort("s"), .customLong("sound")], help: "사운드 타입 (0: 기본, 1: 사운드2, 2: 사운드3, -1: 무음)")
    var sound: Int = 0
    
    @Flag(name: .shortAndLong, help: "자세한 출력")
    var verbose: Bool = false
    
    mutating func run() async throws {
        if time == nil && duration == nil {
            throw ValidationError("--time 또는 --duration 중 하나는 반드시 지정해야 합니다.")
        }
        
        if time != nil && duration != nil {
            throw ValidationError("--time과 --duration은 동시에 사용할 수 없습니다.")
        }
        
        let waitTime: TimeInterval
        let targetDescription: String
        
        if let timeStr = time {
            let targetTime = try parseTime(timeStr)
            waitTime = calculateWaitTime(targetTime)
            targetDescription = timeStr
        } else if let durationMinutes = duration {
            waitTime = TimeInterval(durationMinutes * 60)
            let targetTime = Date().addingTimeInterval(waitTime)
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            targetDescription = formatter.string(from: targetTime)
        } else {
            throw ValidationError("시간 정보가 없습니다.")
        }
        
        if waitTime <= 0 {
            throw ValidationError("알람 시간이 현재 시간보다 이전입니다.")
        }
        
        print("⏰ \(targetDescription)에 알람이 설정되었습니다.")
        if verbose {
            print("📊 대기 시간: \(Int(waitTime))초 (\(Int(waitTime/60))분 \(Int(waitTime.truncatingRemainder(dividingBy: 60)))초)")
        }
        
        // 카운트다운 타이머 시작
        await startCountdown(waitTime: waitTime, targetTime: targetDescription)
        
        // 알람 실행
        await executeAlarm()
    }
    
    private func parseTime(_ timeStr: String) throws -> Date {
        let components = timeStr.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]),
              hour >= 0, hour < 24,
              minute >= 0, minute < 60 else {
            throw ValidationError("시간 형식이 올바르지 않습니다. HH:MM 형식으로 입력해주세요.")
        }
        
        let calendar = Calendar.current
        let now = Date()
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = 0
        
        guard let targetDate = calendar.date(from: dateComponents) else {
            throw ValidationError("날짜 생성에 실패했습니다.")
        }
        
        // 만약 지정된 시간이 현재 시간보다 이전이면 다음날로 설정
        if targetDate <= now {
            return calendar.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate
        }
        
        return targetDate
    }
    
    private func calculateWaitTime(_ targetTime: Date) -> TimeInterval {
        return targetTime.timeIntervalSinceNow
    }
    
    private func startCountdown(waitTime: TimeInterval, targetTime: String) async {
        let totalSeconds = Int(waitTime)
        
        for remainingSeconds in stride(from: totalSeconds, through: 1, by: -1) {
            if verbose || remainingSeconds % 60 == 0 || remainingSeconds <= 10 {
                let hours = remainingSeconds / 3600
                let minutes = (remainingSeconds % 3600) / 60
                let seconds = remainingSeconds % 60
                
                if hours > 0 {
                    print("⏳ \(targetTime)까지 \(hours)시간 \(minutes)분 \(seconds)초 남음")
                } else if minutes > 0 {
                    print("⏳ \(targetTime)까지 \(minutes)분 \(seconds)초 남음")
                } else {
                    print("⏳ \(targetTime)까지 \(seconds)초 남음")
                }
            }
            
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
        }
    }
    
    private func executeAlarm() async {
        print("🔔 \(message)")
        
        // macOS 알림 센터에 알림 발송
        await sendNotification()
        
        // 시스템 사운드 재생
        playAlarmSound()
        
        // 사용자 주의 요청
        NSApplication.shared.requestUserAttention(.criticalRequest)
    }
    
    @MainActor
    private func sendNotification() async {
        let notification = NSUserNotification()
        notification.title = "Timer CLI 알람"
        notification.informativeText = message
        notification.soundName = sound == -1 ? nil : NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    private func playAlarmSound() {
        guard sound != -1 else { return }
        
        let soundName: String
        switch sound {
        case 1:
            soundName = "alert-sound-2"
        case 2:
            soundName = "alert-sound-3"
        default:
            soundName = "alert-sound"
        }
        
        // 원본 앱의 사운드 파일 경로에서 찾기
        let timerAppSoundPath = "/Users/1001028/git/timer-app/Timer/\(soundName).caf"
        
        if FileManager.default.fileExists(atPath: timerAppSoundPath) {
            let soundURL = URL(fileURLWithPath: timerAppSoundPath)
            playSound(url: soundURL)
        } else {
            // 시스템 기본 사운드 재생
            NSSound.beep()
        }
    }
    
    private func playSound(url: URL) {
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.play()
            
            // 사운드 재생이 끝날 때까지 잠시 대기
            Thread.sleep(forTimeInterval: 2.0)
        } catch {
            print("⚠️ 사운드 재생 실패: \(error.localizedDescription)")
            NSSound.beep()
        }
    }
}

// Validation Error 확장
extension TimerCLI {
    struct ValidationError: LocalizedError {
        let message: String
        
        init(_ message: String) {
            self.message = message
        }
        
        var errorDescription: String? {
            return message
        }
    }
}
