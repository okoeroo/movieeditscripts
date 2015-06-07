

#ffmpeg -i input.mp4 -filter:v 'fade=in:0:50' -c:v libx264 -crf 22 -preset veryfast -c:a copy output.mp4


FADEFRAMECOUNT=12

mute() { ### UNUSED
    ffmpeg -f lavfi -i aevalsrc=0 -i video.mov -shortest -c:v copy -c:a aac \
    -strict experimental -map 0:a -map 1:v output.mov
}

getframe() {
    FILE="$1"
    #FRAMECOUNT=$(ffmpeg -i "${FILE}" -vcodec copy -acodec copy -f null /dev/null 2>&1 | grep 'frame=' |  tr -s ' ' | cut -f 2 -d ' ')

    # Get the frame count through a regex
    string=$(ffmpeg -i "${FILE}" -vcodec copy -acodec copy -f null /dev/null 2>&1 | grep 'frame=');
    [[ $string =~ [^0-9]*([0-9]+)[^0-9]+ ]];
    FRAMECOUNT="${BASH_REMATCH[1]}"

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
        echo "Frame count: $FADEFRAMECOUNT"
        FILTER="-filter:v fade=in:0:$FADEFRAMECOUNT,fade=out:$(($FRAMECOUNT-$FADEFRAMECOUNT)):$FADEFRAMECOUNT"
    fi


    ffmpeg -y ${AUDIO_SETTING_PRE} -i "${CLIP_IN_FILE}" ${FILTER} -c:v libx264 -crf 22 -preset veryfast ${AUDIO_SETTING_POST} "${CLIP_OUT_FILE}"
}


concatclips() {
    FINAL="$1"
    shift


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
#    FINAL="final.mp4"
    ffmpeg -y -f concat -i "$TMPFILE" -acodec copy -c copy "${FINAL}"

    # CLEAN UP
    echo
    echo "Cleaning up"
    cat "$TMPFILE" | while read LINE; do FILE=$(echo "$LINE" | cut -d" " -f 2-); rm "$FILE"; done
    rm "$TMPFILE"

    echo
    echo "Final file: ${FINAL}"
}

# describe videos here
concatclips "final4.mp4" \
    "materials/CISO title clips/NCSC One 2015 - Jaya Baloo - Crypto is dead, long live crypto.mp4" \
    "raw/NCSC One - Jaya Baloo - Crypto is dead, long live crypto.mp4" \
    "materials/CISO_infinity_logo_1280x720.noaudio.mp4"


