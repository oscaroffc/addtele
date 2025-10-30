#!/bin/bash

# Setup Script for Telegram Auto Add Contact to Group
# Author: dika
# GitHub: https://github.com/oscaroffc

clear

echo "================================================================"
echo "     TELEGRAM AUTO ADD CONTACT TO GROUP - SETUP"
echo "================================================================"
echo "  Script by: dika"
echo "  GitHub: https://github.com/oscaroffc"
echo "================================================================"
echo ""

# Fungsi untuk mengecek command
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Fungsi untuk print dengan warna
print_success() {
    echo -e "\e[32m✓ $1\e[0m"
}

print_error() {
    echo -e "\e[31m✗ $1\e[0m"
}

print_warning() {
    echo -e "\e[33m⚠ $1\e[0m"
}

print_info() {
    echo -e "\e[36mℹ $1\e[0m"
}

# Deteksi OS
echo "🔍 Mendeteksi sistem operasi..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
    print_success "OS: Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="mac"
    print_success "OS: macOS"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    OS="windows"
    print_success "OS: Windows (Git Bash/Cygwin)"
else
    print_warning "OS tidak dikenali, melanjutkan sebagai Linux"
    OS="linux"
fi
echo ""

# Cek Python
echo "🔍 Mengecek instalasi Python..."
if command_exists python3; then
    PYTHON_CMD="python3"
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    print_success "Python3 ditemukan: v$PYTHON_VERSION"
elif command_exists python; then
    PYTHON_CMD="python"
    PYTHON_VERSION=$(python --version 2>&1 | awk '{print $2}')
    print_success "Python ditemukan: v$PYTHON_VERSION"
else
    print_error "Python tidak ditemukan!"
    echo ""
    echo "Silakan install Python terlebih dahulu:"
    if [[ "$OS" == "linux" ]]; then
        echo "  sudo apt update && sudo apt install python3 python3-pip"
    elif [[ "$OS" == "mac" ]]; then
        echo "  brew install python3"
    else
        echo "  Download dari: https://www.python.org/downloads/"
    fi
    exit 1
fi
echo ""

# Cek pip
echo "🔍 Mengecek instalasi pip..."
if command_exists pip3; then
    PIP_CMD="pip3"
    print_success "pip3 ditemukan"
elif command_exists pip; then
    PIP_CMD="pip"
    print_success "pip ditemukan"
else
    print_error "pip tidak ditemukan!"
    echo ""
    echo "Menginstall pip..."
    if [[ "$OS" == "linux" ]]; then
        sudo apt install python3-pip -y
    else
        $PYTHON_CMD -m ensurepip --upgrade
    fi
    PIP_CMD="pip3"
fi
echo ""

# Install dependencies
echo "📦 Menginstall dependencies..."
echo "================================================================"
echo ""

PACKAGES=("telethon" "asyncio")

for package in "${PACKAGES[@]}"; do
    echo "Installing $package..."
    $PIP_CMD install "$package" --upgrade
    if [ $? -eq 0 ]; then
        print_success "$package berhasil diinstall"
    else
        print_error "Gagal menginstall $package"
    fi
    echo ""
done

echo "================================================================"
echo ""

# Cek file run.sh
echo "🔍 Mengecek file script..."
if [ -f "run.sh" ]; then
    print_success "File run.sh ditemukan"
    
    # Buat executable
    chmod +x run.sh
    print_success "File run.sh dibuat executable"
else
    print_error "File run.sh tidak ditemukan!"
    echo ""
    echo "Pastikan file run.sh ada di direktori yang sama dengan setup.sh"
    exit 1
fi
echo ""

# Cek API credentials
echo "🔐 Mengecek API Credentials..."
API_ID=$(grep "API_ID = " run.sh | head -1 | cut -d "'" -f 2)
API_HASH=$(grep "API_HASH = " run.sh | head -1 | cut -d "'" -f 2)

if [ "$API_ID" == "13451379" ] || [ -z "$API_ID" ]; then
    print_warning "API_ID masih menggunakan default atau kosong!"
    echo ""
    echo "  ⚠️  PENTING: Ganti API_ID dan API_HASH di file run.sh"
    echo "  📍 Lokasi: Baris 28-29"
    echo "  🔗 Dapatkan di: https://my.telegram.org/apps"
    echo ""
    read -p "Apakah Anda sudah mengisi API_ID dan API_HASH? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        print_warning "Silakan isi API_ID dan API_HASH terlebih dahulu"
        echo ""
        echo "Cara mendapatkan API:"
        echo "  1. Buka https://my.telegram.org/apps"
        echo "  2. Login dengan nomor Telegram Anda"
        echo "  3. Buat aplikasi baru"
        echo "  4. Copy API_ID dan API_HASH"
        echo "  5. Paste ke file run.sh baris 28-29"
        exit 1
    fi
else
    print_success "API_ID terdeteksi: $API_ID"
fi
echo ""

# Buat file start script
echo "📝 Membuat start script..."

if [[ "$OS" == "windows" ]]; then
    # Untuk Windows (bat file)
    cat > start.bat << 'EOF'
@echo off
python run.sh
pause
EOF
    print_success "File start.bat dibuat"
else
    # Untuk Linux/Mac (bash script)
    cat > start.sh << 'EOF'
#!/bin/bash
python3 run.sh
EOF
    chmod +x start.sh
    print_success "File start.sh dibuat"
fi
echo ""

# Summary
echo "================================================================"
echo "✅ SETUP SELESAI!"
echo "================================================================"
echo ""
echo "📋 Ringkasan:"
print_success "Python: $PYTHON_VERSION"
print_success "Telethon: Installed"
print_success "Script: Ready"
echo ""
echo "🚀 Cara menjalankan:"
if [[ "$OS" == "windows" ]]; then
    echo "   Double click: start.bat"
    echo "   Atau ketik: python run.sh"
else
    echo "   Ketik: ./start.sh"
    echo "   Atau: python3 run.sh"
fi
echo ""
echo "⚠️  PENTING:"
echo "   • Pastikan API_ID dan API_HASH sudah diisi"
echo "   • Gunakan delay minimal 60 detik"
echo "   • Jangan spam untuk menghindari banned"
echo ""
echo "📖 Dokumentasi:"
echo "   GitHub: https://github.com/oscaroffc"
echo ""
echo "================================================================"
echo ""

read -p "Tekan ENTER untuk keluar..."