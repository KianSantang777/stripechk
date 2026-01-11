#!/bin/bash
# ==========================================================
# stripechk Universal Installer (Termux / Linux / Ubuntu)
# Author: Kian Santang
# GitHub: https://github.com/KianSantang777/stripechk
# ==========================================================

set -e

# -----------------------------
# UI Elements (Spinner + Colors)
# -----------------------------

spin() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

print_header() {
    clear
    echo ""
    echo "==============================================="
    echo "          stripechk AUTO INSTALLER          "
    echo "==============================================="
    echo ""
}

print_step() {
    echo ""
    echo "───────────────────────────────────────────────"
    echo "▶ Step $1: $2"
    echo "───────────────────────────────────────────────"
}

success() {
    echo -e "\e[32m✔ Success:\e[0m $1"
}

error_exit() {
    echo -e "\n\e[31m✖ Error:\e[0m $1"
    exit 1
}

# -----------------------------
# Platform Detection
# -----------------------------

print_header

if [ -d "/data/data/com.termux" ]; then
    PLATFORM="termux"
    PYTHON_CMD="python"
    PKG_MGR="pkg"
    SUDO=""
    echo "Environment detected: Termux (Android)"
else
    PLATFORM="linux"
    PYTHON_CMD="python3"
    PKG_MGR="apt"
    SUDO="sudo"
    echo "Environment detected: Linux / Ubuntu / Debian"
fi

sleep 1

# -----------------------------
# Step 1: System Update
# -----------------------------
print_step 1 "Updating and upgrading the system..."
(
    if [ "$PLATFORM" = "termux" ]; then
        pkg update -y && pkg upgrade -y
    else
        $SUDO apt update -y && $SUDO apt upgrade -y
    fi
) & spin
success "System update complete."

# -----------------------------
# Step 2: Termux Storage Permission
# -----------------------------
if [ "$PLATFORM" = "termux" ]; then
    print_step 2 "Requesting Termux storage permission..."
    (termux-setup-storage) & spin
    success "Storage permission granted."
fi

# -----------------------------
# Step 3: Install Dependencies
# -----------------------------
print_step 3 "Installing required packages..."
(
    if [ "$PLATFORM" = "termux" ]; then
        pkg install -y python git nano
    else
        $SUDO apt install -y python3 python3-pip git nano software-properties-common
    fi
) & spin
success "All required packages installed."

# -----------------------------
# Step 4: Verify Python
# -----------------------------
print_step 4 "Checking Python installation..."
$PYTHON_CMD -V >/dev/null 2>&1 || error_exit "Python not found!"
success "Python detected: $($PYTHON_CMD -V 2>&1)"

# -----------------------------
# Step 5: Navigate to Project Directory
# -----------------------------
print_step 5 "Locating stripechk directory..."

PROJECT_DIR="$HOME/stripechk"

if [ -d "$PROJECT_DIR" ]; then
    cd "$PROJECT_DIR"
    success "Directory found: $PROJECT_DIR"
else
    error_exit "stripechk directory not found in HOME. Please clone it first."
fi

# -----------------------------
# Step 6: Install Python Dependencies
# -----------------------------
print_step 6 "Installing Python dependencies..."
(
    if [ -f "requirements.txt" ]; then
        $PYTHON_CMD -m pip install --upgrade pip
        $PYTHON_CMD -m pip install -r requirements.txt
    else
        error_exit "requirements.txt not found!"
    fi
) & spin
success "Python dependencies installed."

# -----------------------------
# Step 7: Fix Permissions
# -----------------------------
print_step 7 "Setting directory permissions..."
(chmod -R 755 "$PROJECT_DIR") & spin
success "Permissions updated."


APP_PATH="$PROJECT_DIR/card.py"

if [ ! -f "$APP_PATH" ]; then
    error_exit "File not found: $APP_PATH"
fi

echo ""
echo "==============================================="
echo "   Starting card.py (auto-restart ON)    "
echo "   Press CTRL + C to stop manually             "
echo "==============================================="
echo ""

sleep 1

while true; do
    $PYTHON_CMD "$APP_PATH"
    echo ""
    echo "↻ card.py stopped. Restarting in 5 seconds..."
    sleep 5
done
