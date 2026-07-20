#!/bin/bash
# Install voice typing dependencies and configure your setup.
# Copyright (C) 2026 by Henry Kroll III, www.thenerdshow.com
#
# This is free software.  You may redistribute it under the terms
# of the Apache license and the GNU General Public License Version
# 2 or at your option any later version.

set -e

# ── helpers ──────────────────────────────────────────────────────────────────
check() {
    local step="$1" msg="$2"
    if [ "$step" -eq 0 ]; then
        echo "  ✓ $msg"
    else
        echo "  ✗ $msg"
    fi
    return "$step"
}

heading() {
    echo
    echo "── $1 ──"
}

confirm() {
    local prompt="$1" default="${2:-y}"
    local yn
    while true; do
        read -r -p "  $prompt (${default}/n) " yn
        yn="${yn:-$default}"
        case "$yn" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "  Please answer y or n." ;;
        esac
    done
}

cmd_exists() {
    command -v "$1" &>/dev/null
}

# ── welcome ──────────────────────────────────────────────────────────────────
heading "Voice Typing Installer"
echo
echo "  This script will help you install and configure the"
echo "  voice typing tools for private, offline speech-to-text."
echo
echo "  Three modes are available:"
echo
echo "    1. voice_typing (standalone)"
echo "       Uses whisper-cli (whisper.cpp) directly. Slower but simple."
echo "       Dependencies: sox, lame, ydotool, whisper-cli, a model file"
echo
echo "    2. voice_client_local (local server)"
echo "       Runs a whisper.cpp server as a user service."
echo "       Faster, always-on. Needs whisper.cpp compiled."
echo "       Dependencies: sox, lame, ydotool, curl, jq"
echo
echo "    3. voice_client (remote server)"
echo "       Connects to a whisper.cpp server on your network."
echo "       Dependencies: sox, lame, ydotool, curl, jq"
echo

# ── mode selection ───────────────────────────────────────────────────────────
while true; do
    read -r -p "  Select mode [1-3]: " mode
    case "$mode" in
        1) MODE="voice_typing"; break ;;
        2) MODE="voice_client_local"; break ;;
        3) MODE="voice_client"; break ;;
        *) echo "  Please enter 1, 2, or 3." ;;
    esac
done
echo "  ✓ Selected: $MODE"

# ── distro detection (for package install commands) ──────────────────────────
heading "Distro detection"
if [ -f /etc/fedora-release ] || [ -f /etc/centos-release ] || [ -f /etc/redhat-release ]; then
    DISTRO="fedora"
    PKG_INSTALL="sudo dnf install -y"
    PKG_QUERY="rpm -q"
    echo "  ✓ Detected: Fedora/CentOS"
elif [ -f /etc/debian_version ]; then
    DISTRO="debian"
    PKG_INSTALL="sudo apt install -y"
    PKG_QUERY="dpkg -l"
    echo "  ✓ Detected: Debian/Ubuntu"
elif cmd_exists pacman; then
    DISTRO="arch"
    PKG_INSTALL="sudo pacman -S --noconfirm"
    PKG_QUERY="pacman -Q"
    echo "  ✓ Detected: Arch"
else
    DISTRO="unknown"
    PKG_INSTALL=""
    PKG_QUERY=""
    echo "  ! Unrecognized distro — will check for tools individually"
fi

# ── common dependencies ──────────────────────────────────────────────────────
heading "Common dependencies"

# sox
if cmd_exists sox; then
    check 0 "sox found"
else
    if confirm "sox is required for audio recording. Install?"; then
        $PKG_INSTALL sox 2>/dev/null && check 0 "sox installed" || check 1 "sox install failed"
    else
        echo "  ! sox is required. Cannot continue."
        exit 1
    fi
fi

# libsox-fmt-mp3 (Debian)
if [ "$DISTRO" = "debian" ]; then
    if dpkg -l libsox-fmt-mp3 &>/dev/null 2>&1; then
        check 0 "libsox-fmt-mp3 found"
    else
        if confirm "libsox-fmt-mp3 is needed for MP3 support in sox. Install?"; then
            $PKG_INSTALL libsox-fmt-mp3 2>/dev/null && check 0 "libsox-fmt-mp3 installed" || check 1 "libsox-fmt-mp3 install failed"
        fi
    fi
fi

# lame
if cmd_exists lame; then
    check 0 "lame found"
else
    if confirm "lame is required for MP3 encoding. Install?"; then
        $PKG_INSTALL lame 2>/dev/null && check 0 "lame installed" || check 1 "lame install failed"
    fi
