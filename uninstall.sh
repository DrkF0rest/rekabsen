#!/bin/bash
set -Eeuo pipefail

APP_NAME="rekabsen"
APP_DIR="/etc/rekabsen"
LOG_DIR="/var/log/rekabsen"
SERVICE_FILE="/etc/systemd/system/rekabsen.service"
BIN_FILE="/usr/local/bin/rekabsen"

# Monokai accents
PINK='\033[38;5;197m'
GREEN='\033[38;5;148m'
YELLOW='\033[38;5;186m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;245m'
RESET='\033[0m'

if [[ -t 1 ]]; then
    ANIMATION=true
else
    ANIMATION=false
fi

SPINNER=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

success() {
    echo -e "${GREEN}  ✓ ${RESET}$1"
}

warning() {
    echo -e "${YELLOW}  ! ${RESET}$1"
}

fail() {
    echo -e "${PINK}  ✗ ${RESET}$1" >&2
    exit 1
}

run() {
    local message="$1"
    shift

    if [[ "$ANIMATION" == false ]]; then
        "$@"
        success "$message"
        return
    fi

    "$@" >/dev/null 2>&1 &
    local pid=$!
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${PINK}%s${RESET} %s" \
            "${SPINNER[$((i % ${#SPINNER[@]}))]}" "$message"
        ((i+=1))
        sleep 0.1
    done

    if wait "$pid"; then
        printf "\r\033[K"
        success "$message"
    else
        printf "\r\033[K"
        fail "$message failed"
    fi
}

# Root check
[[ $EUID -eq 0 ]] || fail "Please run as root"

echo ""
echo -e "${GRAY}rekabsen-adms${RESET} ${PURPLE}uninstaller${RESET} ${GRAY}v1.0.0${RESET}"
echo -e "${GRAY}────────────────────────────────────${RESET}"
echo ""
echo "The following components will be removed:"
echo ""
echo "  - Systemd service"
echo "  - Application directory"
echo "  - Python virtual environment"
echo "  - Application logs"
echo "  - CLI command"
echo ""

read -r -p "Continue uninstall? [y/N]: " CONFIRM < /dev/tty

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    warning "Uninstallation cancelled"
    exit 0
fi

echo ""

# 1. Stop service
if systemctl list-unit-files "$APP_NAME.service" --no-legend |
    grep -q "$APP_NAME.service"; then

    run "Stopping service" systemctl stop "$APP_NAME"
    run "Disabling service" systemctl disable "$APP_NAME"
else
    warning "Service not found"
fi

# 2. Remove systemd service
if [[ -f "$SERVICE_FILE" ]]; then
    rm -f "$SERVICE_FILE"
    run "Reloading systemd" systemctl daemon-reload
    systemctl reset-failed "$APP_NAME" >/dev/null 2>&1 || true
else
    warning "Service file not found"
fi

# 3. Remove application
if [[ -d "$APP_DIR" ]]; then
    run "Removing application files" rm -rf -- "$APP_DIR"
else
    warning "Application directory not found"
fi

# 4. Remove logs
if [[ -d "$LOG_DIR" ]]; then
    run "Removing log files" rm -rf -- "$LOG_DIR"
else
    warning "Log directory not found"
fi

# 5. Remove CLI
if [[ -f "$BIN_FILE" ]]; then
    rm -f "$BIN_FILE"
    success "CLI command removed"
else
    warning "CLI command not found"
fi

rm -rf ../rekabsen-adms
cd
success "Removing application files"

echo ""
echo -e "${GRAY}────────────────────────────────────${RESET}"
echo -e "${GREEN}  Uninstallation completed${RESET}"
echo ""
echo "  Rekabsen has been removed."
echo ""
echo -e "${GRAY}────────────────────────────────────${RESET}"
echo ""
