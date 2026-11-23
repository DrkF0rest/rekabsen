#!/bin/bash
set -euo pipefail

APP_NAME=rekabsen-adms
REPO=https://github.com/DrkF0rest/rekabsen-adms.git
APP_DIR=/etc/rekabsen
LOG_DIR=/var/log/rekabsen

# Monokai
PINK='\033[38;5;197m' GREEN='\033[38;5;148m' YELLOW='\033[38;5;186m'
PURPLE='\033[38;5;141m' CYAN='\033[38;5;81m' GRAY='\033[38;5;245m' RESET='\033[0m'

ok()   { echo -e "${GREEN}  ✓${RESET} $1"; }
die()  { echo -e "${PINK}  ✗${RESET} $1" >&2; exit 1; }
step() { echo -e "\n${PURPLE}[$1/6]${RESET} $2"; }

# Jalanin command dengan spinner kalau di terminal
run() {
    local msg=$1; shift
    if [[ ! -t 1 ]]; then "$@"; return; fi
    "$@" >/dev/null 2>&1 & local pid=$! i=0 f=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
    while kill -0 $pid 2>/dev/null; do
        printf "\r  ${PINK}%s${RESET} %s" "${f[i++ % 10]}" "$msg"; sleep 0.1
    done
    printf "\r\033[K"
    wait $pid && ok "$msg" || die "$msg failed"
}

[[ $EUID -eq 0 ]] || die "Run as root"
[[ ! -e $APP_DIR ]]   || die "$APP_DIR already exists"

echo -e "\n${GRAY}REKABSEN by DrkF0rest${RESET} ${PURPLE}installer${RESET}\n${GRAY}────────────────────────────────────${RESET}"

step 1 "Dependencies"
export DEBIAN_FRONTEND=noninteractive
run "Updating package index" apt-get update -qq
run "Installing packages" apt-get install -y -qq git python3 python3-venv python3-pip

step 2 "Repository"
run "Cloning repository" git clone --depth 1 --branch rekabsen-adms "$REPO"
mv "$APP_NAME/adms_server.py" "$APP_DIR"
mv "$APP_NAME/requirements.txt" "$APP_DIR"
mv "$APP_NAME/adms" "$APP_DIR"
mv "$APP_NAME/backend" "$APP_DIR"
[[ -f $APP_DIR/adms_server.py ]] || die "adms_server.py not found"

step 3 "Python environment"
run "Creating virtualenv" python3 -m venv "$APP_DIR/venv"
[[ -f $APP_DIR/requirements.txt ]] && run "Installing Python packages" "$APP_DIR/venv/bin/pip" install -q -r "$APP_DIR/requirements.txt"

step 4 "Permissions & logging"
id $APP_NAME &>/dev/null || useradd --system --no-create-home --shell /usr/sbin/nologin $APP_NAME
mkdir -p "$LOG_DIR"
chown -R $APP_NAME:$APP_NAME "$APP_DIR" "$LOG_DIR"
ok "Permissions configured"

step 5 "Systemd"
cat > /etc/systemd/system/$APP_NAME.service <<EOF
[Unit]
Description=Rekabsen ADMS Server by DrkF0rest
After=network.target

[Service]
User=$APP_NAME
Group=$APP_NAME
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/venv/bin/python3 $APP_DIR/adms_server.py
Restart=on-failure
RestartSec=5
StandardOutput=append:$LOG_DIR/access.log
StandardError=append:$LOG_DIR/error.log

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
ok "Systemd configured"

step 6 "Service"

cat > /usr/local/bin/rekabsen <<'EOF'
#!/bin/bash
S=rekabsen
APP_DIR=/etc/rekabsen
LOG_DIR=/var/log/rekabsen

PINK='\033[38;5;197m' GREEN='\033[38;5;148m' PURPLE='\033[38;5;141m'
CYAN='\033[38;5;81m' GRAY='\033[38;5;245m' WHITE='\033[38;5;255m' RESET='\033[0m'
[[ -t 1 ]] || PINK= GREEN= PURPLE= CYAN= GRAY= WHITE= RESET=

IP=$(hostname -I 2>/dev/null | awk '{print $1}')
STATUS=$(systemctl is-active $S 2>/dev/null || echo unknown)
PID=$(systemctl show $S -p MainPID --value 2>/dev/null)
UPTIME=$(systemctl show $S -p ActiveEnterTimestamp --value 2>/dev/null)

PORT=Unknown
if [[ $PID =~ ^[1-9][0-9]*$ ]]; then
    PORT=$(ss -H -ltnp 2>/dev/null | grep -F "pid=${PID}," | awk '{print $4}' \
        | sed 's/.*://' | sort -un | paste -sd ', ' -)
    PORT=${PORT:-Unknown}
fi

[[ $STATUS == active ]] && SC=$GREEN || SC=$PINK

line="────────────────────────────────────────"
row() { printf "  ${GRAY}%-15s${RESET} ${3:-}%s${RESET}\n" "$1" "$2"; }

[[ -t 1 ]] && clear

echo -e "\n  ${PURPLE}REKABSEN${RESET} ${GRAY}ADMS SERVER${RESET}"
echo -e "  ${GRAY}${line}${RESET}\n"
echo -e "  ${SC}●${RESET} Service ${SC}${STATUS^^}${RESET}\n"

echo -e "  ${CYAN}NETWORK${RESET}"
row "IP Address" "${IP:-Unknown}" "$WHITE"
row "Port"       "$PORT"          "$WHITE"
row "Endpoint"   "${IP:-Unknown}:${PORT}" "$CYAN"

echo -e "\n  ${PURPLE}APPLICATION${RESET}"
row "Directory"   "$APP_DIR"
row "Environment" "$APP_DIR/venv"
row "Logs"        "$LOG_DIR"

echo -e "\n  ${PURPLE}SERVICE INFORMATION${RESET}"
row "Process ID" "${PID:-N/A}"
row "Started"    "${UPTIME:-Unknown}"

echo -e "\n  ${PURPLE}MANAGEMENT${RESET}"
for c in "systemctl status $S" "systemctl restart $S" "systemctl stop $S" "journalctl -u $S -f"; do
    echo -e "  ${CYAN}${c}${RESET}"
done

echo -e "\n  ${PURPLE}Uninstall${RESET}"
curl -fsSL https://rekabsen.drkforest.site/uninstall.sh | bash

echo -e "\n  ${GRAY}${line}${RESET}"
echo -e "  ${GRAY}Rekabsen ADMS · Developed by DrkF0rest${RESET}\n"
EOF
chmod +x /usr/local/bin/rekabsen

systemctl enable --now $APP &>/dev/null
sleep 2
systemctl is-active --quiet $APP || { journalctl -u $APP -n 20 --no-pager; die "Service failed to start"; }
ok "Service is running"

echo -e "\n${GRAY}────────────────────────────────────${RESET}\n${GREEN}  Installation completed${RESET}  ${GRAY}(${SECONDS}s)${RESET}"
echo -e "  Run ${CYAN}rekabsen${RESET} for status info\n"