fi

# curl (client modes)
if [ "$MODE" != "voice_typing" ]; then
    if cmd_exists curl; then
        check 0 "curl found"
    else
        if confirm "curl is required for server requests. Install?"; then
            $PKG_INSTALL curl 2>/dev/null && check 0 "curl installed" || check 1 "curl install failed"
        fi
    fi
fi

# jq (client modes)
if [ "$MODE" != "voice_typing" ]; then
    if cmd_exists jq; then
        check 0 "jq found"
    else
        if confirm "jq is required for JSON parsing. Install?"; then
            $PKG_INSTALL jq 2>/dev/null && check 0 "jq installed" || check 1 "jq install failed"
        fi
    fi
fi

# ── whisper backend ──────────────────────────────────────────────────────────
heading "Speech-to-text backend"

case "$MODE" in
    voice_typing)
        # Check for whisper-cli (whisper.cpp)
        if cmd_exists whisper-cli; then
            check 0 "whisper-cli found at $(which whisper-cli)"
        else
            echo "  whisper-cli not found in PATH."
            echo "  To compile whisper.cpp:"
            echo "    git clone https://github.com/ggerganov/whisper.cpp.git"
            echo "    cd whisper.cpp"
            echo "    cmake -B build"
            echo "    cmake --build build --config Release -j $(nproc)"
            echo "    sudo cp build/bin/whisper-cli /usr/local/bin/"
            echo
            if confirm "Continue without whisper-cli? (you can build it later)"; then
                :
            fi
        fi
        # Check for a model file
        if [ -n "${WHISPER_MODEL:-}" ] && [ -f "$WHISPER_MODEL" ]; then
            check 0 "model found at WHISPER_MODEL"
        elif ls "$HOME/Downloads/src/whisper.cpp/models/ggml-"*.bin &>/dev/null; then
            check 0 "model found in ~/Downloads/src/whisper.cpp/models/"
        else
            echo "  No whisper model file found."
            echo "  Download one after building whisper.cpp:"
            echo "    cd whisper.cpp && bash models/download-ggml-model.sh tiny.en"
            echo "  Or set WHISPER_MODEL=/path/to/model.bin"
        fi
        ;;
    voice_client_local)
        echo "  voice_client_local needs a whisper.cpp server running as a user service."
        echo "  Check if whisper-server is available..."
        if cmd_exists whisper-server; then
            check 0 "whisper-server found at $(which whisper-server)"
        else
            echo "  whisper-server not found in PATH."
            echo
            echo "  To compile whisper.cpp with server support:"
            echo "    git clone https://github.com/ggerganov/whisper.cpp.git"
            echo "    cd whisper.cpp"
            echo "    cmake -B build"
            echo "    cmake --build build --config Release -j $(nproc)"
            echo "    sudo cp build/bin/whisper-server /usr/local/bin/"
            echo ""
            echo "  Then download a model:"
            echo "    cd whisper.cpp"
            echo "    bash models/download-ggml-model.sh tiny.en"
            echo ""
            if confirm "Continue without whisper-server? (you can build it later)"; then
                :
            fi
        fi
        ;;
    voice_client)
        echo "  voice_client connects to a remote whisper.cpp server."
        echo "  No local whisper installation needed."
        ;;
esac

# ── ydotool (defer to install_ydotoold) ──────────────────────────────────────
heading "ydotool (virtual keyboard)"
if cmd_exists ydotool && [ -S /tmp/.ydotool_socket ]; then
    check 0 "ydotool is already installed and socket present"
else
    echo "  ydotool is needed to type text into the active window."
    if confirm "Run the ydotool installer (sudo ./install_ydotoold)?"; then
        echo "  The installer will handle distro detection, package install,"
        echo "  systemd service setup, permissions, and a smoke test."
        echo
        sudo bash "$(dirname "$0")/install_ydotoold"
        echo
        echo "  Note: You may need to log out and back in for group changes."
    else
        echo "  ! Skipping ydotool install. You'll need it to type text."
        echo "  Re-run: sudo ./install_ydotoold"
    fi
fi

