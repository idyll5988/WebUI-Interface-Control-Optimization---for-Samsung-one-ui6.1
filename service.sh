#!/system/bin/sh
                                
while [[ "$(getprop sys.boot_completed)" -ne 1 ]] && [[ ! -d "/sdcard" ]];do sleep 1; done
                              
while [[ `getprop sys.boot_completed` -ne 1 ]];do sleep 1; done
                              
sdcard_rw() {
until [[ $(getprop sys.boot_completed) -eq 1 || $(getprop dev.bootcomplete) -eq 1 ]]; do sleep 1; done
}
                              
sdcard_rw
                              
[ ! "$MODDIR" ] && MODDIR=${0%/*}
MODPATH="/data/adb/modules/WebUI"
source "${MODPATH}/scripts/GK.sh"
[[ ! -e ${MODDIR}/scripts/ll/log ]] && mkdir -p ${MODDIR}/scripts/ll/log
km1() {
	echo -e "$@" >>优化.log
	echo -e "$@"
}
km2() {
	echo -e "❗️ $@" >>优化.log
	echo -e "❗️ $@"
}
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
if [[ -d ${MODDIR}/scripts ]]; then
    start_time=$(date +%s.%N)
    for i in ${MODDIR}/scripts/*; do
        if [ -f "${i}" ]; then
			chmod 0755 "${i}" || {
                echo "$(date "+%Y年%m月%d日%H时%M分%S秒") *无法设置权限: ${script}*" >>优化.log
                continue
            }
            $su_write "nohup \"${i}\" &" &
            while [ $(jobs | wc -l) -ge "${thread}" ]; do
                sleep 1
            done
        fi
    done
    wait  
    end_time=$(date +%s.%N)
    elapsed=$(echo "$end_time - $start_time" | bc)
    formatted_time=$(printf "%.3f" $elapsed)
    echo "$( date "+%Y年%m月%d日%H时%M分%S秒") *已执行所有脚本总用时$formatted_time秒*" >>优化.log
else
    echo "$(date "+%Y年%m月%d日%H时%M分%S秒") *自定义服务文件夹不存在*" >>优化.log
fi
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
