#!/system/bin/sh
[ ! "$MODDIR" ] && MODDIR=${0%/*}
[ -e ${MODDIR}/dev/*/.magisk/busybox ] && BB=$(echo ${MODDIR}/dev/*/.magisk/busybox);
[ -e ${MODDIR}/data/adb/magisk/busybox ] && BB=${MODDIR}/data/adb/magisk/busybox;
[ -e ${MODDIR}/data/adb/ap/bin/busybox ] && BB=${MODDIR}/data/adb/ap/bin/busybox;
[ -e ${MODDIR}/data/adb/ksu/bin/busybox ] && BB=${MODDIR}/data/adb/ksu/bin/busybox;
[ -e ${MODDIR}/system/bin/busybox ] && BB=${MODDIR}/system/bin/busybox;
[ -e ${MODDIR}/system/bin/toybox ] && SOS=${MODDIR}/system/bin/toybox;
[ -e ${MODDIR}/system/bin/sqlite3 ] && SQ=${MODDIR}/system/bin/sqlite3;
[ "$BB" ] && export PATH="/system/bin:$BB:$PATH";
detect_su_format() {
    if su -i -c 'exit 0' >/dev/null 2>&1; then
        echo "su -i -c"
    elif su -c 'exit 0' >/dev/null 2>&1; then
        echo "su -c"
    else
        echo ""
    fi
}
su_write=$(detect_su_format)
$su_write renice -n 10 $$