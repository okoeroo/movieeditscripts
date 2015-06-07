

#ffmpeg -i input.mp4 -filter:v 'fade=in:0:50' -c:v libx264 -crf 22 -preset veryfast -c:a copy output.mp4


FADEFRAMECOUNT=12

mute() { ### UNUSED
    ffmpeg -f lavfi -i aevalsrc=0 -i video.mov -shortest -c:v copy -c:a aac \
    -strict experimental -map 0:a -map 1:v output.mov
}

getframe() {
    FILE="$1"
    FRAMECOUNT=$(ffmpeg -i "${FILE}" -vcodec copy -acodec copy -f null /dev/null 2>&1 | grep 'frame=' |  tr -s ' ' | cut -f 2 -d ' ')
    echo $FRAMECOUNT
}

hasaudio() {
    FILE="$1"
    RC=$(ffprobe  -i "$FILE" 2>&1 | grep Stream | grep Audio | wc -l | tr -d ' ')
    return $RC
}

fademagic() {
    CLIP_IN_FILE="$1"
    CLIP_OUT_FILE="$2"
    FADE_IN_FRAMECOUNT="$3"
    FADE_OUT_FRAMECOUNT="$4"

    FRAMECOUNT=$(getframe "${CLIP_IN_FILE}")

    # Has audio? 1 or 0 returned
    hasaudio "$CLIP_IN_FILE"
    HAS_AUDIO="$?"

    if [ $HAS_AUDIO -eq 0 ]; then
        AUDIO_SETTING_PRE="-f lavfi -i aevalsrc=0 -c:a aac"
        AUDIO_SETTING_POST="-shortest -strict -2"
    else
        AUDIO_SETTING_POST="-c:a copy"
    fi

    # Fade in an fade out based on list index of the input files to concatenate
    if [ $FADE_IN_FRAMECOUNT -eq 0 ] && [ $FADE_OUT_FRAMECOUNT -ne 0 ]; then
        FILTER="-filter:v fade=out:$(($FRAMECOUNT-$FADEFRAMECOUNT)):$FADEFRAMECOUNT"
    elif [ $FADE_IN_FRAMECOUNT -ne 0 ] && [ $FADE_OUT_FRAMECOUNT -eq 0 ]; then
        FILTER="-filter:v fade=in:0:$FADEFRAMECOUNT"
    else
        FILTER="-filter:v fade=in:0:$FADEFRAMECOUNT,fade=out:$(($FRAMECOUNT-$FADEFRAMECOUNT)):$FADEFRAMECOUNT"
    fi


    ffmpeg -y ${AUDIO_SETTING_PRE} -i "${CLIP_IN_FILE}" ${FILTER} -c:v libx264 -crf 22 -preset veryfast ${AUDIO_SETTING_POST} "${CLIP_OUT_FILE}"
}


concatclips() {
    TMPFILE="/tmp/movie_magic.tmp.list.tmp"
    rm "${TMPFILE}"
    CNT=0
    for var in "$@"; do
        CNT=$(($CNT+1))
        echo "$CNT / $#: $var"

        INPUT="$var"
        OUTPUT="/tmp/tmp.$CNT.tmp.mp4"
        echo "file ${OUTPUT}" >> "$TMPFILE"

        if [ $CNT -eq 1 ]; then
            # First video config: NO fade in, WITH fade out
            echo "First vid"
            fademagic "$INPUT" "$OUTPUT"  0 $FADEFRAMECOUNT
        elif [ $CNT -eq $# ]; then
            # Last video config: WITH fade in, WITH fade out
            echo "Last vid"
            fademagic "$INPUT" "$OUTPUT"  $FADEFRAMECOUNT $FADEFRAMECOUNT
        else
            # All intermediate video config: WITH fade in, WITH fade out
            echo "Intermediate"
            fademagic "$INPUT" "$OUTPUT"  $FADEFRAMECOUNT $FADEFRAMECOUNT
        fi
    done

    # Concat clips
    ffmpeg -y -f concat -i "$TMPFILE" -acodec copy -c copy final.mp4

    cat "$TMPFILE"
    rm "$TMPFILE"
}

concatclips "materials/CISO_infinity_logo_1280x720.noaudio.mp4" "De Kraaien - 1&2-f_iM-CusiZU.mp4" "materials/CISO_infinity_logo_1280x720.noaudio.mp4"
concatclips "materials/CISO_infinity_logo_1280x720.noaudio.mp4" "De Kraaien - 1&2-f_iM-CusiZU.mp4"


exit 0

fademagic "materials/CISO_infinity_logo_1280x720.noaudio.mp4" "tmp.mp4" 0 $FADEFRAMECOUNT
echo "file tmp.mp4" >> tmp.list.tmp
fademagic "materials/CISO_infinity_logo_1280x720.noaudio.mp4" "tmp2.mp4" $FADEFRAMECOUNT $FADEFRAMECOUNT
echo "file tmp2.mp4" >> tmp.list.tmp

ffmpeg -f concat -i tmp.list.tmp -c copy final.mp4




#ffmpeg -i input.mp4 -filter:v 'fade=in:0:50,fade=out:21000:50' -c:v libx264 -crf 22 -preset veryfast -c:a copy output.mp4


exit 0

ffmpeg \
    -i "materials/CISO_infinity_logo_1280x720.noaudio.mp4" \
    -i "De Kraaien - 1&2-f_iM-CusiZU.mp4" \
    -f lavfi -i color=black -filter_complex \
"[0:v]format=pix_fmts=yuva420p,fade=t=out:st=3.5:d=0.4:alpha=1,setpts=PTS-STARTPTS[va0];\
[1:v]format=pix_fmts=yuva420p,fade=t=in:st=0:d=1:alpha=1,setpts=PTS-STARTPTS+4/TB[va1];\
[2:v]scale=1280x720,trim=duration=9[over],amerge=inputs=2;\
[over][va0]overlay[over1];\
[over1][va1]overlay=format=yuv420[outv];" \
    -aspect "16/9"    -vcodec libx264 -map [outv] out.mp4



exit 0

# Fade in from black from frame 0 to frame 50
# ffmpeg -i input.mp4 -filter:v 'fade=in:0:50' -c:v libx264 -crf 22 -preset veryfast -c:a copy output.mp4

# Fade out to black from frame 21000 to frame 21050
# ffmpeg -i input.mp4 -filter:v 'fade=out:21000:50' -c:v libx264 -crf 22 -preset veryfast -c:a copy output.mp4

# Fade in and out combined
# ffmpeg -i input.mp4 -filter:v 'fade=in:0:50,fade=out:21000:50' -c:v libx264 -crf 22 -preset veryfast -c:a copy output.mp4
