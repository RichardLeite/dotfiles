#!/bin/bash

# Kill any existing mpvpaper instances to prevent multiple instances
killall -9 mpvpaper 2>/dev/null

# Set up optimized mpv options for lower memory usage
MPV_OPTIONS="--no-audio --loop-file=inf --hwdec=auto --gpu-hwdec-interop=auto --vd-lavc-threads=2 --hwdec-codecs=all --vd-lavc-fast --vd-lavc-skiploopfilter=all --vd-lavc-skipframe=nonref --vd-lavc-framedrop=nonref --vd-lavc-software-fallback=no --no-sub --no-resume-playback --demuxer-lavf-analyzeduration=1 --demuxer-lavf-probe-info=nostreams"

while true; do
    # Start mpvpaper with optimized options on all monitors
    mpvpaper -o "$MPV_OPTIONS" '*' ~/.config/Ax-Shell/assets/wallpapers_example/oni-mask-girl.mp4
    
    # Wait for 2 hours before restarting
    sleep 30m
    
    # Kill the current instance before restarting
    killall -9 mpvpaper 2>/dev/null
    
    # Small delay to ensure clean shutdown
    sleep 2
done