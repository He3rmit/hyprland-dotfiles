#!/usr/bin/env bash

# ==============================================================================
# SCRIPT: recorder.sh
# PURPOSE: Lightweight Wayland Screen & Region Recorder for Hyprland
#          Supports region selection, fullscreen, and audio capture.
#          Uses wf-recorder with universal H.264 (yuv420p) encoding.
# ==============================================================================

PID_FILE="/tmp/hypr-recorder.pid"
INFO_FILE="/tmp/hypr-recorder.info"
SAVE_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}/Captures"

notify() {
    local title="$1"
    local msg="$2"
    local urgency="${3:-normal}"
    notify-send -a "Screen Recorder" -u "$urgency" -i "media-record" "$title" "$msg" 2>/dev/null || true
}

# --- 1. STOP ACTIVE RECORDING ---
stop_recording() {
    if [[ ! -f "$PID_FILE" ]]; then
        return 1
    fi

    local pid
    pid=$(cat "$PID_FILE" 2>/dev/null)
    local target_file=""
    [[ -f "$INFO_FILE" ]] && target_file=$(cat "$INFO_FILE" 2>/dev/null)

    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        # Send SIGINT to allow recorder to gracefully flush MP4 MOOV atom index
        kill -SIGINT "$pid"

        # Wait up to 3 seconds for clean exit
        for _ in {1..30}; do
            if ! kill -0 "$pid" 2>/dev/null; then
                break
            fi
            sleep 0.1
        done

        # Force kill if still hung
        kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null
    fi

    rm -f "$PID_FILE" "$INFO_FILE"
    pkill -RTMIN+9 waybar 2>/dev/null || true

    # Check that output file exists and is valid
    if [[ -n "$target_file" && -s "$target_file" ]]; then
        local dir
        dir=$(dirname "$target_file")
        local base
        base=$(basename "$target_file")

        # Spawn interactive notification with quick actions
        (
            local action
            action=$(notify-send -a "Screen Recorder" -i "video-x-generic" -u normal \
                "Recording Saved" "Saved to $base" \
                --action="play=▶ Open Video" \
                --action="folder=📁 Open Folder" 2>/dev/null)

            case "$action" in
                play)
                    if command -v mpv >/dev/null 2>&1; then
                        mpv "$target_file" >/dev/null 2>&1 &
                    else
                        xdg-open "$target_file" >/dev/null 2>&1 &
                    fi
                    ;;
                folder)
                    if command -v thunar >/dev/null 2>&1; then
                        thunar "$dir" >/dev/null 2>&1 &
                    else
                        xdg-open "$dir" >/dev/null 2>&1 &
                    fi
                    ;;
            esac
        ) &
    else
        notify "Recording Cancelled" "No video was recorded." "low"
        [[ -f "$target_file" ]] && rm -f "$target_file"
    fi
    exit 0
}

# Handle informational and stop queries first
if [[ "$1" == "--status" ]]; then
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
        echo '{"text":"󰑋 REC","class":"recording","tooltip":"Recording in progress\nClick to stop"}'
    else
        echo '{"text":"","class":"idle","tooltip":"Screen Recorder"}'
    fi
    exit 0
fi

if [[ "$1" == "--stop" || "$1" == "-s" ]]; then
    stop_recording
    exit 0
fi

# If already recording, toggle off and stop
if [[ -f "$PID_FILE" ]]; then
    stop_recording
fi

# --- 2. PRE-FLIGHT DEPENDENCY CHECK ---
if ! command -v wf-recorder >/dev/null 2>&1; then
    notify "Screen Recorder Error" "wf-recorder is not installed.\nInstall with: sudo pacman -S wf-recorder" "critical"
    echo "Error: wf-recorder is not installed. Run: sudo pacman -S wf-recorder" >&2
    exit 1
fi

if ! command -v slurp >/dev/null 2>&1; then
    notify "Screen Recorder Error" "slurp is required for region selection." "critical"
    echo "Error: slurp is not installed. Run: sudo pacman -S slurp" >&2
    exit 1
fi

# --- 3. PARSE RECORDING OPTIONS ---
MODE="region"
RECORD_AUDIO=true
AUDIO_MODE="desktop" # "desktop", "mic", or custom device

while [[ $# -gt 0 ]]; do
    case "$1" in
        --fullscreen|-f)
            MODE="fullscreen"
            shift
            ;;
        --no-audio)
            RECORD_AUDIO=false
            shift
            ;;
        --mic|-m)
            RECORD_AUDIO=true
            AUDIO_MODE="mic"
            shift
            ;;
        --audio=*)
            RECORD_AUDIO=true
            AUDIO_MODE="${1#*=}"
            shift
            ;;
        --audio|-a)
            RECORD_AUDIO=true
            AUDIO_MODE="desktop"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# --- 4. PREPARE DESTINATION ---
mkdir -p "$SAVE_DIR"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
OUTPUT_FILE="$SAVE_DIR/recording_${TIMESTAMP}.mp4"

# --- 5. SELECT CAPTURE TARGET & AUDIO ---
RECORDER_ARGS=("-c" "libx264" "-p" "yuv420p" "-f" "$OUTPUT_FILE")

if [[ "$RECORD_AUDIO" == true ]]; then
    RECORDER_ARGS+=("-C" "aac" "-R" "48000")
    if [[ "$AUDIO_MODE" == "desktop" ]]; then
        # Capture system/desktop audio by monitoring the active output sink
        DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null)
        if [[ -n "$DEFAULT_SINK" ]]; then
            RECORDER_ARGS+=("--audio=${DEFAULT_SINK}.monitor")
        else
            RECORDER_ARGS+=("--audio")
        fi
    elif [[ "$AUDIO_MODE" == "mic" ]]; then
        # Capture microphone (default PulseAudio source)
        RECORDER_ARGS+=("--audio")
    else
        # Custom device
        RECORDER_ARGS+=("--audio=${AUDIO_MODE}")
    fi
fi

if [[ "$MODE" == "region" ]]; then
    # Close SwayNC panel so it doesn't block the selection overlay
    swaync-client -cp >/dev/null 2>&1 || true
    sleep 0.05

    # Area selection via slurp
    GEOM=$(slurp)
    if [[ -z "$GEOM" ]]; then
        # User pressed Esc or cancelled
        exit 0
    fi
    RECORDER_ARGS+=("-g" "$GEOM")
else
    # Fullscreen mode: capture active focused output
    ACTIVE_OUTPUT=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .name' | head -1)
    if [[ -n "$ACTIVE_OUTPUT" ]]; then
        RECORDER_ARGS+=("-o" "$ACTIVE_OUTPUT")
    fi
fi

# --- 6. LAUNCH RECORDING ---
wf-recorder "${RECORDER_ARGS[@]}" >/dev/null 2>&1 &
RECORDER_PID=$!

echo "$RECORDER_PID" > "$PID_FILE"
echo "$OUTPUT_FILE" > "$INFO_FILE"
pkill -RTMIN+9 waybar 2>/dev/null || true

if [[ "$RECORD_AUDIO" == true ]]; then
    if [[ "$AUDIO_MODE" == "mic" ]]; then
        notify "Recording Started 🎙️" "Recording with microphone...\nPress Super+Shift+R to stop."
    else
        notify "Recording Started 🔊" "Recording with desktop audio...\nPress Super+Shift+R to stop."
    fi
else
    notify "Recording Started 📹" "Recording video only (silent)...\nPress Super+Shift+R to stop."
fi
