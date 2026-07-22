#!/bin/bash
# Install ydotool/ydotoold across distros, with permission fixes and testing.
# Copyright (C) 2026 by Henry Kroll III, www.thenerdshow.com
#
# This is free software.  You may redistribute it under the terms
# of the Apache license and the GNU General Public License Version
# 2 or at your option any later version.

set -e

# Cleanup temp directory on exit (e.g. failed source build)
cleanup() {
    if [ -n "${TMPDIR:-}" ] && [ -d "$TMPDIR" ]; then
        rm -rf "$TMPDIR"
    fi
}
trap cleanup EXIT

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

# ── root check ───────────────────────────────────────────────────────────────
heading "Root permissions"
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Re-executing with sudo..."
    exec sudo bash "$0" "$@"
fi
echo "  ✓ Running as root"

# ── early abort (already functional) ─────────────────────────────────────────
heading "Checking if already functional"
if command -v ydotool &>/dev/null && [ -S /tmp/.ydotool_socket ]; then
    if su - "$SUDO_USER" -c "test -S /tmp/.ydotool_socket" 2>/dev/null; then
        check 0 "ydotool is already installed and running"
        echo
        echo "  Nothing to do. If you need to troubleshoot, run:"
        echo "    sudo journalctl -u ydotoold -b | tail -n 20"
        exit 0
    fi
fi

# ── distro detection ─────────────────────────────────────────────────────────
heading "Distro detection"
if   [ -f /etc/fedora-release ] || [ -f /etc/centos-release ] || [ -f /etc/redhat-release ]; then
    DISTRO="fedora"
    PKG_INSTALL="dnf install -y"
    PKGS="sox curl lame ydotool jq"
    YDOTOOL_SVC="ydotool"
elif [ -f /etc/debian_version ]; then
    DISTRO="debian"
    PKG_INSTALL="apt install -y"
    PKGS="sox curl lame ydotool openai-whisper libsox-fmt-mp3 jq"
    YDOTOOL_SVC="ydotoold"
elif command -v pacman &>/dev/null; then
    DISTRO="arch"
    PKG_INSTALL="pacman -S --noconfirm"
    PKGS="sox curl lame ydotool jq"
    YDOTOOL_SVC="ydotoold"
else
    DISTRO="unknown"
    echo "  ! Unrecognized distro — will attempt source build"
fi
echo "  ✓ Detected: ${DISTRO^}"

# ── install via package manager (if available) ───────────────────────────────
heading "Package installation"
INSTALL_OK=1
if [ "$DISTRO" != "unknown" ]; then
    if $PKG_INSTALL $PKGS; then
        INSTALL_OK=0
        check 0 "Packages installed: $PKGS"
    else
        echo "  ! Package install failed; falling back to source build"
    fi
else
    echo "  ! No package manager match; will build from source"
fi

# ── source build (fallback or unknown distro) ────────────────────────────────
if [ "$INSTALL_OK" -ne 0 ] || ! command -v ydotool &>/dev/null; then
    heading "Source build"
    for _cmd in git cmake make; do
        if ! command -v "$_cmd" &>/dev/null; then
            echo "  ! $_cmd not found -- cannot build from source"
            echo "    Install $_cmd and re-run this script."
            check 1 "Missing dependency: $_cmd"
            exit 1
        fi
    done
    TMPDIR=$(mktemp -d)
    cd "$TMPDIR"
    git clone --depth=1 https://github.com/ReimuNotMoe/ydotool.git .
    mkdir build && cd build
    cmake -DSYSTEMD_SYSTEM_SERVICE=ON -DSYSTEMD_USER_SERVICE=OFF ..
    make -j "$(nproc)"
    cp ./ydotool /usr/local/bin/ydotool
    cp ./ydotoold /usr/local/bin/ydotoold
    cp ./ydotoold.service /etc/systemd/system/
    systemctl daemon-reload
    check 0 "Built ydotool from source -> /usr/local/bin"
fi

