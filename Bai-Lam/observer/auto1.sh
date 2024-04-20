#!/bin/bash

logfile="D:\Workspace\2023-2024-Ki-I\Do-An-Tot-Nghiep\Bai-Lam\observer\log_obs.log"
lastsize=$(wc -c < "$logfile")

while true; do
    currentsize=$(wc -c < "$logfile")
    if ((currentsize > lastsize)); then
        newlines=$(tail -c +"$((lastsize + 1))" "$logfile")
        echo "$newlines"
        lastsize=$currentsize
    fi
    sleep 1
done
