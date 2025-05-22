#!/system/bin/sh
MODDIR=${0%/*}
MODPATH="/data/adb/modules/WebUI"
LOG_DIR="${MODDIR}/ll/log"
source "${MODPATH}/scripts/GK.sh"
[[ ! -e ${LOG_DIR} ]] && mkdir -p ${LOG_DIR}
while true; do
    $su_write renice -n 10 $$
    screen_status=$(dumpsys window | grep "mScreenOn" | grep true) 
	if [[ "${screen_status}" ]]; then
    refresh_rate=$(settings get system peak_refresh_rate 2>/dev/null | cut -d. -f1)
	[ -z "$refresh_rate" ] && refresh_rate=120 # 默认值
    frame_ns=$((1000000000 / refresh_rate))
    phases=(
    ['v1']=$((frame_ns * 6 / 100))     # 6% 帧周期
    ['v2']=$((frame_ns * 12 / 100))    # 12%
    ['v3']=$((frame_ns * 25 / 100))    # 25%
    ['hwc']=$((frame_ns * 130 / 100))  # 130% 帧周期
    )
    $su_write resetprop -n debug.sf.hwc.min.duration ${phases['hwc']}
    $su_write resetprop -n debug.sf.early_phase_offset_ns ${phases['v1']}
    $su_write resetprop -n debug.sf.high_fps_early_phase_offset_ns ${phases['v2']}
	else  
    fi
    # 智能休眠算法
    load=$(awk '{printf "%.0f", $1}' /proc/loadavg)
    case true in
        $((load >= 20))*) sleep 10 ;;
        $((load >= 10))*) sleep 15 ;;
        $((load >= 5))*)  sleep 20 ;;
        *)                sleep 30 ;;
    esac
done >/dev/null 2>&1 &