# ── ensure binaries exist ────────────────────────────────────────────────────
BIN_OK=1
if command -v ydotool &>/dev/null; then
    BIN_OK=0
    check 0 "ydotool found at $(which ydotool)"
else
    check 1 "ydotool not found — installation failed"
fi
if command -v ydotoold &>/dev/null; then
    check 0 "ydotoold found at $(which ydotoold)"
else
    check 1 "ydotoold not found"
fi

# ── systemd service ──────────────────────────────────────────────────────────
heading "Systemd service"
SVC_OK=1

# Determine correct service unit name
if [ -f /etc/systemd/system/ydotoold.service ]; then
    YDOTOOL_SVC="ydotoold"
elif [ -f /etc/systemd/system/ydotool.service ]; then
    YDOTOOL_SVC="ydotool"
fi

# If no service file exists, copy one from known locations
if [ ! -f "/etc/systemd/system/${YDOTOOL_SVC}.service" ]; then
    for src in \
        /usr/lib/systemd/system/ydotoold.service \
        /usr/local/lib/systemd/system/ydotoold.service \
        /usr/share/ydotool/ydotoold.service \
        /usr/lib/systemd/system/ydotool.service; do
        if [ -f "$src" ]; then
            cp "$src" "/etc/systemd/system/${YDOTOOL_SVC}.service"
            break
        fi
    done
fi

if [ -f "/etc/systemd/system/${YDOTOOL_SVC}.service" ]; then
    systemctl daemon-reload
    systemctl enable "$YDOTOOL_SVC" 2>/dev/null || true
    systemctl start "$YDOTOOL_SVC" 2>/dev/null || true
    sleep 1
    if systemctl is-active --quiet "$YDOTOOL_SVC"; then
        SVC_OK=0
        check 0 "Service ${YDOTOOL_SVC} is active (running)"
    else
        echo "  ! Service ${YDOTOOL_SVC} found but not active"
        echo "    Check: journalctl -u ${YDOTOOL_SVC} -b | tail -n 20"
    fi
else
    echo "  ! No systemd service file found for ydotool"
    echo "    You may need to start ydotoold manually"
fi

# ── permissions ──────────────────────────────────────────────────────────────
heading "Permissions"

# setuid bit
chmod +s "$(which ydotool)" 2>/dev/null && \
    check 0 "setuid bit set on $(which ydotool)" || \
    check 1 "setuid bit could not be set"

# input group
GROUP_OK=1
if getent group input &>/dev/null; then
    if groups "$SUDO_USER" | grep -q input; then
        check 0 "User $SUDO_USER is in the 'input' group"
    else
        usermod -aG input "$SUDO_USER"
        echo "  ✓ Added $SUDO_USER to the 'input' group (log out & back in)"
    fi
else
    check 1 "'input' group does not exist on this system"
fi

# ── socket link ──────────────────────────────────────────────────────────────
heading "Socket link"
SOCK_LINK_OK=1
if [ -S /tmp/.ydotool_socket ]; then
    SOCK_LINK_OK=0
    check 0 "Socket exists at /tmp/.ydotool_socket"
else
    # Try to find the socket
    FOUND_SOCK=$(find /run/user /tmp -maxdepth 2 -name "*.ydotool_socket" -type s 2>/dev/null | head -1)
    if [ -n "$FOUND_SOCK" ]; then
        ln -sf "$FOUND_SOCK" /tmp/.ydotool_socket
        SOCK_LINK_OK=0
        check 0 "Symlinked $FOUND_SOCK -> /tmp/.ydotool_socket"
    else
        # If the service is running but socket doesn't exist, the daemon
        # may not have created it yet; restart and wait
        if systemctl is-active --quiet "$YDOTOOL_SVC" 2>/dev/null; then
            echo "  ! Socket not found; restarting service..."
            systemctl restart "$YDOTOOL_SVC" 2>/dev/null || true
            sleep 2
            if [ -S /tmp/.ydotool_socket ]; then
                SOCK_LINK_OK=0
                check 0 "Socket created after restart"
            else
                check 1 "Socket still not found after restart"
            fi
        else
            check 1 "Socket not found — is ydotoold running?"
        fi
    fi
