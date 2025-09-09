.PHONY: default clean build open cli-build cli-install shell-install install test launcher-build launcher-install help

# 기본 타겟 - GUI 앱 빌드
default: clean build open

# GUI 앱 관련 타겟들
clean:
	xcodebuild -quiet clean 

build: clean launcher-build
	xcodebuild -quiet build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
	@echo "📦 CLI 도구들을 앱 번들에 포함 중..."
	cp TimerLauncher/.build/arm64-apple-macosx/release/TimerLauncher build/Release/Timer.app/Contents/MacOS/timer-launch-cli
	cp timer-launch build/Release/Timer.app/Contents/MacOS/timer-launch
	@echo "✅ Timer.app 번들 완성!"

open: build
	open ./build/Release/

# CLI 런처 (GUI 앱을 시간 설정하여 실행)
launcher-build:
	@echo "🔨 Timer 런처 빌드 중..."
	cd TimerLauncher && swift build -c release
	@echo "✅ 런처 빌드 완료: TimerLauncher/.build/arm64-apple-macosx/release/TimerLauncher"

launcher-install: build
	@echo "📦 Timer 런처 설치 중..."
	sudo cp build/Release/Timer.app/Contents/MacOS/timer-launch-cli /usr/local/bin/timer-launch
	@echo "✅ Timer 런처 설치 완료: /usr/local/bin/timer-launch"
	@echo "사용법: timer-launch --time 14:30"

# CLI 버전 관련 타겟들
cli-build:
	@echo "🔨 Swift CLI 버전 빌드 중..."
	cd TimerCLI && swift build -c release
	@echo "✅ CLI 빌드 완료: TimerCLI/.build/release/TimerCLI"

cli-install: cli-build
	@echo "📦 CLI 도구 설치 중..."
	sudo cp TimerCLI/.build/release/TimerCLI /usr/local/bin/timer
	@echo "✅ CLI 설치 완료: /usr/local/bin/timer"
	@echo "사용법: timer --time 14:30 --message \"회의 시간\""

shell-install:
	@echo "📦 Shell 스크립트 버전 설치 중..."
	chmod +x timer-simple.sh
	sudo cp timer-simple.sh /usr/local/bin/timer-shell
	@echo "✅ Shell 스크립트 설치 완료: /usr/local/bin/timer-shell"
	@echo "사용법: timer-shell 14:30 \"회의 시간\""

# 전체 설치 (모든 버전)
install: launcher-install cli-install shell-install
	@echo "🎉 모든 타이머 도구 설치 완료!"
	@echo ""
	@echo "사용 가능한 명령어:"
	@echo "  timer-launch --time 14:30    # Timer.app GUI를 시간 설정하여 실행"
	@echo "  timer --time 14:30           # 독립 CLI 타이머"
	@echo "  timer-shell 14:30            # Shell 스크립트 타이머"

test: launcher-build build
	@echo "🧪 Timer 런처 테스트 (2분 타이머로 GUI 실행):"
	TimerLauncher/.build/release/TimerLauncher --duration 2 --verbose

test-cli: cli-build
	@echo "🧪 CLI 도구 테스트 (30초 후 알람):"
	TimerCLI/.build/release/TimerCLI --duration 1 --message "테스트 알람입니다!" --verbose

help:
	@echo "Timer App Makefile"
	@echo ""
	@echo "GUI 앱:"
	@echo "  make                # GUI 앱 빌드 및 폴더 열기"
	@echo "  make build          # GUI 앱 빌드만"
	@echo "  make clean          # GUI 앱 정리"
	@echo ""
	@echo "CLI 런처 (GUI 실행):"
	@echo "  make launcher-build    # Timer 런처 빌드"
	@echo "  make launcher-install  # Timer 런처 설치"
	@echo "  make test              # 런처 테스트"
	@echo ""
	@echo "독립 CLI 도구:"
	@echo "  make cli-build      # Swift CLI 빌드"
	@echo "  make cli-install    # Swift CLI 설치"
	@echo "  make test-cli       # CLI 도구 테스트"
	@echo ""
	@echo "전체:"
	@echo "  make install        # 모든 도구 설치"

