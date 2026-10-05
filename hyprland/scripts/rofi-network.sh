#!/usr/bin/env bash

# ==============================================================================
# SCRIPT: rofi-network.sh
# PURPOSE: Interactive Rofi Network Hub (Wi-Fi, Ethernet & Hotspot)
# ==============================================================================

ROFI_THEME="$HOME/.config/rofi/themes/selector.rasi"

notify_net() {
    local title="$1"
    local msg="$2"
    local urgency="${3:-normal}"
    notify-send -a "Network Hub" -u "$urgency" -i "network-wireless" "$title" "$msg" 2>/dev/null || true
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

# --- 1. PROBE HARDWARE ---
WIFI_DEV=$(nmcli -t -f DEVICE,TYPE device status | grep ":wifi$" | cut -d':' -f1 | head -1)
ETH_DEV=$(nmcli -t -f DEVICE,TYPE device status | grep ":ethernet$" | cut -d':' -f1 | head -1)

# Check Wi-Fi Radio state
WIFI_RADIO=$(nmcli radio wifi 2>/dev/null)

# --- 2. BUILD MENU ENTRIES ---
build_menu() {
    local entries=()

    # --- ETHERNET STATUS ---
    if [[ -n "$ETH_DEV" ]]; then
        local eth_state
        eth_state=$(nmcli -t -f DEVICE,STATE device status | grep "^${ETH_DEV}:" | cut -d':' -f2)
        local eth_ip
        eth_ip=$(nmcli -g IP4.ADDRESS device show "$ETH_DEV" 2>/dev/null | head -1 | cut -d'/' -f1)

        case "$eth_state" in
            connected)
                entries+=("󰈀 Ethernet (${ETH_DEV}) • Connected [${eth_ip:-Active}]")
                ;;
            connecting*)
                entries+=("󰈀 Ethernet (${ETH_DEV}) • Connecting...")
                ;;
            disconnected)
                entries+=("󰈂 Ethernet (${ETH_DEV}) • Cable Plugged (Click to Connect)")
                ;;
            unavailable)
                entries+=("󰈂 Ethernet (${ETH_DEV}) • Cable Unplugged")
                ;;
            *)
                entries+=("󰈂 Ethernet (${ETH_DEV}) • ${eth_state}")
                ;;
        esac
    fi

    # --- WI-FI STATUS & LIST ---
    if [[ "$WIFI_RADIO" != "enabled" ]]; then
        entries+=("󰤮 Wi-Fi is OFF (Click to Turn ON)")
    else
        # Find active connected Wi-Fi SSID
        local active_wifi
        active_wifi=$(nmcli -t -f IN-USE,SSID,SIGNAL device wifi list 2>/dev/null | grep "^\*:" | head -1)
        if [[ -n "$active_wifi" ]]; then
            local act_ssid act_sig
            act_ssid=$(echo "$active_wifi" | cut -d':' -f2)
            act_sig=$(echo "$active_wifi" | cut -d':' -f3)
            entries+=("● 󰤨 ${act_ssid} [Connected • ${act_sig}%]")
        fi

        # Scan nearby networks
        # Format: IN-USE:SSID:SIGNAL:SECURITY
        local wifi_list
        wifi_list=$(nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list 2>/dev/null)

        # Parse & deduplicate SSIDs
        declare -A seen_ssids
        while IFS=':' read -r in_use ssid signal security; do
            [[ -z "$ssid" || "$in_use" == "*" ]] && continue
            [[ -n "${seen_ssids[$ssid]}" ]] && continue
            seen_ssids["$ssid"]=1

            local icon="󰤨"
            if (( signal < 30 )); then
                icon="󰤟"
            elif (( signal < 60 )); then
                icon="󰤢"
            elif (( signal < 85 )); then
                icon="󰤥"
            fi

            local sec_icon=""
            [[ "$security" =~ WPA|WEP|802.1x ]] && sec_icon=" 󰌾"

            entries+=("  ${icon}${sec_icon} ${ssid} (${signal}%)")
        done <<< "$wifi_list"

        entries+=("󰤮 Turn Wi-Fi OFF")
        entries+=("󰑐 Rescan Wi-Fi Networks")
    fi

    printf "%s\n" "${entries[@]}"
}

