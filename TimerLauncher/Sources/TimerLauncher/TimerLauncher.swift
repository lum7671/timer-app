import ArgumentParser
import Foundation
import Cocoa

@main
struct TimerLauncher: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "timer-launch",
        abstract: "Timer.app GUI를 지정된 시간으로 설정하여 실행합니다",
        version: "1.7.0"
    )
    
    @Option(name: .shortAndLong, help: "알람 시간 (HH:MM 형식)")
    var time: String?
    
    @Option(name: [.customShort("d"), .customLong("duration")], help: "알람까지 남은 시간 (분 단위)")
    var duration: Int?
    
    @Option(name: [.customShort("s"), .customLong("seconds")], help: "알람까지 남은 시간 (초 단위)")
    var totalSeconds: Int?
    
    @Flag(name: .shortAndLong, help: "자세한 출력")
    var verbose: Bool = false
    
    @Flag(name: [.customShort("f"), .customLong("foreground")], help: "Timer.app이 포그라운드로 실행되도록 함")
    var foreground: Bool = false
    
    @Flag(name: [.customLong("start")], help: "타이머를 자동으로 시작")
    var start: Bool = false
    
    func run() throws {
        // 인자 검증 - 타입 안전성 개선
        let timeProvided = time != nil
        let durationProvided = duration != nil  
        let secondsProvided = totalSeconds != nil
        
        let argCount = [timeProvided, durationProvided, secondsProvided].filter { $0 }.count
        guard argCount == 1 else {
            throw ValidationError("--time, --duration, --seconds 중 정확히 하나만 지정해야 합니다.")
        }
        
        // 시간 설정 모드 결정
        if let timeStr = time {
            // 직접 시간 설정 모드
            if verbose {
                print("🚀 Timer.app을 \(timeStr)에 울리도록 설정하여 실행합니다...")
            }
            
            // Timer.app을 arguments와 함께 실행
            try launchTimerApp(timeString: timeStr)
            
        } else {
            // 초 단위 계산 모드 (기존 방식)
            let timerSeconds: Int
            let description: String
            
            if let durationMinutes = duration {
                guard durationMinutes > 0 else {
                    throw ValidationError("시간은 0보다 커야 합니다.")
                }
                timerSeconds = durationMinutes * 60
                let targetTime = Date().addingTimeInterval(TimeInterval(timerSeconds))
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                description = formatter.string(from: targetTime)
            } else if let seconds = totalSeconds {
                guard seconds > 0 else {
                    throw ValidationError("시간은 0보다 커야 합니다.")
                }
                timerSeconds = seconds
                let targetTime = Date().addingTimeInterval(TimeInterval(timerSeconds))
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                description = formatter.string(from: targetTime)
            } else {
                throw ValidationError("시간을 지정해주세요.")
            }
            
            if verbose {
                print("🚀 Timer.app을 \(description) (\(timerSeconds)초)로 설정하여 실행합니다...")
            }
            
            // Timer.app을 초 단위로 실행
            try launchTimerApp(seconds: timerSeconds)
        }
        
        // Timer.app 실행
        // 기본 메서드 호출 제거 - 이제 arguments를 통해 전달
        
        if verbose {
            print("✅ Timer.app이 성공적으로 실행되었습니다!")
            if let timeStr = time {
                print("💡 타이머가 \(timeStr)에 울리도록 설정되었습니다.")
            } else {
                print("💡 타이머가 설정되었습니다.")
            }
        }
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
    
    private func setTimerTimeDefaults(timeString: String) throws {
        if verbose {
            print("📝 시간 문자열(\(timeString))을 UserDefaults에 저장합니다...")
        }
        
        // 기본 UserDefaults에 시간 문자열 설정
        UserDefaults.standard.set(timeString, forKey: "LauncherSetTimeString")
        UserDefaults.standard.set(true, forKey: "LauncherShouldSetTimer")
        UserDefaults.standard.synchronize()
        
        if verbose {
            print("📝 기본 UserDefaults에 시간 문자열 저장 완료")
        }
    }
    
    private func setTimerDefaults(seconds: Int) throws {
        // Timer.app의 bundle identifier 찾기
        let timerBundleId = findTimerAppBundleId()
        
        if let bundleId = timerBundleId {
            if verbose {
                print("📝 Timer.app 설정을 업데이트합니다... (Bundle ID: \(bundleId))")
            }
            
            // Timer.app 전용 UserDefaults에 설정
            let timerDefaults = UserDefaults(suiteName: bundleId) ?? UserDefaults.standard
            timerDefaults.set(Double(seconds), forKey: "LauncherSetSeconds")
            timerDefaults.set(true, forKey: "LauncherShouldSetTimer")
            timerDefaults.synchronize()
        } else {
            if verbose {
                print("📝 기본 UserDefaults에 설정을 저장합니다...")
            }
            
            // 기본 UserDefaults에 설정
            UserDefaults.standard.set(Double(seconds), forKey: "LauncherSetSeconds")
            UserDefaults.standard.set(true, forKey: "LauncherShouldSetTimer")
            UserDefaults.standard.synchronize()
        }
    }
    
    private func findTimerAppBundleId() -> String? {
        // 현재 프로젝트의 Timer.app을 찾기
        let currentPath = FileManager.default.currentDirectoryPath
        let timerAppPath = "\(currentPath)/build/Release/Timer.app"
        
        if FileManager.default.fileExists(atPath: timerAppPath),
           let bundle = Bundle(path: timerAppPath),
           let bundleId = bundle.bundleIdentifier {
            return bundleId
        }
        
        // macOS 12.0 이상에서만 사용 가능한 API 호환성 처리
        if #available(macOS 12.0, *) {
            let workspace = NSWorkspace.shared
            let timerApps = workspace.urlsForApplications(withBundleIdentifier: "com.michaelvillar.timer")
            
            if let firstApp = timerApps.first,
               let bundle = Bundle(url: firstApp),
               let bundleId = bundle.bundleIdentifier {
                return bundleId
            }
        }
        
        return nil
    }
    
    private func launchTimerApp(timeString: String) throws {
        let currentPath = FileManager.default.currentDirectoryPath
        let timerAppPath = "\(currentPath)/build/Release/Timer.app"
        
        if verbose {
            print("🔍 Timer.app에 시간 설정 전달: \(timeString)")
        }
        
        // arguments 배열 생성
        var arguments = ["--time", timeString]
        if start {
            arguments.append("--start")
            if verbose {
                print("▶️ 자동 시작 옵션 추가")
            }
        }
        
        // 먼저 로컬 빌드된 Timer.app 찾기
        if FileManager.default.fileExists(atPath: timerAppPath) {
            let url = URL(fileURLWithPath: timerAppPath)
            try launchApp(at: url, arguments: arguments)
            return
        }
        
        throw ValidationError("Timer.app을 찾을 수 없습니다. 먼저 빌드해주세요.")
    }
    
    private func launchTimerApp(seconds: Int) throws {
        let currentPath = FileManager.default.currentDirectoryPath
        let timerAppPath = "\(currentPath)/build/Release/Timer.app"
        
        if verbose {
            print("🔍 Timer.app에 초 단위 설정 전달: \(seconds)")
        }
        
        // arguments 배열 생성
        var arguments = ["--seconds", "\(seconds)"]
        if start {
            arguments.append("--start")
            if verbose {
                print("▶️ 자동 시작 옵션 추가")
            }
        }
        
        // 먼저 로컬 빌드된 Timer.app 찾기
        if FileManager.default.fileExists(atPath: timerAppPath) {
            let url = URL(fileURLWithPath: timerAppPath)
            try launchApp(at: url, arguments: arguments)
            return
        }
        
        throw ValidationError("Timer.app을 찾을 수 없습니다. 먼저 빌드해주세요.")
    }
    
    private func launchTimerApp() throws {
        let currentPath = FileManager.default.currentDirectoryPath
        let timerAppPath = "\(currentPath)/build/Release/Timer.app"
        
        // 먼저 로컬 빌드된 Timer.app 찾기
        if FileManager.default.fileExists(atPath: timerAppPath) {
            let url = URL(fileURLWithPath: timerAppPath)
            try launchApp(at: url)
            return
        }
        
        // macOS 12.0 이상에서만 사용 가능한 API 호환성 처리
        if #available(macOS 12.0, *) {
            let workspace = NSWorkspace.shared
            let timerApps = workspace.urlsForApplications(withBundleIdentifier: "com.michaelvillar.timer")
            
            if let firstApp = timerApps.first {
                try launchApp(at: firstApp)
                return
            }
        }
        
        // Timer.app을 찾을 수 없는 경우, 빌드 시도
        if verbose {
            print("⚠️ Timer.app을 찾을 수 없습니다. 빌드를 시도합니다...")
        }
        
        let buildResult = shell("make build")
        if buildResult.status == 0 {
            if FileManager.default.fileExists(atPath: timerAppPath) {
                let url = URL(fileURLWithPath: timerAppPath)
                try launchApp(at: url)
                return
            }
        }
        
        throw ValidationError("Timer.app을 찾거나 빌드할 수 없습니다. Timer.app을 먼저 빌드하거나 경로를 확인해주세요.")
    }
    
    private func launchApp(at url: URL, arguments: [String] = []) throws {
        let workspace = NSWorkspace.shared
        
        if verbose {
            print("🔍 앱 실행 시도: \(url.path)")
            print("🔍 Arguments: \(arguments)")
            print("🔍 Foreground 모드: \(foreground)")
        }
        
        // macOS 버전에 따른 호환성 처리
        if #available(macOS 10.15, *) {
            let configuration = NSWorkspace.OpenConfiguration()
            
            // 항상 새 인스턴스 생성하도록 설정
            configuration.createsNewApplicationInstance = true
            
            // Command line arguments 설정
            configuration.arguments = arguments
            
            // 기본적으로 항상 포그라운드에서 실행하도록 변경
            configuration.activates = true
            
            var launchError: Error?
            let semaphore = DispatchSemaphore(value: 0)
            
            workspace.openApplication(at: url, configuration: configuration) { app, error in
                if let error = error {
                    print("⚠️ 앱 실행 중 오류: \(error.localizedDescription)")
                    launchError = error
                } else if let app = app {
                    print("✅ 앱 실행 성공: \(app.localizedName ?? "Timer") (새 인스턴스)")
                }
                semaphore.signal()
            }
            
            // 실행 완료까지 대기
            semaphore.wait()
            
            if let error = launchError {
                throw error
            }
        } else {
            // 이전 버전 호환성 - 새 인스턴스 생성
            try workspace.launchApplication(at: url, options: [.newInstance], configuration: [:])
        }
        
        if verbose {
            print("🎯 Timer.app 새 인스턴스 실행 완료: \(url.path)")
        }
    }
    
    private func shell(_ command: String) -> (output: String, status: Int32) {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/bash"
        task.launch()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return (output, task.terminationStatus)
    }
}

// Validation Error 확장
extension TimerLauncher {
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
