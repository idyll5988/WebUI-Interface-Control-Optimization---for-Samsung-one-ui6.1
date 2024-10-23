#!/system/bin/sh
[ ! "$MODDIR" ] && MODDIR=${0%/*}
function log() {
logfile=1000000
maxsize=1000000
if  [[ "$(stat -t ${MODDIR}/scripts/ll/log/优化.log | awk '{print $2}')" -eq "$maxsize" ]] || [[ "$(stat -t ${MODDIR}/scripts/ll/log/优化.log | awk '{print $2}')" -gt "$maxsize" ]]; then
rm -f "${MODDIR}/scripts/ll/log/优化.log"
fi
}
[[ ! -e ${MODDIR}/scripts/ll/log ]] && mkdir -p ${MODDIR}/scripts/ll/log
cd ${MODDIR}/scripts/ll/log
log
if [ "$KSU" = "true" ]; then
echo "$( date "+%Y年%m月%d日%H时%M分%S秒") *👺KernelSU版本=$KSU_KERNEL_VER_CODE (kernel) + $KSU_VER_CODE (ksud)*" >>优化.log
elif [ "$APATCH" = "true" ]; then
APATCH_VER=$(cat "/data/adb/ap/version")
echo "$( date "+%Y年%m月%d日%H时%M分%S秒") *👺APatch版本=$APATCH_VER*" >>优化.log
else
echo "$( date "+%Y年%m月%d日%H时%M分%S秒") *👺Magisk=已安装*" >>优化.log
echo "$( date "+%Y年%m月%d日%H时%M分%S秒") *👺su版本=$(su -v)*" >>优化.log
echo "$( date "+%Y年%m月%d日%H时%M分%S秒") *👺Magisk版本=$(magisk -v)*" >>优化.log
echo "$( date "+%Y年%m月%d日%H时%M分%S秒") *👺Magisk版本号=$(magisk -V)*" >>优化.log
echo "$( date "+%Y年%m月%d日%H时%M分%S秒") *👺Magisk路径=$(magisk --path)*" >>优化.log
fi
while true; do
renice +5 $$
value=$(getprop | grep "oneui" | awk -F': ' '{print $2}' | tr -d '[]')
major=$(echo $value | cut -d'0' -f1)
minor=$(echo $value | cut -d'0' -f2 | cut -c 1)
cpus=`cat /proc/cpuinfo| grep "processor"| wc -l`
arv=$(getprop ro.build.version.release)
[[ "$arv" == "" ]] && arv=$(getprop ro.build.version.release_or_codename)
ARM=$(getprop ro.product.cpu.abi | awk -F "-" '{print $1}')
if [[ "$(getprop init.svc.thermal-engine)" == "running" ]] || [[ "$(getprop init.svc.mi_thermald)" == "running" ]] || [[ "$(getprop init.svc.thermald)" == "running" ]] || [[ "$(getprop init.svc.thermalservice)" == "running" ]]; then
thermal=开
elif [[ "$(getprop init.svc.thermal-engine)" == "stopped" ]] || [[ "$(getprop init.svc.mi_thermald)" == "stopped" ]] || [[ "$(getprop init.svc.thermald)" == "stopped" ]] || [[ "$(getprop init.svc.thermalservice)" == "stopped" ]]; then
thermal=关
else
thermal=未知
fi
render=`getprop debug.hwui.renderer`
if [[ "$render" = "opengl" ]]
then
mode="OpenGL"
elif [[ "$render" = "skiagl" ]]
then
mode="Skia (OpenGL)"
elif [[ "$render" = "skiavk" ]]
then
mode="Skia (Vulkan)"
elif [[ "$render" = "" ]]
then
mode=`dumpsys gfxinfo $PACKAGE_NAME | grep Pipeline | cut -f2 -d '='`
else
mode="未知"
fi
TOTAL_RAM=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
TOTAL_RAM_GB=$(echo "scale=2; $TOTAL_RAM / 1024 / 1024" | bc)
if (( $(echo "$TOTAL_RAM_GB < 12.5 && $TOTAL_RAM_GB > 10.5" | bc -l) )); then
RAM=12
elif (( $(echo "$TOTAL_RAM_GB < 16.5 && $TOTAL_RAM_GB > 13" | bc -l) )); then
RAM=16
else
RAM=$(echo "$TOTAL_RAM_GB" | awk '{print ($0-int($0)>0)?int($0)+1:int($0)}')
fi
[[ "$(cat /sys/fs/selinux/enforce)" == "1" ]] && slstatus="Enforcing" || slstatus="Permissive"
gbcapacity=$(cat /sys/class/power_supply/battery/charge_full_design)
[[ "$gbcapacity" == "" ]] && gbcapacity=$(dumpsys batterystats | awk '/Capacity:/{print $2}' | cut -d "," -f 1)
[[ "$gbcapacity" -ge "1000000" ]] && gbcapacity=$((gbcapacity / 1000))
design_capacity=$(awk '{printf "%.0f", $0/1000}' /sys/class/power_supply/battery/charge_full_design)
current_capacity=$(awk '{printf "%.0f", $0/1000}' /sys/class/power_supply/battery/charge_full)
percentage=$(expr $current_capacity \* 100 / $design_capacity)
battery_usage_percentage=$(expr 100 - $percentage)
if [ -f "/sec/FactoryApp/bsoh" ]; then
    health=$(cat /sec/FactoryApp/bsoh)
else
    battery_info=$(/system/bin/dumpsys battery)
    health=$(echo "$battery_info" | sed -n 's/.*mSavedBatteryAsoc: \([^,]*\).*/\1/p')
fi
if [ -f "/efs/FactoryApp/batt_discharge_level" ]; then
    cycles_raw=$(cat /efs/FactoryApp/batt_discharge_level)
    cycles=$((cycles_raw / 100))
else
    battery_info=${battery_info:-$(/system/bin/dumpsys battery)}
    cycles_raw=$(echo "$battery_info" | sed -n 's/.*mSavedBatteryUsage: \([^,]*\).*/\1/p')
    cycles=$((cycles_raw / 100))
fi
btemp=$(cat /sys/class/power_supply/battery/temp)
[[ $"btemp" == "" ]] && [[ -e "/sys/class/power_supply/battery/temp" ]] && btemp=$(cat /sys/class/power_supply/battery/temp) || [[ ${btemp} == "" ]] && [[ -e "/sys/class/power_supply/battery/batt_temp" ]] && btemp=$(cat /sys/class/power_supply/battery/batt_temp)
btemp=$((btemp / 10))
bhealth=$(dumpsys battery  | awk '/health/{print $2}')
[[ -e "/sys/class/power_supply/battery/health" ]] && bhealth=$(cat /sys/class/power_supply/battery/health)
mo=$(getprop ro.product.model)
A=$(getprop ro.product.brand)
ba=$(cat /sys/class/power_supply/battery/capacity)
    screen_status=$(dumpsys window | grep "mScreenOn" | grep true)
    if [[ "${screen_status}" ]]; then
        > log.txt
        devices=$(echo "[ 🌸 运行中😊 ]👉👉👉
█▓▒▒░░░📲设备性能优化░░░▒▒▓█
📱CPU数量:$cpus个 
📱手机品牌:$A 
📱设备型号:$mo 
📱RAM总量:$RAM GB 
🐧️安卓版本:$arv 
🐧One UI版本:$major.$minor
🐧系统构架:$ARM位 
🌡️温控状态:$thermal 
🌡️电池温度:$btemp°C 
🔋电池容量:$gbcapacity mAh 
🔋电池电量:$ba% 
🔋电池健康:$percentage% 
🔋电池损耗:$battery_usage_percentage% 
🔋电池循环:$cycles次 
🛠️渲染引擎:$mode 
🔒SELinux政策:$slstatus")
        echo "$devices" >> log.txt
        sleep 3
    fi 
done
