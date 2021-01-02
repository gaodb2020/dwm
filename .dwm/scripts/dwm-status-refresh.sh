#!/bin/bash

function get_bytes {
    # Find active network interface
    interface=$(ip route get 8.8.8.8 2>/dev/null| awk '{print $5}')
    line=$(grep $interface /proc/net/dev | cut -d ':' -f 2 | awk '{print "received_bytes="$1, "transmitted_bytes="$9}')
    eval $line
    now=$(date +%s%N)
}

function get_velocity {
    value=$1
    old_value=$2
    now=$3
    
    timediff=$(($now - $old_time))
    velKB=$(echo "1000000000*($value-$old_value)/1024/$timediff" | bc)
    if test "$velKB" -gt 1024
    then
    	echo $(echo "scale=2; $velKB/1024" | bc)MB/s
    else
    	echo ${velKB}KB/s
    fi
}

get_bytes
old_received_bytes=$received_bytes
old_transmitted_bytes=$transmitted_bytes
old_time=$now

print_volume() {
    volume="$(amixer get Master | tail -n1 | sed -r 's/.*\[(.*)%\].*/\1/')"
    if test "$volume" -gt 0
    then
    	echo -e "\uE05D${volume}"
    else
    	echo -e "Mute"
    fi
}

print_mem(){
    #memfree=$(($(grep -m1 'MemAvailable:' /proc/meminfo | awk '{print $2}') / 1024))
    memfree=$(free -h | awk '(NR==2){ print $4 }' | awk '{sub(/.$/,"")}1')
    echo -e "$memfree"
}

print_disk() {
    diskfree=$(df -h | awk '{ if ($6 == "/") print $4 }')
    echo -e "$diskfree"
}

print_temp(){
    test -f /sys/class/thermal/thermal_zone0/temp || return 0
    echo $(head -c 2 /sys/class/thermal/thermal_zone0/temp)C
}

print_date(){
    date '+%Y年%m月%d日 %H:%M'
}

show_record(){
    test -f /tmp/r2d2 || return
    rp=$(cat /tmp/r2d2 | awk '{print $2}')
    size=$(du -h $rp | awk '{print $1}')
    echo " $size $(basename $rp)"
}

dwm_alsa () {
    VOL=$(amixer get Master | tail -n1 | sed -r "s/.*\[(.*)%\].*/\1/")
    printf "%s" "$SEP1"
    if [ "$IDENTIFIER" = "unicode" ]; then
        if [ "$VOL" -eq 0 ]; then
            printf " "
        elif [ "$VOL" -gt 0 ] && [ "$VOL" -le 50 ]; then
            printf " %s%%" "$VOL"
        else
            printf " %s%%" "$VOL"
        fi
    else
        if [ "$VOL" -eq 0 ]; then
            printf "MUTE"
        elif [ "$VOL" -gt 0 ] && [ "$VOL" -le 33 ]; then
            printf "VOL %s%%" "$VOL"
        elif [ "$VOL" -gt 33 ] && [ "$VOL" -le 66 ]; then
            printf "VOL %s%%" "$VOL"
        else
            printf "VOL %s%%" "$VOL"
        fi
    fi
    printf "%s\n" "$SEP2"
}

LOC=$(readlink -f "$0")
DIR=$(dirname "$LOC")
export IDENTIFIER="unicode"

get_bytes

vel_recv=$(get_velocity $received_bytes $old_received_bytes $now)
vel_trans=$(get_velocity $transmitted_bytes $old_transmitted_bytes $now)

xsetroot -name "   $(print_mem)  $(print_disk)  $vel_recv  $vel_trans $(dwm_alsa) $(show_record) $(print_date) "

old_received_bytes=$received_bytes
old_transmitted_bytes=$transmitted_bytes
old_time=$now

exit 0

