#!/bin/bash

# --- VARIABLES ---
REPO_URL="https://github.com/LeonardoMandel/proway-docker.git"
APP_DIR="pizzaria-app"
PROJECT_DIR="/opt/pizzaria"
CRON_USER=$(whoami)

# --- FUNCTIONS ---
# Get the host's IP address
get_host_ip() {
    HOST_IP=$(hostname -I | awk '{print $1}')
    export HOST_IP
}

# Install dependencies
install_dependencies() {
    sudo apt-get update
    sudo apt-get install -y docker.io docker-compose git
    sudo systemctl start docker
    sudo systemctl enable docker
}

# Clone or update the repository
update_repository() {
    if [ ! -d "$PROJECT_DIR" ]; then
        git clone "$REPO_URL" "$PROJECT_DIR"
    else
        cd "$PROJECT_DIR" || exit
        git pull origin main
    fi
}

# Replace 'localhost' with the host IP
replace_localhost() {
    FRONTEND_PUBLIC_DIR="$PROJECT_DIR/$APP_DIR/frontend/public"
    FRONTEND_SRC_DIR="$PROJECT_DIR/$APP_DIR/frontend/src"
    
    sed -i "s/localhost/$HOST_IP/g" "$FRONTEND_PUBLIC_DIR/index.html"
    sed -i "s/localhost/$HOST_IP/g" "$FRONTEND_SRC_DIR/boot/axios.js"
}

# Deploy the application
deploy_application() {
    cd "$PROJECT_DIR/$APP_DIR" || exit
    sudo docker-compose up --build -d
}

# Add the script to crontab
add_to_crontab() {
    CRON_JOB="*/5 * * * * $CRON_USER /bin/bash $0 >> /var/log/pizzaria_deploy.log 2>&1"
    if ! sudo crontab -l | grep -q "$CRON_JOB"; then
        (sudo crontab -l 2>/dev/null; echo "$CRON_JOB") | sudo crontab -
    fi
}

# --- MAIN EXECUTION ---
get_host_ip
install_dependencies
update_repository
replace_localhost
deploy_application
add_to_crontab