fi

# ── ydotool socket in bashrc ─────────────────────────────────────────────────
heading "Shell config"
BASHRC_OK=1
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    BASHRC="$USER_HOME/.bashrc"
    if grep -q "YDOTOOL_SOCKET" "$BASHRC" 2>/dev/null; then
        BASHRC_OK=0
        check 0 "YDOTOOL_SOCKET export found in $BASHRC"
    else
        su - "$SUDO_USER" -c "echo '' >> \"$BASHRC\""
        su - "$SUDO_USER" -c "echo '# Ydotool socket path (installed by install_ydotoold)' >> \"$BASHRC\""
        su - "$SUDO_USER" -c "echo 'export YDOTOOL_SOCKET=/tmp/.ydotool_socket' >> \"$BASHRC\""
        BASHRC_OK=0
        echo "  ✓ Added YDOTOOL_SOCKET export to $BASHRC"
    fi
else
    echo "  ! SUDO_USER not set; skipping .bashrc update"
fi

# ── test ─────────────────────────────────────────────────────────────────────
heading "Smoke test"
TEST_OK=1
if command -v ydotool &>/dev/null; then
    # Run as the original user (not root) so the socket connection works
    if [ -n "$SUDO_USER" ]; then
        if su - "$SUDO_USER" -c "YDOTOOL_SOCKET=/tmp/.ydotool_socket ydotool type 'ydotool test OK'" 2>/dev/null; then
            TEST_OK=0
            check 0 "ydotool type command executed successfully"
        else
            # Try as root
            if YDOTOOL_SOCKET=/tmp/.ydotool_socket ydotool type 'ydotool test OK' 2>/dev/null; then
                TEST_OK=0
                check 0 "ydotool type command executed (as root)"
            else
                check 1 "ydotool type test failed — check journalctl"
            fi
        fi
    else
        if YDOTOOL_SOCKET=/tmp/.ydotool_socket ydotool type 'ydotool test OK' 2>/dev/null; then
            TEST_OK=0
            check 0 "ydotool type command executed successfully"
        else
            check 1 "ydotool type test failed"
        fi
    fi
else
    check 1 "ydotool not installed — cannot test"
fi

# ── summary ──────────────────────────────────────────────────────────────────
heading "Success checklist"
echo "  Step                     Status"
echo "  ───────────────────────────────────────────────────"
echo "  1. Root permissions      $([ "$(id -u)" -eq 0 ] && echo "✓" || echo "✗")"
echo "  2. Distro detection      $([ -n "$DISTRO" ] && echo "✓" || echo "✗")"
echo "  3. Package installation  $([ "$INSTALL_OK" -eq 0 ] && echo "✓" || echo "✗")"
echo "  4. Binary installed      $([ "$BIN_OK" -eq 0 ] && echo "✓" || echo "✗")"
echo "  5. Systemd service       $([ "$SVC_OK" -eq 0 ] && echo "✓" || echo "✗")"
echo "  6. Setuid + input group  $([ -u "$(which ydotool 2>/dev/null)" ] && echo "✓" || echo "✗")"
echo "  7. Socket accessible     $([ "$SOCK_LINK_OK" -eq 0 ] && echo "✓" || echo "✗")"
echo "  8. Shell config updated  $([ "$BASHRC_OK" -eq 0 ] && echo "✓" || echo "✗")"
echo "  9. Smoke test passed     $([ "$TEST_OK" -eq 0 ] && echo "✓" || echo "✗")"
echo
echo "After installation, log out and back in (or run 'newgrp input')"
echo "to pick up the group membership, then source your .bashrc:"
echo "  source ~/.bashrc"
echo
echo "Then test with:"
echo "  ydotool type 'hello world'"
echo "  ./voice_typing"