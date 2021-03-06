

#ffmpeg -i input.mp4 -filter:v 'fade=in:0:50' -c:v libx264 -crf 22 -preset veryfast -c:a copy output.mp4


FADEFRAMECOUNT=12

mute() { ### UNUSED
    ffmpeg -f lavfi -i aevalsrc=0 -i video.mov -shortest -c:v copy -c:a aac \
    -strict experimental -map 0:a -map 1:v output.mov
}

getframe() {
    FILE="$1"

    FRAMECOUNT=$(ffprobe  -select_streams v -show_streams  -i "${FILE}" | grep nb_frames | sed -e 's/nb_frames=//')
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


    ffmpeg -y ${AUDIO_SETTING_PRE} -i "${CLIP_IN_FILE}" ${FILTER} -c:v libx264 -preset veryfast ${AUDIO_SETTING_POST} "${CLIP_OUT_FILE}"
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
concatclips "./publishable/NCSC One - Jaya Baloo - Crypto is dead, long live crypto.mp4" \
    "materials/CISO title clips/NCSC One 2015 - Jaya Baloo - Crypto is dead, long live crypto.mp4" \
    "raw/NCSC One - Jaya Baloo - Crypto is dead, long live crypto.mp4" \
    "materials/CISO_infinity_logo_1280x720.noaudio.mp4"
exit 0
concatclips "./publishable/CISO - Jaya Baloo en Bouke van Leathem over cybersecurity en ethisch hacken.mp4" \
    "materials/CISO_infinity_logo_1280x720.noaudio.mp4" \
    "raw/Jaya Baloo en Bouke van Leathem over cybersecurity en ethisch hacken bij KPN-dtNBgg6Gp1A.mp4" \
    "materials/CISO_infinity_logo_1280x720.noaudio.mp4"

concatclips "./publishable/CISO - Marc van Kasteren over cyber security policy.mp4" \
    "materials/CISO_infinity_logo_1280x720.noaudio.mp4" \
    "raw/Marc van Kasteren over cyber security policy bij KPN-uQ7JZ8pDoSA.mp4" \
    "materials/CISO_infinity_logo_1280x720.noaudio.mp4"

concatclips "./publishable/CISO - Rence Damming over het werk van Privacy Officer.mp4" \
    "materials/CISO_infinity_logo_1280x720.noaudio.mp4" \
    "raw/Rence Damming over het werk van Privacy Officer bij KPN-y5ahGlGzt0U.mp4" \
    "materials/CISO_infinity_logo_1280x720.noaudio.mp4"

concatclips "./publishable/CISO - Rob Kuiters over digitaal forensisch onderzoek.mp4" \
    "materials/CISO_infinity_logo_1280x720.noaudio.mp4" \
    "raw/Rob Kuiters over digitaal forensisch onderzoek bij KPN-9E9vmPUUMEs.mp4" \
    "materials/CISO_infinity_logo_1280x720.noaudio.mp4"

concatclips "./publishable/CISO - Oscar Koeroo en Eduard Hoekx demonstreren de black phone.mp4" \
    "materials/CISO_infinity_logo_1280x720.noaudio.mp4" \
    "raw/Oscar Koeroo en Eduard Hoekx demonstreren de black phone-7d8vtJe11eg.mp4" \
    "materials/CISO_infinity_logo_1280x720.noaudio.mp4"


