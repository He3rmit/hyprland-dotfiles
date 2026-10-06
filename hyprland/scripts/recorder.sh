#!/usr/bin/env bash

# ==============================================================================
# SCRIPT: recorder.sh
# PURPOSE: Wayland Screen & Region Recorder with Interactive Audio/Target Menu
#          Supports: Desktop Audio, Microphone, Mixed (Desktop+Mic), Silent.
# ==============================================================================

PID_FILE="/tmp/hypr-recorder.pid"
INFO_FILE="/tmp/hypr-recorder.info"
MODULES_FILE="/tmp/hypr-recorder.modules"
SAVE_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}/Captures"
ROFI_THEME="$HOME/.config/rofi/themes/selector.rasi"

notify() {
    local title="$1"
    local msg="$2"
    local urgency="${3:-normal}"
    notify-send -a "Screen Recorder" -u "$urgency" -i "media-record" "$title" "$msg" 2>/dev/null || true
}

rofi_cmd() {
    local prompt="$1"
    local extra_args=("${@:2}")
    if [[ -f "$ROFI_THEME" ]]; then
        rofi -dmenu -i -p "$prompt" -theme "$ROFI_THEME" "${extra_args[@]}"
    else
        rofi -dmenu -i -p "$prompt" "${extra_args[@]}"
    fi
}

cleanup_audio_modules() {
    if [[ -f "$MODULES_FILE" ]]; then
        while read -r mod_id; do
            [[ -n "$mod_id" ]] && pactl unload-module "$mod_id" 2>/dev/null || true
        done < "$MODULES_FILE"
        rm -f "$MODULES_FILE"
    fi
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
    cleanup_audio_modules
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

# --- 2. EARLY STATUS OR STOP DISPATCH ---
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

# If already recording, toggle off and stop immediately
if [[ -f "$PID_FILE" ]]; then
    stop_recording
fi

# --- 3. PRE-FLIGHT DEPENDENCY CHECK ---
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

# --- 4. INTERACTIVE MENU OR CLI PARSING ---
MODE=""
AUDIO_TYPE=""

show_menu() {
    local opt_reg_desk="🔊  Region (Desktop Audio)"
    local opt_reg_both="🎧  Region (Desktop Audio + Mic)"
    local opt_reg_mic="🎙️  Region (Microphone Only)"
    local opt_reg_mute="🔇  Region (Silent / No Audio)"
    local opt_fs_desk="🖥️   Fullscreen (Desktop Audio)"
    local opt_fs_both="🎧  Fullscreen (Desktop Audio + Mic)"
    local opt_fs_mic="🎙️  Fullscreen (Microphone Only)"
    local opt_fs_mute="🔇  Fullscreen (Silent / No Audio)"

    local items="$opt_reg_desk\n$opt_reg_both\n$opt_reg_mic\n$opt_reg_mute\n$opt_fs_desk\n$opt_fs_both\n$opt_fs_mic\n$opt_fs_mute"
    local choice
    choice=$(echo -e "$items" | rofi_cmd "󰑋 Screen Recorder")
    [[ -z "$choice" ]] && exit 0

    case "$choice" in
        *"Region (Desktop Audio)"*)
            MODE="region"; AUDIO_TYPE="desktop" ;;
        *"Region (Desktop Audio + Mic)"*)
            MODE="region"; AUDIO_TYPE="both" ;;
        *"Region (Microphone Only)"*)
            MODE="region"; AUDIO_TYPE="mic" ;;
        *"Region (Silent / No Audio)"*)
            MODE="region"; AUDIO_TYPE="none" ;;
        *"Fullscreen (Desktop Audio)"*)
            MODE="fullscreen"; AUDIO_TYPE="desktop" ;;
        *"Fullscreen (Desktop Audio + Mic)"*)
            MODE="fullscreen"; AUDIO_TYPE="both" ;;
        *"Fullscreen (Microphone Only)"*)
            MODE="fullscreen"; AUDIO_TYPE="mic" ;;
        *"Fullscreen (Silent / No Audio)"*)
            MODE="fullscreen"; AUDIO_TYPE="none" ;;
        *)
            exit 0 ;;
    esac
}

