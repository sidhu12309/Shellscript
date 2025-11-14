#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# ---------------------------------------------
# COLORS
# ---------------------------------------------
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# ---------------------------------------------
# FUNCTIONS
# ---------------------------------------------
print_step() {
  echo -e "\n${BLUE}▶ $1${RESET}"
}

print_success() {
  echo -e "${GREEN}✅ $1${RESET}"
}

print_error() {
  echo -e "${RED}❌ $1${RESET}"
}

# ---------------------------------------------
# 1️⃣ CHECK ROOT
# ---------------------------------------------
if [ "$EUID" -ne 0 ]; then
  print_error "Please run as root or use sudo."
  exit 1
fi

# ---------------------------------------------
# 2️⃣ UPDATE SYSTEM
# ---------------------------------------------
print_step "Updating system packages..."
apt-get update -y && apt-get upgrade -y
print_success "System update completed."

# ---------------------------------------------
# 3️⃣ INSTALL JAVA 21
# ---------------------------------------------
print_step "Installing Java 21..."
apt-get install -y openjdk-21-jdk
java -version
print_success "Java 21 installed successfully."

# ---------------------------------------------
# 4️⃣ INSTALL DOCKER
# ---------------------------------------------
print_step "Installing Docker..."

# Remove old versions (if any)
apt-get remove -y docker docker-engine docker.io containerd runc || true

# Required packages
apt-get install -y ca-certificates curl gnupg lsb-release

# Setup keyrings
install -m 0755 -d /etc/apt/keyrings
rm -f /etc/apt/keyrings/docker.gpg

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  gpg --dearmor -o /etc/apt/keyrings/docker.gpg

chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository (Ubuntu 24.04: noble)
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu noble stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker packages
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
systemctl enable docker
systemctl start docker
docker --version
print_success "Docker installed and running."

# ---------------------------------------------
# 5️⃣ INSTALL DOCKER COMPOSE (if not present)
# ---------------------------------------------
print_step "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
  curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi
docker-compose --version
print_success "Docker Compose installed successfully."

# ---------------------------------------------
# 6️⃣ RUN SONARQUBE CONTAINER
# ---------------------------------------------
print_step "Deploying SonarQube container..."

# Create a SonarQube Docker Compose file
mkdir -p /opt/sonarqube
cat > /opt/sonarqube/docker-compose.yml <<'EOF'
version: "3.9"
services:
  sonarqube:
    image: sonarqube:community
    container_name: sonarqube
    ports:
      - "9000:9000"
    environment:
      - SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs
    restart: always

volumes:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
EOF

# Run container
cd /opt/sonarqube
docker-compose up -d

# Verify container is running
if docker ps | grep -q "sonarqube"; then
  print_success "SonarQube is running successfully on port 9000 🎉"
  echo -e "${YELLOW}Access it at: http://<your-server-ip>:9000${RESET}"
else
  print_error "SonarQube failed to start. Check logs using: docker logs sonarqube"
  exit 1
fi

# ---------------------------------------------
# 7️⃣ DONE
# ---------------------------------------------
print_success "Installation completed successfully!"
echo -e "${GREEN}✅ SonarQube setup finished.${RESET}"
