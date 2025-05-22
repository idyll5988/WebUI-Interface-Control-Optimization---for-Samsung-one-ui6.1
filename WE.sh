#!/system/bin/sh
[ ! "$MODDIR" ] && MODDIR=${0%/*}
MODPATH="/data/adb/modules/WebUI"
[[ ! -e ${MODDIR}/ll/log ]] && mkdir -p ${MODDIR}/ll/log
source "${MODPATH}/scripts/GK.sh"
while true; do
renice +10 $$

cpu_icon="❌"
gpu_icon="❌"
ram_icon="❌"
battery_icon="❌"
thermal_icon="❌"
mode_icon="❌"

device_model=$(getprop ro.product.model)
case $device_model in
    "SM-S928*")
        cpu_icon="🔥"  # 骁龙8 Gen3专属图标
        ;;
    "SM-S918*")
        cpu_icon="🌪️"  # 骁龙8 Gen2图标
        ;;
    *)
        cpu_icon="💻"  # 默认图标
        ;;
esac

# 2. 性能模式图标（需与GPU渲染脚本联动）
# 从环境变量或配置文件获取当前模式（需预先定义）
current_mode=$(cat /data/adb/modules/WebUI/current_mode 2>/dev/null || echo "5")
case $current_mode in
    "1") mode_icon="⚡" ;;  # 100% GPU
    "3") mode_icon="⚖️" ;;  # 50% GPU
    "5") mode_icon="🔋" ;;  # 0% GPU
    *)    mode_icon="❔" ;;
esac

# 3. 温度图标
if [ "$cpu_temp" -gt 50 ] || [ "$gpu_temp" -gt 55 ]; then
    thermal_icon="🔥"
elif [ "$cpu_temp" -gt 40 ] || [ "$gpu_temp" -gt 45 ]; then
    thermal_icon="🌡️"
else
    thermal_icon="❄️"
fi

# 4. 电池健康图标
if [ "$battery_loss_percentage" -gt 20 ]; then
    battery_icon="⚠️"
elif [ "$battery_loss_percentage" -gt 10 ]; then
    battery_icon="🔋"
else
    battery_icon="🔋"
fi

# 5. 内存使用图标
if [ "$memory_pressure" -gt 80 ]; then
    ram_icon="🚨"
elif [ "$memory_pressure" -gt 60 ]; then
    ram_icon="📉"
else
    ram_icon="📈"
fi
zone=$(cat /sys/class/thermal/thermal_zone[0-9]/temp | awk '{printf "%.1f°C\n", $1/1000}')
value=$(getprop | grep "oneui" | awk -F': ' '{print $2}' | tr -d '[]')
major=$(echo "$value" | grep -oE '^[0-9]+' | head -c 1)
minor=$(echo "$value" | grep -oE '\.[0-9]+' | head -n 1 | tr -d '.')
if [ -z "$minor" ]; then
    minor="0"
fi
cpus=`cat /proc/cpuinfo| grep "processor"| wc -l`
arv=$(getprop ro.build.version.release)
[[ "$arv" == "" ]] && arv=$(getprop ro.build.version.release_or_codename)
ARM=$(getprop ro.product.cpu.abi | awk -F "-" '{print $1}')
if [[ "$(getprop init.svc.thermal-engine)" == "running" ]] || [[ "$(getprop init.svc.mi_thermald)" == "running" ]] || [[ "$(getprop init.svc.thermald)" == "running" ]] || [[ "$(getprop init.svc.thermalservice)" == "running" ]] || [[ "$(getprop init.svc.vendor.samsung.hardware.hyper-default)" == "running" ]]; then
thermal=开
elif [[ "$(getprop init.svc.thermal-engine)" == "stopped" ]] || [[ "$(getprop init.svc.mi_thermald)" == "stopped" ]] || [[ "$(getprop init.svc.thermald)" == "stopped" ]] || [[ "$(getprop init.svc.thermalservice)" == "stopped" ]] || [[ "$(getprop init.svc.vendor.samsung.hardware.hyper-default)" == "running" ]]; then
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
design_capacity=$(awk '{printf "%.0f", $0/1000}' /sys/class/power_supply/battery/charge_full_design)
if [[ -z "$design_capacity" ]]; then
    design_capacity=$(dumpsys batterystats | awk '/Capacity:/{print $2}' | cut -d "," -f 1)
    if [[ "$design_capacity" -ge "1000000" ]]; then
        design_capacity=$((design_capacity / 1000))
    fi
fi
current_capacity=$(awk '{printf "%.0f", $0/1000}' /sys/class/power_supply/battery/charge_full)
if [[ -z "$design_capacity" || -z "$current_capacity" || "$design_capacity" -le 0 ]]; then
    percentage=0
    battery_loss_percentage=0
else
    percentage=$((current_capacity * 100 / design_capacity))
    if [[ "$percentage" -gt 100 ]]; then
        percentage=100
    fi
    battery_loss_percentage=$((100 - percentage))
fi
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
cpu_temp_file="/sys/class/thermal/thermal_zone1/temp"
if [ -f "$cpu_temp_file" ]; then
    cpu_temp=$(cat "$cpu_temp_file")
    cpu_temp=$((cpu_temp / 1000))
else
    cpu_temp="N/A"
fi
gpu_temp_file="/sys/class/thermal/thermal_zone3/temp"
if [ -f "$gpu_temp_file" ]; then
    gpu_temp=$(cat "$gpu_temp_file")
    gpu_temp=$((gpu_temp / 1000))
else
    gpu_temp="N/A"
fi
btemp=$(cat /sys/class/power_supply/battery/temp)
[[ $"btemp" == "" ]] && [[ -e "/sys/class/power_supply/battery/temp" ]] && btemp=$(cat /sys/class/power_supply/battery/temp) || [[ ${btemp} == "" ]] && [[ -e "/sys/class/power_supply/battery/batt_temp" ]] && btemp=$(cat /sys/class/power_supply/battery/batt_temp)
btemp=$((btemp / 10))
bhealth=$(dumpsys battery  | awk '/health/{print $2}')
[[ -e "/sys/class/power_supply/battery/health" ]] && bhealth=$(cat /sys/class/power_supply/battery/health)
cc=$(cat /sys/class/power_supply/battery/charge_full_design)
charge_full_design=$(($cc / 1000))
mo=$(getprop ro.product.model)
A=$(getprop ro.product.brand)
ba=$(cat /sys/class/power_supply/battery/capacity)
read -r cpu user nice system idle iowait irq softirq steal guest </proc/stat
cpu_active_prev=$((user + system + nice + softirq + steal))
cpu_total_prev=$((user + system + nice + softirq + steal + idle + iowait))
usleep 50000
read -r cpu user nice system idle iowait irq softirq steal guest </proc/stat
cpu_active_cur=$((user + system + nice + softirq + steal))
cpu_total_cur=$((user + system + nice + softirq + steal + idle + iowait))
cpu_load=$((100 * (cpu_active_cur - cpu_active_prev) / (cpu_total_cur - cpu_total_prev)))
total_freq_khz=0
cpu_count=0
for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    freq_file="${cpu}/cpufreq/scaling_cur_freq"
    if [ -f "$freq_file" ]; then
        freq=$(cat "$freq_file")
        total_freq_khz=$((total_freq_khz + freq))
        cpu_count=$((cpu_count + 1))
    fi
done
average_ghz=$(echo "scale=2; $total_freq_khz / $cpu_count / 1000000 + 0.005" | bc -l | awk '{printf "%.2f", $0}')
display_info=$(timeout 3 dumpsys display 2>/dev/null)
refresh_line=$(echo "$display_info" | grep -m1 -E 'mRefreshRate=|refreshRate=|frameRate=')
refresh_value=$(echo "$refresh_line" | grep -oE '[0-9]{2,3}(\.[0-9]+)?' | head -n1)
refresh_rate=$(printf "%.0f" "$refresh_value" 2>/dev/null)
refresh_decimal=$((refresh_rate + 0))
density_output=$(timeout 3 wm density 2>/dev/null)
density=$(echo "$density_output" | 
          grep -m1 -E 'Override density:|Physical density:' | 
          sed -n 's/.*[^0-9]\([0-9]\{3,\}\)[^0-9]*$/\1/p')

dpi=$(( density ))	
check_cpu_usage() {
  top -n 1 -m 10 | grep "%cpu" | awk '{print $3}' | cut -d "%" -f1
}	 
GPUU=$(cat /sys/class/kgsl/kgsl-3d0/gpuclk) 	
ufs() {
    local ufs_life_value="$1"
    local status_msg
    case $ufs_life_value in
    "0x01"|"0x1")
        status_msg="UFS健康状况：100% - 90% 已使用寿命 0% - 10%"
    ;;
    "0x02"|"0x2")
        status_msg="UFS健康状况：90% - 80% 已使用寿命 10% - 20%"
    ;;
    "0x03"|"0x3")
        status_msg="UFS健康状况：80% - 70% 已使用寿命 20% - 30%"
    ;;
    "0x04"|"0x4")
        status_msg="UFS健康状况：70% - 60% 已使用寿命 30% - 40%"
    ;;
    "0x05"|"0x5")
        status_msg="UFS健康状况：60% - 50% 已使用寿命 40% - 50%"
    ;;
    "0x06"|"0x6")
        status_msg="UFS健康状况：50% - 40% 已使用寿命 50% - 60%"
    ;;
    "0x07"|"0x7")
        status_msg="UFS健康状况：40% - 30% 已使用寿命 60% - 70%"
    ;;
    "0x08"|"0x8")
        status_msg="UFS健康状况：30% - 20% 已使用寿命 70% - 80%"
    ;;
    "0x09"|"0x9")
        status_msg="UFS健康状况：20% - 10% 已使用寿命 80% - 90%"
    ;;
    "0x0A"|"0xA")
        status_msg="UFS健康状况：10% - 0% 已使用寿命 90% - 100%"
    ;;
    "0x0B"|"0xB")
        status_msg="UFS健康状况：<10% 已超过预估寿命"
    ;;
    *)
        status_msg='已使用寿命 未知'
    ;;
    esac

    echo "$status_msg"
}
ram_status=$(settings get global ram_expand_size 2>/dev/null | awk '{if ($1 == "null") print "未启用"; else printf "%.1f GB", $1/1024}')
CPU_USAGE=$(check_cpu_usage)
mem_usage=$(cat /dev/memcg/memory.usage_in_bytes 2>/dev/null || echo 0)
memsw_usage=$(cat /dev/memcg/memory.memsw.usage_in_bytes 2>/dev/null || echo 1)
memory_pressure=$(awk -v mem_usage="$mem_usage" -v memsw_usage="$memsw_usage" 'BEGIN {print int(mem_usage * 100 / memsw_usage)}')
name=$($su_write "cat /sys/devices/platform/soc/*.ufshc/string_descriptors/product_name")
ufs_a=$($su_write "cat /sys/devices/platform/soc/*.ufshc/health_descriptor/life_time_estimation_a" | cut -f1 -d ' ')
ufs_b=$($su_write "cat /sys/devices/platform/soc/*.ufshc/health_descriptor/life_time_estimation_b" | cut -f1 -d ' ')
driversinfo=$(dumpsys SurfaceFlinger | awk '/GLES/ {if (NF >= 13) {print $6,$7,$8,$9,$10,$11,$12,$13} else {for(i=6;i<=(NF >= 13? 13 : NF);i++){printf("%s ",$i)};print ""}}' | tr -d ',')
    screen_status=$(dumpsys window | grep "mScreenOn" | grep true)
    if [[ "${screen_status}" ]]; then
        > /data/adb/modules/WebUI/scripts/ll/log/配置.log
			devices=$(echo "[ 🌸 运行中😊 ]👉👉👉
█▓▒▒░░░📲设备性能优化░░░▒▒▓█
🧮️CPU数量:$cpus个 
📱处理器: $cpu_icon 骁龙8 Gen3 for Galaxy
📱性能模式: $mode_icon
📱手机品牌:$A 
📱设备型号:$mo 
📱RAM总量:$RAM GB 
📱RAM Plus:$ram_status
📱已用内存:$memory_pressure% $ram_icon
🐧️安卓版本:$arv 
🐧One UI版本:$major.$minor
🐧系统构架:$ARM位 
🌡️温控状态:$thermal $thermal_icon
🌡️电池温度:$btemp°C $battery_icon
🔋电池容量:$charge_full_design mAh 
🔋电池电量:$ba% 
🔋电池健康:$percentage% $battery_icon
🔋电池损耗:$battery_loss_percentage% 
♻️电池循环:$cycles次 
🔋官方电池健康损耗:$(dumpsys battery | grep -i msave)
🌡️CPU 温度:${cpu_temp}°C
📊CPU 平均频率:${average_ghz} GHz
📊️CPU使用率:$CPU_USAGE%
📊CPU 负载:$cpu_load%
🌡️GPU 温度:${gpu_temp}°C
🌡️GPU 频率:$GPUU
🌡️所有温度监控:$zone
💻当前刷新率:$(( $(settings get system peak_refresh_rate | cut -d. -f1) ))Hz
💻️密度:${density} (缩放系数: $((density / 160 ))x)
💻️DPI分辨率:${dpi} (物理像素密度)
🔨驱动程序信息:$driversinfo
📱当前渲染:$mode 
💻️SurfaceFlinger数值:$(dumpsys SurfaceFlinger | grep phase)
💻️色彩模式:$(dumpsys SurfaceFlinger | grep ColorMode)
💾UFS设备品牌:$name
💾UFS健康A状况:$(ufs $ufs_a)--💾UFS健康B状况=$(ufs $ufs_b)
💾缓存用量:已用:`free -g|grep "Mem"|awk '{print $3}'`"G" 剩余:$((`free -g|grep "Mem"|awk '{print $2}'`-`free -g|grep "Mem"|awk '{print $3}'`))"G"
⛏️安全补丁:$(getprop ro.build.version.security_patch)
🖥️CPU使用率最高10个进程信息:$(dumpsys cpuinfo | grep -E '^[[:space:]]*[0-9]+%' | sort -nr -k1 | head -10) 
🔒SELinux政策:$slstatus")
if [ "$KSU" = "true" ]; then
    version_info="👺KernelSU版本=$KSU_KERNEL_VER_CODE (kernel) + $KSU_VER_CODE (ksud)"
elif [ "$APATCH" = "true" ]; then
    APATCH_VER=$(cat "/data/adb/ap/version")
    version_info="👺APatch版本=$APATCH_VER"
else
    magisk_version=$(magisk -v)
    magisk_version_number=$(magisk -V)
    version_info="👺Magisk版本=$magisk_version 👺Magisk版本号=$magisk_version_number"
fi
devices=$(echo "$version_info
$devices")
echo "$devices" >> /data/adb/modules/WebUI/scripts/ll/log/配置.log
        sleep 3
    fi 
done