# --- 3. HANDLE ACTIONS ---
handle_ethernet() {
    local eth_state
    eth_state=$(nmcli -t -f DEVICE,STATE device status | grep "^${ETH_DEV}:" | cut -d':' -f2)

    if [[ "$eth_state" == "connected" ]]; then
        local eth_ip
        eth_ip=$(nmcli -g IP4.ADDRESS device show "$ETH_DEV" 2>/dev/null | head -1 | cut -d'/' -f1)
        local opt
        opt=$(printf "🔄 Renew DHCP Lease / Reconnect\n󰈂 Disconnect Ethernet\n📋 Copy IP Address (%s)\n🔙 Back" "${eth_ip:-N/A}" | rofi_cmd "Ethernet (${ETH_DEV})")
        case "$opt" in
            *"Renew"*)
                notify_net "Ethernet" "Re-negotiating DHCP lease on ${ETH_DEV}..."
                nmcli device reapply "$ETH_DEV" 2>/dev/null || nmcli device connect "$ETH_DEV" 2>/dev/null
                notify_net "Ethernet" "Ethernet renewed successfully."
                ;;
            *"Disconnect"*)
                nmcli device disconnect "$ETH_DEV"
                notify_net "Ethernet" "Disconnected ${ETH_DEV}."
                ;;
            *"Copy IP"*)
                echo -n "$eth_ip" | wl-copy
                notify_net "Ethernet" "Copied ${eth_ip} to clipboard."
                ;;
        esac
    elif [[ "$eth_state" == "disconnected" ]]; then
        notify_net "Ethernet" "Connecting ${ETH_DEV}..."
        nmcli device connect "$ETH_DEV"
    elif [[ "$eth_state" == "unavailable" ]]; then
        notify_net "Ethernet" "Ethernet cable is unplugged. Plug cable in to connect." "low"
    fi
}

handle_wifi_connect() {
    local target_ssid="$1"
    notify_net "Wi-Fi" "Connecting to ${target_ssid}..."

    # Check if network is already saved
    local is_saved
    is_saved=$(nmcli -t -f NAME connection show | grep -Fx "$target_ssid" | head -1)

    if [[ -n "$is_saved" ]]; then
        if nmcli connection up "$target_ssid" >/dev/null 2>&1; then
            notify_net "Wi-Fi Connected" "Connected to ${target_ssid}."
        else
            notify_net "Wi-Fi Error" "Failed to connect to saved network ${target_ssid}." "critical"
        fi
        return
    fi

    # Check if network requires security
    local sec_info
    sec_info=$(nmcli -t -f SSID,SECURITY device wifi list 2>/dev/null | grep "^${target_ssid}:" | cut -d':' -f2 | head -1)

    if [[ -n "$sec_info" && "$sec_info" != "--" ]]; then
        local pass
        pass=$(rofi_cmd "Password for ${target_ssid}" -password)
        [[ -z "$pass" ]] && exit 0

        local res
        res=$(nmcli dev wifi connect "$target_ssid" password "$pass" 2>&1)
        if [[ "$res" == *"successfully activated"* ]]; then
            notify_net "Wi-Fi Connected" "Successfully connected to ${target_ssid}."
        else
            notify_net "Wi-Fi Failed" "Authentication error connecting to ${target_ssid}." "critical"
        fi
    else
        # Open network (no password)
        if nmcli dev wifi connect "$target_ssid" >/dev/null 2>&1; then
            notify_net "Wi-Fi Connected" "Connected to ${target_ssid}."
        else
            notify_net "Wi-Fi Failed" "Could not connect to ${target_ssid}." "critical"
        fi
    fi
}

handle_active_wifi() {
    local ssid="$1"
    local opt
    opt=$(printf "󰤮 Disconnect from %s\n📋 Copy Wi-Fi IP Address\n🔙 Back" "$ssid" | rofi_cmd "Wi-Fi: ${ssid}")
    case "$opt" in
        *"Disconnect"*)
            nmcli connection down "$ssid" 2>/dev/null || nmcli device disconnect "$WIFI_DEV" 2>/dev/null
            notify_net "Wi-Fi" "Disconnected from ${ssid}."
            ;;
        *"Copy Wi-Fi IP"*)
            local ip
            ip=$(nmcli -g IP4.ADDRESS device show "$WIFI_DEV" 2>/dev/null | head -1 | cut -d'/' -f1)
            echo -n "$ip" | wl-copy
            notify_net "Wi-Fi" "Copied ${ip} to clipboard."
            ;;
    esac
}

# --- 4. MAIN ROUTER ---
main() {
    local choice
    choice=$(build_menu | rofi_cmd "󰤨 Network Hub")
    [[ -z "$choice" ]] && exit 0

    case "$choice" in
        *"Ethernet"*)
            handle_ethernet
            ;;
        *"Wi-Fi is OFF"*)
            nmcli radio wifi on
            notify_net "Wi-Fi" "Wi-Fi radio turned ON."
            ;;
        *"Turn Wi-Fi OFF"*)
            nmcli radio wifi off
            notify_net "Wi-Fi" "Wi-Fi radio turned OFF."
            ;;
        *"Rescan Wi-Fi"*)
            notify_net "Wi-Fi" "Rescanning wireless networks..."
            nmcli dev wifi rescan 2>/dev/null
            sleep 1
            exec "$0"
            ;;
        "● "*)
            # Active connected network clicked
            local current_ssid
            current_ssid=$(echo "$choice" | sed -E 's/● 󰤨 //; s/ \[Connected.*//')
            handle_active_wifi "$current_ssid"
            ;;
        "  "*)
            # Available network clicked
            local selected_ssid
            selected_ssid=$(echo "$choice" | sed -E 's/^  [^ ]+ //; s/ \([0-9]+%\)$//')
            handle_wifi_connect "$selected_ssid"
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
