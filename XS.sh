#!/system/bin/sh
MODDIR=${0%/*}
MODPATH="/data/adb/modules/WebUI"
LOG_DIR="${MODDIR}/ll/log"
source "${MODDIR}/scripts/GK.sh"
[[ ! -e ${LOG_DIR} ]] && mkdir -p ${LOG_DIR}
$su_write renice -n 10 $$
while true; do
    screen_status=$(dumpsys window | grep "mScreenOn" | grep true) 
	if [[ "${screen_status}" ]]; then
    local refresh_raterefresh_rate=$(settings get system peak_refresh_rate 2>/dev/null | cut -d. -f1)
	[[ -z $refresh_rate ]] && refresh_rate=120 # 默认值
	(( refresh_rate > 165 )) && refresh_rate=165
    (( refresh_rate < 60 )) && refresh_rate=60
    frame_time=$(awk "BEGIN {printf \"%.0f\", (1 / $refresh_rate) * 1000000000}")
	early_offset=$((frame_time / 5))
    late_offset=$((frame_time * 5 / 6))
    negative_offset=$((early_offset * -1))
    gl_duration=$((late_offset + frame_time / 15))
    idle_timer=$((frame_time / 1000000 + 800))
    sampling_duration=$((frame_time * 4 / 5))
    sampling_period=$((frame_time * 9 / 10))
	$su_write resetprop -n debug.sf.hwc.min.duration "$frame_time"
	$su_write resetprop -n debug.sf.early.app.duration "$early_offset"
	$su_write resetprop -n debug.sf.late.app.duration "$late_offset"
	$su_write resetprop -n debug.sf.early.sf.duration "$early_offset"
	$su_write resetprop -n debug.sf.late.sf.duration "$late_offset"
	$su_write resetprop -n debug.sf.set_idle_timer_ms "$idle_timer"
	$su_write resetprop -n debug.sf.earlyGl.sf.duration "$gl_duration"
	$su_write resetprop -n debug.sf.earlyGl.app.duration "$gl_duration"
	$su_write resetprop -n debug.sf.early_phase_offset_ns "$early_offset"
	$su_write resetprop -n debug.sf.early_gl_phase_offset_ns "$early_offset"
	$su_write resetprop -n debug.sf.early_app_phase_offset_ns "$early_offset"
	$su_write resetprop -n debug.sf.early_gl_app_phase_offset_ns "$early_offset"
	$su_write resetprop -n debug.sf.high_fps_early_app_phase_offset_ns "$negative_offset"
	$su_write resetprop -n debug.sf.high_fps_late_app_phase_offset_ns "$late_offset"
	$su_write resetprop -n debug.sf.high_fps_early_sf_phase_offset_ns "$negative_offset"
	$su_write resetprop -n debug.sf.high_fps_late_sf_phase_offset_ns "$late_offset"
	$su_write resetprop -n debug.sf.high_fps_early_gl_phase_offset_ns "$early_offset"
	$su_write resetprop -n debug.sf.high_fps_early_gl_app_phase_offset_ns "$early_offset"
	else  
	$su_write resetprop --delete debug.sf.hwc.min.duration
    $su_write resetprop --delete debug.sf.set_idle_timer_ms
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