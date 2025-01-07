#!/system/bin/busybox sh
PATH=$PATH:/data/adb/ap/bin:/data/adb/magisk:/data/adb/ksu/bin
sync
MODPATH="${0%/*}"
source "${MODPATH}/scripts/GK.sh"
if [ -z "$MODPATH" ] || ! echo "$MODPATH" | grep -q '/data/adb/modules/'; then
  MODPATH="$(dirname "$(readlink -f "$0")")"
fi
su -c am broadcast -a android.intent.action.ACTION_OPTIMIZE_DEVICE
su -c cmd battery reset;su -c dumpsys battery reset
echo "$( date "+%Y年%m月%d日%H时%M分%S秒") *搜索并清除data与sdcard目录中的应用缓存*" 
{
find /data/data/*/cache/* -delete > /dev/null 2>&1 && echo " | 清除完成" 
find /data/data/*/code_cache/* -delete > /dev/null 2>&1 && echo " | 清除完成"  
find /data/user_de/*/*/cache/* -delete > /dev/null 2>&1 && echo " | 清除完成"  
find /data/user_de/*/*/code_cache/* -delete > /dev/null 2>&1 && echo " | 清除完成"  
find /sdcard/Android/data/*/cache/* -delete > /dev/null 2>&1 && echo " | 清除完成" 
rm -rf /data/media/0/mtklog /data/media/0/ramdump /data/misc/*stats/* \
           /data/misc/bootstat/* /data/misc/boottrace/* /data/misc/dropbox/* \
           /data/misc/stats*/* /data/misc/tombstones/* /data/misc/trace/* \
           /data/mlog/* /data/system/*stats/* /data/system/bootstat/* \
           /data/system/boottrace/* /data/system/dropbox/* /data/system/shared_prefs/* \
           /data/system/stats*/* /data/system/tombstones/* /data/system/trace/* \
           /data/system/usagestats/* /data/system_ce/0/recent_*/* \
           /data/system_ce/0/recent_tasks/* /data/tombstones/* /data/vendor/*stats/* \
           /data/vendor/bootstat/* /data/vendor/boottrace/* /data/vendor/charge_logger/* \
           /data/vendor/dropbox/* /data/vendor/stats*/* /data/vendor/tombstones/* \
           /data/vendor/trace/* /data/vendor/wlan_logs /data/resource-cache/* \
           /cache/* /data/system/package_cache/* /data/system/cache/* \
           /data/vendor/cache/* /data/misc/cache/* /data/dalvik-cache \
		    > /dev/null 2>&1 && echo " | 清除完成" 
    find /data \( -path "/data/*_log/*" -o \
                    -path "/data/*_logs/*" -o \
                    -path "/data/*_logger/*" -o \
                    -path "/data/traces/*" -o \
                    -path "/data/logger*/*" \) -exec rm -rf {} + \	
                    > /dev/null 2>&1 && echo " | 清除完成" 					
find /data/data/*/cache/* /data/data/*/code_cache/* \
         /data/user_de/*/*/cache/* /data/user_de/*/*/code_cache/* \
         /sdcard/Android/data/*/cache/* /storage/emulated/0/ -type f -name '*cache*' \
         /data/resource-cache/* /cache/* /data/system/package_cache/* \
         /data/system/cache/* /data/vendor/cache/* /data/misc/cache/* \
         /data/dalvik-cache -type f \( -name "*.art" -o \
                                      -name "*.bak" -o \
                                      -name "*.log" -o \
                                      -name "*.thumbnails" -o \
                                      -name "gms" \) -exec rm -vf {} + \
         -o -type d -empty -print -exec rmdir {} + \	
        > /dev/null 2>&1 && echo " | 清除完成" 		 
} &
while [ $(jobs | wc -l) -ge "${thread}" ]; do
sleep 1
done
wait
echo "$( date "+%Y年%m月%d日%H时%M分%S秒") *搜索并清除data与sdcard目录中的应用缓存完成*" 
sleep 5 && exit 0