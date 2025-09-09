#!/bin/zsh

# Timer CLI - Shell Script Version
# Usage: ./timer-simple.sh [HH:MM] [message]

set -e

# 기본값 설정
MESSAGE="${2:-알람 시간입니다! ⏰}"
SOUND_ENABLED=true

# 도움말 함수
show_help() {
    cat << EOF
Timer CLI - Shell Script Version

사용법:
    ./timer-simple.sh [HH:MM] [메시지]
    ./timer-simple.sh --duration [분] [메시지]
    
예제:
    ./timer-simple.sh 14:30 "회의 시간입니다"
    ./timer-simple.sh --duration 25 "포모도로 타이머 완료"
    
옵션:
    --duration [분]    지정된 분 후에 알람
    --no-sound        사운드 비활성화
    --help            도움말 표시
EOF
}

# 시간 파싱 함수
parse_time() {
    local time_str="$1"
    
    if [[ ! "$time_str" =~ ^[0-9]{1,2}:[0-9]{2}$ ]]; then
        echo "❌ 시간 형식이 올바르지 않습니다. HH:MM 형식으로 입력해주세요."
        exit 1
    fi
    
    local hour=$(echo "$time_str" | cut -d: -f1)
    local minute=$(echo "$time_str" | cut -d: -f2)
    
    if [[ $hour -lt 0 || $hour -gt 23 || $minute -lt 0 || $minute -gt 59 ]]; then
        echo "❌ 올바른 시간 범위가 아닙니다."
        exit 1
    fi
    
    # 오늘 날짜에 지정된 시간으로 타임스탬프 계산
    local target_timestamp=$(date -j -f "%H:%M" "$time_str" "+%s" 2>/dev/null)
    local current_timestamp=$(date "+%s")
    
    # 지정된 시간이 현재 시간보다 이전이면 다음날로 설정
    if [[ $target_timestamp -le $current_timestamp ]]; then
        target_timestamp=$((target_timestamp + 86400)) # 24시간 추가
    fi
    
    echo $target_timestamp
}

# 카운트다운 함수
countdown() {
    local target_timestamp="$1"
    local message="$2"
    local current_timestamp
    local remaining_seconds
    
    while true; do
        current_timestamp=$(date "+%s")
        remaining_seconds=$((target_timestamp - current_timestamp))
        
        if [[ $remaining_seconds -le 0 ]]; then
            break
        fi
        
        # 매분 또는 마지막 10초에만 출력
        if [[ $((remaining_seconds % 60)) -eq 0 || $remaining_seconds -le 10 ]]; then
            local hours=$((remaining_seconds / 3600))
            local minutes=$(((remaining_seconds % 3600) / 60))
            local seconds=$((remaining_seconds % 60))
            
            if [[ $hours -gt 0 ]]; then
                echo "⏳ ${hours}시간 ${minutes}분 ${seconds}초 남음"
            elif [[ $minutes -gt 0 ]]; then
                echo "⏳ ${minutes}분 ${seconds}초 남음"
            else
                echo "⏳ ${seconds}초 남음"
            fi
        fi
        
        sleep 1
    done
    
    # 알람 실행
    execute_alarm "$message"
}

# 알람 실행 함수
execute_alarm() {
    local message="$1"
    
    echo "🔔 $message"
    
    # macOS 알림 발송
    osascript -e "display notification \"$message\" with title \"Timer CLI\" sound name \"Blow\""
    
    # terminal-notifier가 설치되어 있다면 사용
    if command -v terminal-notifier &> /dev/null; then
        terminal-notifier -title "Timer CLI" -message "$message" -sound Blow
    fi
    
    # 사운드 재생 (원본 앱의 사운드 파일 사용)
    if [[ "$SOUND_ENABLED" == true ]]; then
        play_alarm_sound
    fi
}

# 사운드 재생 함수
play_alarm_sound() {
    local timer_app_sound="/Users/1001028/git/timer-app/Timer/alert-sound.caf"
    
    if [[ -f "$timer_app_sound" ]]; then
        # macOS의 afplay를 사용해 사운드 재생
        afplay "$timer_app_sound" &
    else
        # 시스템 기본 사운드
        osascript -e 'beep 3'
    fi
}

# 메인 로직
main() {
    local duration_mode=false
    local target_time=""
    local duration_minutes=""
    
    # 인자 파싱
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --duration|-d)
                duration_mode=true
                duration_minutes="$2"
                shift 2
                ;;
            --no-sound)
                SOUND_ENABLED=false
                shift
                ;;
            *)
                if [[ "$duration_mode" == false && -z "$target_time" ]]; then
                    target_time="$1"
                elif [[ -z "$MESSAGE" || "$MESSAGE" == "알람 시간입니다! ⏰" ]]; then
                    MESSAGE="$1"
                fi
                shift
                ;;
        esac
    done
    
    # 필수 인자 검증
    if [[ "$duration_mode" == false && -z "$target_time" ]]; then
        echo "❌ 시간을 지정해주세요."
        show_help
        exit 1
    fi
    
    if [[ "$duration_mode" == true && -z "$duration_minutes" ]]; then
        echo "❌ 기간을 지정해주세요."
        show_help
        exit 1
    fi
    
    # 타겟 타임스탬프 계산
    local target_timestamp
    if [[ "$duration_mode" == true ]]; then
        target_timestamp=$(($(date "+%s") + duration_minutes * 60))
        target_time=$(date -r $target_timestamp "+%H:%M")
        echo "⏰ ${duration_minutes}분 후 (${target_time})에 알람이 설정되었습니다."
    else
        target_timestamp=$(parse_time "$target_time")
        echo "⏰ ${target_time}에 알람이 설정되었습니다."
    fi
    
    # 카운트다운 시작
    countdown "$target_timestamp" "$MESSAGE"
}

# 스크립트 실행
main "$@"
