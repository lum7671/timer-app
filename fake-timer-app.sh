#!/bin/bash

# Timer.app 가짜 구현 (테스트용)
# 실제 Timer.app 없이도 런처 테스트를 위함

echo "🚀 가짜 Timer.app 시작됨"

# UserDefaults에서 런처 설정 확인
defaults read NSGlobalDomain LauncherShouldSetTimer 2>/dev/null >/dev/null
if [ $? -eq 0 ]; then
    should_set=$(defaults read NSGlobalDomain LauncherShouldSetTimer 2>/dev/null)
    seconds=$(defaults read NSGlobalDomain LauncherSetSeconds 2>/dev/null)
    
    if [ "$should_set" = "1" ] && [ "$seconds" != "" ]; then
        echo "⏰ CLI에서 설정된 타이머 시간: ${seconds}초"
        
        minutes=$((seconds / 60))
        remaining_seconds=$((seconds % 60))
        echo "📊 타이머 설정: ${minutes}분 ${remaining_seconds}초"
        
        # 설정 제거 (실제 앱처럼)
        defaults delete NSGlobalDomain LauncherShouldSetTimer 2>/dev/null
        defaults delete NSGlobalDomain LauncherSetSeconds 2>/dev/null
        
        echo "🎯 타이머가 설정되었습니다!"
    else
        echo "📝 기본 타이머 앱으로 시작됨"
    fi
else
    echo "📝 기본 타이머 앱으로 시작됨"
fi

echo "💡 Timer.app GUI 창이 여기에 표시됩니다..."
echo "⏹️  가짜 앱 종료"
