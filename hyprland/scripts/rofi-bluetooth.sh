#!/usr/bin/env bash

# ==============================================================================
# SCRIPT: rofi-bluetooth.sh
# PURPOSE: Interactive Rofi Bluetooth Manager (Power, Pairing & Quick Connect)
# ==============================================================================

ROFI_THEME="$HOME/.config/rofi/themes/selector.rasi"

notify_bt() {
    local title="$1"
    local msg="$2"
    local urgency="${3:-normal}"
    notify-send -a "Bluetooth Hub" -u "$urgency" -i "bluetooth" "$title" "$msg" 2>/dev/null || true
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

get_device_icon() {
    local icon_type="$1"
    case "$icon_type" in
        audio-headset|audio-headphones|audio-card) echo "󰥰" ;;
        input-mouse)                              echo "󰍽" ;;
        input-keyboard)                           echo "󰌌" ;;
        input-gaming)                             echo "󰊴" ;;
        phone)                                    echo "󰏲" ;;
        computer)                                 echo "󰌢" ;;
        *)                                        echo "󰂯" ;;
    esac
}

is_powered() {
    bluetoothctl show 2>/dev/null | grep -q "Powered: yes"
}

# --- 1. BUILD MENU ---
build_menu() {
    local entries=()

    if ! is_powered; then
        echo "󰂲 Bluetooth is OFF (Click to Turn ON)"
        return
    fi

    # Read paired devices
    local paired_devices
    paired_devices=$(bluetoothctl devices 2>/dev/null)

    if [[ -n "$paired_devices" ]]; then
        while read -r _ mac name; do
            [[ -z "$mac" ]] && continue
            local info
            info=$(bluetoothctl info "$mac" 2>/dev/null)
            local connected="no" icon_type="" bat=""
            while IFS= read -r line; do
                if [[ "$line" =~ Connected:[[:space:]]+([a-zA-Z]+) ]]; then
                    connected="${BASH_REMATCH[1]}"
                elif [[ "$line" =~ Icon:[[:space:]]+([^[:space:]]+) ]]; then
                    icon_type="${BASH_REMATCH[1]}"
                elif [[ "$line" =~ Battery[[:space:]]+Percentage: ]]; then
                    if [[ "$line" =~ \(([0-9]+)\) ]]; then
                        bat="${BASH_REMATCH[1]}"
                    elif [[ "$line" =~ ([0-9]+)%? ]]; then
                        bat="${BASH_REMATCH[1]}"
                    fi
                fi
            done <<< "$info"

            local icon
            icon=$(get_device_icon "$icon_type")

            if [[ "$connected" == "yes" ]]; then
                if [[ -n "$bat" ]]; then
                    entries+=("● ${icon} ${name} [Connected • ${bat}% 󰥉] | ${mac}")
                else
                    entries+=("● ${icon} ${name} [Connected] | ${mac}")
                fi
            else
                entries+=("  ${icon} ${name} [Disconnected] | ${mac}")
            fi
        done <<< "$paired_devices"
    fi

    entries+=("󰑐 Scan for Nearby Devices")
    entries+=("󰂲 Turn Bluetooth OFF")

    printf "%s\n" "${entries[@]}"
}

