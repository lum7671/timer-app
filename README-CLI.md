# Timer App - CLI 버전

원본 Timer App을 CLI 도구로 변환한 프로젝트입니다.

## 📦 설치 방법

### 1. GUI 런처 (권장)

```bash
# 빌드 (CLI 도구가 앱 번들에 자동 포함됨)
make build

# 시스템에 설치
make launcher-install

# 또는 한 번에 빌드 + 설치
make install
```

### 2. Swift CLI 버전 빌드 및 설치

```bash
# 빌드
make cli-build

# 시스템에 설치
make cli-install
```

### 3. Shell 스크립트 버전 설치

```bash
make shell-install
```

## 🚀 사용법

### 1. GUI 런처 (`timer-launch`) - 권장

GUI Timer.app을 시간 설정과 함께 실행합니다.

**기본 사용법:**

```bash
# 특정 시간에 알람 설정
timer-launch --time 19:30
timer-launch --time 14:30

# 지정된 시간 후 알람
timer-launch --duration 25    # 25분 후
timer-launch --seconds 3600   # 3600초(1시간) 후
```

**자동 시작 옵션:**

```bash
# 시간 설정 후 바로 타이머 시작
timer-launch --time 19:30 --start
timer-launch --duration 30 --start
timer-launch --seconds 1800 --start
```

**macOS open 명령어 사용:**

```bash
# Timer.app을 직접 실행하면서 시간 설정
open -a Timer.app --args --time 19:30
open -a Timer.app --args --time 19:30 --start
open -a Timer.app --args --duration 30 --start
```

**앱 번들에서 직접 실행:**

```bash
# 빌드된 앱 번들에서 CLI 도구 사용
Timer.app/Contents/MacOS/timer-launch --time 19:30 --start
Timer.app/Contents/MacOS/timer-launch-cli --time 19:30 --start --verbose
```

### 2. Swift CLI 버전 (`timer`)

**특정 시간에 알람 설정:**

```bash
timer --time 14:30 --message "회의 시간입니다"
timer -t 15:45 -m "커피 타임"
```

**지정된 시간 후 알람:**

```bash
timer --duration 25 --message "포모도로 완료"
timer -d 5 -m "휴식 시간"
```

**추가 옵션:**

```bash
timer -t 14:30 -m "알람" --sound 1 --verbose    # 사운드 2번, 자세한 출력
timer -d 10 -s -1                               # 무음 알람
```

### 3. Shell 스크립트 버전 (`timer-shell`)

```bash
timer-shell 14:30 "회의 시간"
timer-shell --duration 25 "포모도로 완료"
timer-shell 15:00 "알람" --no-sound
```

## 🎵 사운드 옵션

- `0`: 기본 사운드 (alert-sound.caf)
- `1`: 사운드 2 (alert-sound-2.caf)  
- `2`: 사운드 3 (alert-sound-3.caf)
- `-1`: 무음

## 🧪 테스트

```bash
# GUI 런처 테스트 (1분 후 자동 시작)
timer-launch --duration 1 --start

# CLI 버전 테스트
make test

# 또는 직접 실행
timer --duration 1 --message "테스트" --verbose

# macOS open 명령어 테스트
open -a Timer.app --args --duration 1 --start
```

## 🛠 개발

### 프로젝트 구조

```text
├── Timer/                  # 원본 GUI 앱
├── TimerLauncher/         # GUI 런처 (CLI → GUI 연동)
│   ├── Package.swift
│   └── Sources/TimerLauncher/
│       └── TimerLauncher.swift
├── TimerCLI/              # Swift CLI 버전
│   ├── Package.swift
│   └── Sources/TimerCLI/
│       └── TimerCLI.swift
├── timer-launch           # Shell script wrapper
├── timer-simple.sh       # Shell 스크립트 버전
└── makefile              # 빌드 자동화
```

### 빌드 명령어

**GUI 앱 + CLI 통합:**

```bash
make                # 기본 - GUI+CLI 통합 빌드 및 폴더 열기
make build          # GUI+CLI 통합 빌드 (CLI 도구가 앱 번들에 포함)
make clean          # 정리
```

**CLI 도구:**

```bash
make launcher-build    # GUI 런처 빌드
make launcher-install  # GUI 런처 설치
make cli-build         # Swift CLI 빌드
make cli-install       # Swift CLI 설치
make shell-install     # Shell 스크립트 설치
make install           # 모든 CLI 도구 설치
make test             # CLI 도구 테스트
make help             # 도움말
```

## 🎯 기능

### ✅ 구현된 기능

- [x] 특정 시간 알람 설정 (HH:MM)
- [x] 지정 시간 후 알람 (분/초 단위)
- [x] **자동 타이머 시작 (`--start` 옵션)**
- [x] GUI Timer.app과 CLI 통합
- [x] 다중 인스턴스 지원
- [x] 커스텀 메시지 설정
- [x] macOS 알림 센터 연동
- [x] 사운드 재생 (원본 앱 사운드 파일 활용)
- [x] 실시간 카운트다운 표시
- [x] Verbose 모드
- [x] 사운드 on/off 설정
- [x] Shell 스크립트 대안 버전
- [x] 앱 번들 내 CLI 도구 통합

### 🔄 원본 앱과의 차이점

- CLI에서 GUI를 시간 설정과 함께 실행
- 백그라운드 실행 중 터미널 카운트다운 표시 (CLI 버전)
- 원본 앱의 알림 및 사운드 시스템 재사용
- 다중 타이머 인스턴스 동시 실행 가능

## 📱 예제 사용 시나리오

```bash
# 포모도로 기법 - GUI 버전 (권장)
timer-launch --duration 25 --start    # 25분 작업, 바로 시작
timer-launch --duration 5 --start     # 5분 휴식, 바로 시작

# 회의 알림 - 특정 시간에 자동 시작
timer-launch --time 14:30 --start

# macOS open 명령어 사용
open -a Timer.app --args --time 19:30 --start

# 조용한 알람 - CLI 버전
timer -t 23:00 -m "수면 시간" -s -1

# 요리 타이머 - 여러 개 동시 실행
timer-launch --duration 10 --start    # 라면
timer-launch --duration 15 --start    # 계란
```

## 🔧 기술 세부사항

### GUI 런처 (TimerLauncher)

- **프레임워크**: Swift ArgumentParser
- **GUI 연동**: NSWorkspace + Command Line Arguments
- **다중 인스턴스**: NSWorkspace.OpenConfiguration
- **플랫폼**: macOS 10.15+

### Swift CLI 버전

- **프레임워크**: Swift ArgumentParser
- **알림**: NSUserNotificationCenter
- **사운드**: AVAudioPlayer (원본 .caf 파일 활용)
- **플랫폼**: macOS 10.15+

### Shell 스크립트 버전

- **셸**: Zsh 호환
- **알림**: osascript, terminal-notifier
- **사운드**: afplay (원본 .caf 파일)
- **시간 처리**: UNIX timestamp 기반

## 🤝 기여 방법

1. Fork 프로젝트
2. 기능 브랜치 생성 (`git checkout -b feature/새기능`)
3. 변경사항 커밋 (`git commit -am '새기능 추가'`)
4. 브랜치에 Push (`git push origin feature/새기능`)
5. Pull Request 생성

## 📄 라이선스

원본 Timer App의 라이선스를 따릅니다.

---

**원본 프로젝트**: [michaelvillar/timer-app](https://github.com/michaelvillar/timer-app)  
**CLI 변환**: 커뮤니티 기여
