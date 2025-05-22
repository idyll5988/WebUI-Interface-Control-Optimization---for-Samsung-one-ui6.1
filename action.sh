#!/system/bin/busybox sh
if ! command -v busybox &> /dev/null; then
  export PATH="/data/adb/magisk:/data/adb/ksu/bin:/data/adb/ap/bin:$PATH:/system/bin"
fi
sync
MODPATH="${0%/*}"
source "${MODPATH}/scripts/GK.sh"
if [ -z "$MODPATH" ] || ! echo "$MODPATH" | grep -q '/data/adb/modules/'; then
  MODPATH="$(dirname "$(readlink -f "$0")")"
fi
thread=200
echo "*搜索并清除data与sdcard目录中的应用缓存*" 
{
su_write renice -n 10 $$
echo "*正在清理应用缓存..." 
clean_cache_app() {
    local app_dir=$1
    local app_name=$(basename "$app_dir")
    local cache_dir="$app_dir/cache"
    local code_cache_dir="$app_dir/code_cache"
    local cache_size=0
    local code_cache_size=0
    [ -d "$cache_dir" ] && cache_size=$(du -sh "$cache_dir" 2>/dev/null | cut -f1)
    [ -d "$code_cache_dir" ] && code_cache_size=$(du -sh "$code_cache_dir" 2>/dev/null | cut -f1)
    if [[ -n "$cache_size" || -n "$code_cache_size" ]]; then
        echo "*正在删除 $app_name 的缓存（缓存大小：${cache_size:-0}, 代码缓存大小：${code_cache_size:-0}）..." 
        [ -d "$cache_dir" ] && find "$cache_dir" -type f -exec rm -f {} + >/dev/null 2>&1
        [ -d "$code_cache_dir" ] && find "$code_cache_dir" -type f -exec rm -f {} + >/dev/null 2>&1
    fi
}
echo "*正在删除 /data/data/*/cache 和 /data/data/*/code_cache 中的文件..." 
for app_dir in /data/data/*; do
    [ -d "$app_dir" ] && clean_cache_app "$app_dir"
done
echo "*正在删除 /data/user_de/*/*/cache 和 /data/user_de/*/*/code_cache 中的文件..." 
for app_dir in /data/user_de/*/*; do
    [ -d "$app_dir" ] && clean_cache_app "$app_dir"
done
echo "*正在删除 /sdcard/Android/data/*/cache 中的文件..." 
for app_dir in /sdcard/Android/data/*; do
    [ -d "$app_dir" ] && clean_cache_app "$app_dir"
done	
} &
while [ $(jobs | wc -l) -ge "${thread}" ]; do
sleep 1
done
wait
echo "*搜索并清除data与sdcard目录中的应用缓存完成*" 
sleep 5 && exit 0