# --- 2. DEVICE ACTIONS ---
handle_device() {
    local mac="$1"
    local name="$2"
    local is_connected="$3"

    if [[ "$is_connected" == "no" ]]; then
        notify_bt "Bluetooth" "Connecting to ${name}..."
        local res
        res=$(bluetoothctl connect "$mac" 2>&1)
        if [[ "$res" == *"Connection successful"* ]]; then
            notify_bt "Bluetooth Connected" "Connected to ${name}."
        else
            notify_bt "Bluetooth Failed" "Failed to connect to ${name}." "critical"
        fi
    else
        local opt
        opt=$(printf "󰂲 Disconnect %s\n🔄 Reconnect %s\n🗑️ Forget / Unpair %s\n🔙 Back" "$name" "$name" "$name" | rofi_cmd "Device: ${name}")
        case "$opt" in
            *"Disconnect"*)
                notify_bt "Bluetooth" "Disconnecting ${name}..."
                bluetoothctl disconnect "$mac" >/dev/null 2>&1
                notify_bt "Bluetooth" "Disconnected ${name}."
                ;;
            *"Reconnect"*)
                notify_bt "Bluetooth" "Re-connecting ${name}..."
                bluetoothctl disconnect "$mac" >/dev/null 2>&1
                sleep 0.5
                bluetoothctl connect "$mac" >/dev/null 2>&1
                notify_bt "Bluetooth" "Reconnected ${name}."
                ;;
            *"Forget"*)
                notify_bt "Bluetooth" "Removing pairing with ${name}..."
                bluetoothctl remove "$mac" >/dev/null 2>&1
                notify_bt "Bluetooth" "Unpaired ${name}."
                ;;
        esac
    fi
}

# --- 3. SCAN & PAIR ---
handle_scan() {
    notify_bt "Bluetooth" "Scanning for nearby devices (5 seconds)..."
    bluetoothctl --timeout 5 scan on >/dev/null 2>&1

    local discovered=()
    local paired_macs
    paired_macs=$(bluetoothctl devices Paired 2>/dev/null | awk '{print $2}')

    while read -r _ mac name; do
        [[ -z "$mac" || "$name" == *"-"* && ${#name} -eq 17 ]] && continue
        # Filter out already paired devices
        if echo "$paired_macs" | grep -q "$mac"; then
            continue
        fi
        discovered+=("󰂯 ${name} | ${mac}")
    done < <(bluetoothctl devices 2>/dev/null)

    if [[ ${#discovered[@]} -eq 0 ]]; then
        notify_bt "Bluetooth" "No new discoverable devices found." "low"
        return
    fi

    local choice
    choice=$(printf "%s\n" "${discovered[@]}" | rofi_cmd "󰑐 Available Devices")
    [[ -z "$choice" ]] && return

    local target_mac="${choice##* | }"
    local target_name="${choice%% | *}"
    target_name="${target_name#󰂯 }"

    notify_bt "Bluetooth" "Pairing with ${target_name}..."
    bluetoothctl pair "$target_mac" >/dev/null 2>&1
    bluetoothctl trust "$target_mac" >/dev/null 2>&1
    local res
    res=$(bluetoothctl connect "$target_mac" 2>&1)
    if [[ "$res" == *"Connection successful"* ]]; then
        notify_bt "Bluetooth Paired" "Paired and connected to ${target_name}."
    else
        notify_bt "Bluetooth Error" "Pairing completed, but connection failed." "critical"
    fi
}

# --- 4. MAIN ROUTER ---
main() {
    # Toggle off if Rofi is already running
    if pgrep -x "rofi" > /dev/null; then
        pkill rofi
        exit 0
    fi

    local menu_content
    menu_content=$(build_menu)
    [[ -z "$menu_content" ]] && exit 0

    local choice
    choice=$(printf "%s\n" "$menu_content" | rofi_cmd "󰂯 Bluetooth Hub")
    [[ -z "$choice" ]] && exit 0

    case "$choice" in
        *"Bluetooth is OFF"*)
            bluetoothctl power on >/dev/null 2>&1
            notify_bt "Bluetooth" "Bluetooth controller turned ON."
            ;;
        *"Turn Bluetooth OFF"*)
            bluetoothctl power off >/dev/null 2>&1
            notify_bt "Bluetooth" "Bluetooth controller turned OFF."
            ;;
        *"Scan for Nearby Devices"*)
            handle_scan
            ;;
        *" | "*)
            local mac="${choice##* | }"
            local name_part="${choice%% | *}"
            local dev_name="${name_part#[● ] }"
            dev_name="${dev_name#* }"
            dev_name="${dev_name% \[*}"

            if [[ "$choice" == "● "* ]]; then
                handle_device "$mac" "$dev_name" "yes"
            else
                handle_device "$mac" "$dev_name" "no"
            fi
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
