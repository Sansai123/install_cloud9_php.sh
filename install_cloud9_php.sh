#!/bin/bash

# Fungsi cetak warna
print_message() {
  local COLOR=$1
  local MESSAGE=$2
  local RESET="\033[0m"
  echo -e "${COLOR}${MESSAGE}${RESET}"
}

GREEN="\033[1;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
RED="\033[1;31m"

print_message "$BLUE" "================================================="
print_message "$GREEN" "🚀 Cloud9 + PHP 8.2 Docker Installation Script 🌟"
print_message "$BLUE" "================================================="

# Deteksi OS
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$ID
else
  print_message "$RED" "❌ Tidak bisa deteksi OS. Exit..."
  exit 1
fi

if [[ "$OS" != "ubuntu" && "$OS" != "debian" ]]; then
  print_message "$RED" "❌ Script hanya support Ubuntu/Debian. Exit..."
  exit 1
fi

print_message "$YELLOW" "⚙️ Update dan upgrade sistem..."
sudo apt update -y && sudo apt upgrade -y
if [ $? -ne 0 ]; then
  print_message "$RED" "❌ Gagal update/upgrade sistem."
  exit 1
fi

# Install dependensi untuk Docker
print_message "$YELLOW" "⚙️ Install paket pendukung Docker..."
sudo apt install -y ca-certificates curl gnupg lsb-release

# Install Docker official repo dan Docker engine
print_message "$YELLOW" "⚙️ Install Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

if [ $? -ne 0 ]; then
  print_message "$RED" "❌ Gagal install Docker."
  exit 1
fi

print_message "$YELLOW" "⚙️ Enable dan start Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

sleep 5
sudo systemctl status docker --no-pager | grep "Active: active (running)"
if [ $? -ne 0 ]; then
  print_message "$RED" "❌ Docker service tidak berjalan."
  exit 1
fi

# Buat Dockerfile Cloud9 + PHP 8.2
print_message "$YELLOW" "⚙️ Membuat Dockerfile Cloud9 + PHP 8.2..."

cat > Dockerfile <<'EOF'
FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    git curl wget unzip build-essential libzip-dev zip nodejs npm && \
    docker-php-ext-install zip pdo_mysql mysqli && \
    a2enmod rewrite

# Install Node.js (versi terbaru LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && apt-get install -y nodejs

# Install Cloud9 SDK dari GitHub
RUN git clone https://github.com/c9/core.git /cloud9 && \
    cd /cloud9 && \
    scripts/install-sdk.sh

WORKDIR /cloud9

EXPOSE 8181

CMD ["node", "/cloud9/server.js", "-w", "/workspace", "-l", "0.0.0.0", "-p", "8181", "--auth", "san:sai"]
EOF

print_message "$YELLOW" "⚙️ Build Docker image cloud9-php8.2..."
sudo docker build -t cloud9-php8.2 .

if [ $? -ne 0 ]; then
  print_message "$RED" "❌ Gagal build Docker image."
  exit 1
fi

print_message "$YELLOW" "⚙️ Jalankan container Cloud9..."
sudo docker run -d -p 8181:8181 --name cloud9-php8.2 -v "$PWD/workspace":/workspace cloud9-php8.2

if [ $? -ne 0 ]; then
  print_message "$RED" "❌ Gagal jalankan container."
  exit 1
fi

PUBLIC_IP=$(curl -s ifconfig.me || echo "localhost")

print_message "$BLUE" "==========================================="
print_message "$GREEN" "🎉 Cloud9 + PHP 8.2 berhasil diinstall! 🎉"
print_message "$BLUE" "==========================================="
print_message "$YELLOW" "🌐 Akses Cloud9 di: http://$PUBLIC_IP:8181"
print_message "$YELLOW" "🔑 Username: san"
print_message "$YELLOW" "🔑 Password: sai"
print_message "$YELLOW" "📂 Folder workspace ter-mount di: $(pwd)/workspace"
print_message "$YELLOW" "==========================================="