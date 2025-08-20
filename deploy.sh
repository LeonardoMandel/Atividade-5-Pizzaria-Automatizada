#!/bin/bash

# --- VARIABLES ---
REPO_URL="https://github.com/LeonardoMandel/proway-docker.git"
BRANCH="main"
APP_DIR="pizzaria-app"
PROJECT_DIR="/opt/pizzaria"
CRON_USER=$(whoami)

# --- FUNCTIONS ---
# Function to get the host's IP address dynamically
get_host_ip() {
    HOST_IP=$(hostname -I | awk '{print $1}')
    if [ -z "$HOST_IP" ]; then
        echo "Error: Could not determine host IP address."
        exit 1
    fi
    echo "Host IP detected: $HOST_IP"
    export HOST_IP
}

# Function to check and install dependencies
install_dependencies() {
    echo "Checking and installing dependencies..."
    if ! command -v docker &> /dev/null; then
        echo "Docker not found. Installing now..."
        sudo apt-get update
        sudo apt-get install -y docker.io
        sudo systemctl start docker
        sudo systemctl enable docker
    fi
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose not found. Installing now..."
        sudo apt-get install -y docker-compose
    fi
}

# Function to clone or update the repository
update_repository() {
    echo "Updating the repository..."
    if [ ! -d "$PROJECT_DIR" ]; then
        echo "Cloning repository to $PROJECT_DIR..."
        git clone -b "$BRANCH" "$REPO_URL" "$PROJECT_DIR"
    else
        echo "Repository already exists. Pulling latest changes..."
        cd "$PROJECT_DIR" || exit
        git pull origin "$BRANCH"
    fi
}

# Function to replace localhost with host IP using sed
replace_localhost() {
    echo "Replacing 'localhost' with '$HOST_IP' in frontend files..."
    FRONTEND_PUBLIC_DIR="$PROJECT_DIR/$APP_DIR/frontend/public"
    FRONTEND_SRC_DIR="$PROJECT_DIR/$APP_DIR/frontend/src"
    
    if [ -f "$FRONTEND_PUBLIC_DIR/index.html" ] && [ -f "$FRONTEND_SRC_DIR/boot/axios.js" ]; then
        sed -i "s/localhost/$HOST_IP/g" "$FRONTEND_PUBLIC_DIR/index.html"
        sed -i "s/localhost/$HOST_IP/g" "$FRONTEND_SRC_DIR/boot/axios.js"
        echo "Replacement successful."
    else
        echo "Warning: Required frontend files not found. Skipping replacement."
    fi
}

# Function to redeploy the application
redeploy_application() {
    echo "Rebuilding and redeploying the application..."
    cd "$PROJECT_DIR/$APP_DIR" || exit
    sudo docker-compose up --build -d
}

# Function to add the script to crontab
add_to_crontab() {
    echo "Adding the deploy script to crontab..."
    CRON_JOB="*/5 * * * * $CRON_USER /bin/bash $0 >> /var/log/pizzaria_deploy.log 2>&1"
    if ! sudo crontab -l | grep -q "$CRON_JOB"; then
        (sudo crontab -l 2>/dev/null; echo "$CRON_JOB") | sudo crontab -
        echo "Cron job added successfully."
    else
        echo "Cron job already exists. No changes made."
    fi
}

# --- MAIN EXECUTION ---
echo "--- Starting Pizzaria Deployment Script ---"
get_host_ip
install_dependencies
update_repository
replace_localhost

# This is the corrected logic: always deploy on first run, then check for updates.
if [ ! -f "$PROJECT_DIR/.first_run" ]; then
    echo "First run detected. Deploying application..."
    redeploy_application
    touch "$PROJECT_DIR/.first_run" # Create a flag file
else
    echo "Checking for new changes..."
    cd "$PROJECT_DIR/$APP_DIR" || exit
    LOCAL_HASH=$(git rev-parse HEAD)
    REMOTE_HASH=$(git rev-parse @{u})

    if [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
        redeploy_application
    else
        echo "No changes detected. Application is up to date."
    fi
fi

add_to_crontab
echo "--- Deployment finished. ---"