# Parse CLI arguments if provided
while [[ $# -gt 0 ]]; do
    case "$1" in
        --menu|-m)
            show_menu
            shift
            ;;
        --fullscreen|-f)
            MODE="fullscreen"
            shift
            ;;
        --region|-r)
            MODE="region"
            shift
            ;;
        --desktop)
            AUDIO_TYPE="desktop"
            shift
            ;;
        --mic)
            AUDIO_TYPE="mic"
            shift
            ;;
        --both)
            AUDIO_TYPE="both"
            shift
            ;;
        --no-audio|--none)
            AUDIO_TYPE="none"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# If neither mode nor audio type specified via CLI, show interactive menu by default
if [[ -z "$MODE" ]]; then
    show_menu
fi

# Fallback defaults if partially set
MODE="${MODE:-region}"
AUDIO_TYPE="${AUDIO_TYPE:-desktop}"

# --- 5. PREPARE DESTINATION ---
mkdir -p "$SAVE_DIR"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
OUTPUT_FILE="$SAVE_DIR/recording_${TIMESTAMP}.mp4"

# --- 6. SETUP AUDIO STREAMS ---
RECORDER_ARGS=("-c" "libx264" "-p" "yuv420p" "-f" "$OUTPUT_FILE")

setup_mixed_audio() {
    local default_sink
    default_sink=$(pactl get-default-sink 2>/dev/null)
    local default_source
    default_source=$(pactl get-default-source 2>/dev/null)

    local sink_mod
    sink_mod=$(pactl load-module module-null-sink sink_name=hypr_recorder_mix sink_properties=device.description=Hypr_Recorder_Mix 2>/dev/null)
    local l1
    l1=$(pactl load-module module-loopback source="${default_sink}.monitor" sink=hypr_recorder_mix latency_msec=20 2>/dev/null)
    local l2
    l2=$(pactl load-module module-loopback source="${default_source}" sink=hypr_recorder_mix latency_msec=20 2>/dev/null)

    echo "$l2" >> "$MODULES_FILE"
    echo "$l1" >> "$MODULES_FILE"
    echo "$sink_mod" >> "$MODULES_FILE"

    echo "hypr_recorder_mix.monitor"
}

case "$AUDIO_TYPE" in
    desktop)
        RECORDER_ARGS+=("-C" "aac" "-R" "48000")
        DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null)
        if [[ -n "$DEFAULT_SINK" ]]; then
            RECORDER_ARGS+=("--audio=${DEFAULT_SINK}.monitor")
        else
            RECORDER_ARGS+=("--audio")
        fi
        ;;
    mic)
        RECORDER_ARGS+=("-C" "aac" "-R" "48000" "--audio")
        ;;
    both)
        RECORDER_ARGS+=("-C" "aac" "-R" "48000")
        MIXED_DEV=$(setup_mixed_audio)
        RECORDER_ARGS+=("--audio=${MIXED_DEV}")
        ;;
    none)
        # No audio flags added
        ;;
esac

# --- 7. SELECT CAPTURE TARGET ---
if [[ "$MODE" == "region" ]]; then
    # Close SwayNC panel so it doesn't block the selection overlay
    swaync-client -cp >/dev/null 2>&1 || true
    sleep 0.05

    GEOM=$(slurp)
    if [[ -z "$GEOM" ]]; then
        cleanup_audio_modules
        exit 0
    fi
    RECORDER_ARGS+=("-g" "$GEOM")
else
    ACTIVE_OUTPUT=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .name' | head -1)
    if [[ -n "$ACTIVE_OUTPUT" ]]; then
        RECORDER_ARGS+=("-o" "$ACTIVE_OUTPUT")
    fi
fi

# --- 8. LAUNCH RECORDING ---
wf-recorder "${RECORDER_ARGS[@]}" >/dev/null 2>&1 &
RECORDER_PID=$!

echo "$RECORDER_PID" > "$PID_FILE"
echo "$OUTPUT_FILE" > "$INFO_FILE"
pkill -RTMIN+9 waybar 2>/dev/null || true

case "$AUDIO_TYPE" in
    desktop)
        notify "Recording Started 🔊" "Recording screen + desktop audio...\nPress Super+Shift+R to stop."
        ;;
    both)
        notify "Recording Started 🎧" "Recording screen + desktop audio + microphone...\nPress Super+Shift+R to stop."
        ;;
    mic)
        notify "Recording Started 🎙️" "Recording screen + microphone...\nPress Super+Shift+R to stop."
        ;;
    none)
        notify "Recording Started 📹" "Recording screen (video only)...\nPress Super+Shift+R to stop."
        ;;
esac