# ── server configuration (client modes) ──────────────────────────────────────
if [ "$MODE" = "voice_client" ] || [ "$MODE" = "voice_client_local" ]; then
    heading "Server configuration"
    echo "  Default server: http://127.0.0.1:7777"
    if [ "$MODE" = "voice_client" ]; then
        if confirm "Use a different server address?" n; then
            read -r -p "  Enter server URL (e.g. http://192.168.1.50:7777): " server_url
            server_url="${server_url:-http://127.0.0.1:7777}"
            echo "  Server will be set to: $server_url"
            echo "  Edit voice_client and update the URL to:"
            echo "    curl -s \"$server_url/inference\""
        fi
    fi
fi

# ── whisper.service (local server mode) ──────────────────────────────────────
if [ "$MODE" = "voice_client_local" ]; then
    heading "Whisper user service"
    if systemctl --user --quiet is-active whisper.service 2>/dev/null; then
        check 0 "whisper.service is already active"
    elif [ -f "$HOME/.config/systemd/user/whisper.service" ]; then
        echo "  whisper.service exists but is not running."
        echo "  Start it with: systemctl --user start whisper.service"
    else
        echo "  voice_client_local needs a systemd user service for whisper-server."
        echo "  Create one at ~/.config/systemd/user/whisper.service"
        echo
        if confirm "Create whisper.service now?"; then
            echo
            echo "  Enter the path to your whisper-server binary."
            echo "  (default: ~/.local/bin/whisper-server)"
            read -r -p "  Path: " ws_path
            ws_path="${ws_path:-$HOME/.local/bin/whisper-server}"
            echo
            echo "  Enter the path to your model file."
            echo "  (default: ~/Downloads/src/whisper.cpp/models/ggml-tiny.en.bin)"
            read -r -p "  Model: " model_path
            model_path="${model_path:-$HOME/Downloads/src/whisper.cpp/models/ggml-tiny.en.bin}"
            echo
            echo "  Enter the port (default: 7777):"
            read -r -p "  Port: " port
            port="${port:-7777}"
            echo
            echo "  Extra flags (e.g. --convert -sns or leave blank):"
            read -r -p "  Flags: " extra_flags

            mkdir -p "$HOME/.config/systemd/user"
            cat > "$HOME/.config/systemd/user/whisper.service" <<EOF
[Unit]
Description=Whisper.cpp server for voice typing
Documentation=https://github.com/ggerganov/whisper.cpp

[Service]
ExecStart=$ws_path \\
-m $model_path \\
--port $port $extra_flags
Restart=on-failure

[Install]
WantedBy=default.target
EOF
            systemctl --user daemon-reload
            if confirm "Start whisper.service now?"; then
                systemctl --user start whisper.service
                if systemctl --user --quiet is-active whisper.service 2>/dev/null; then
                    check 0 "whisper.service started"
                else
                    echo "  ! Service failed to start. Check: journalctl --user -u whisper.service -b"
                fi
            fi
            if confirm "Enable whisper.service to start automatically?"; then
                systemctl --user enable whisper.service 2>/dev/null && check 0 "whisper.service enabled"
            fi
        else
            echo "  ! Skipping. You'll need to set up whisper.service manually."
            echo "  See README.md for instructions."
        fi
    fi
fi

# ── summary ──────────────────────────────────────────────────────────────────
heading "Installation complete"
echo
echo "  Mode:        $MODE"
echo "  Script:      ./$MODE"
echo "  To run:      ./$MODE"
echo "  With LLM:    ./$MODE -flow"
echo

if [ "$MODE" = "voice_typing" ]; then
    echo "  Make sure WHISPER_MODEL is set or a model file is in the default location."
    echo "  Set it in your .bashrc: export WHISPER_MODEL=/path/to/ggml-tiny.en.bin"
elif [ "$MODE" = "voice_client_local" ]; then
    if ! cmd_exists whisper-server; then
        echo "  Next steps — build whisper.cpp:"
        echo "    git clone https://github.com/ggerganov/whisper.cpp.git"
        echo "    cd whisper.cpp"
        echo "    cmake -B build && cmake --build build --config Release -j $(nproc)"
        echo "    sudo cp build/bin/whisper-server /usr/local/bin/"
        echo "    bash models/download-ggml-model.sh tiny.en"
        echo
    fi
    echo "  Make sure whisper.service is running:"
    echo "    systemctl --user start whisper.service"
    echo "    systemctl --user status whisper.service"
elif [ "$MODE" = "voice_client" ]; then
    echo "  Make sure your whisper.cpp server is reachable."
    echo "  Test with: curl -s http://127.0.0.1:7777/inference"
fi
echo
echo "  If ydotool was just installed, log out and back in, then:"
echo "    source ~/.bashrc"
echo "    ydotool type 'hello world'"
echo