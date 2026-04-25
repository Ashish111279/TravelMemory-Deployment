#!/bin/bash

# Travel Memory - Frontend Deployment Script for EC2
# This script automates frontend deployment on Ubuntu EC2 instance

set -e

echo "=========================================="
echo "Travel Memory - Frontend Deployment Script"
echo "=========================================="

# Update system
echo "Step 1: Updating system packages..."
sudo apt update
sudo apt upgrade -y

# Install Node.js
echo "Step 2: Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Git
echo "Step 3: Installing Git..."
sudo apt-get install -y git

# Clone repository
echo "Step 4: Cloning repository..."
cd /home/ubuntu
git clone https://github.com/UnpredictablePrashant/TravelMemory.git

# Navigate to frontend
cd TravelMemory/frontend

# Install dependencies
echo "Step 5: Installing frontend dependencies..."
npm install

# Create .env file (update with your backend URL)
echo "Step 6: Creating .env file..."
cat > .env << 'EOF'
REACT_APP_BACKEND_URL=http://api.yourdomain.com
EOF

echo "⚠️  IMPORTANT: Update .env file with your backend URL:"
echo "   sudo nano /home/ubuntu/TravelMemory/frontend/.env"

# Build React application
echo "Step 7: Building React application..."
npm run build

# Install Nginx
echo "Step 8: Installing Nginx..."
sudo apt-get install -y nginx

# Configure Nginx
echo "Step 9: Configuring Nginx..."
sudo tee /etc/nginx/sites-available/default > /dev/null << 'EOF'
server {
    listen 3001 default_server;
    listen [::]:3001 default_server;

    root /home/ubuntu/TravelMemory/frontend/build;
    index index.html;

    server_name _;

    location / {
        try_files $uri /index.html;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Test Nginx configuration
echo "Step 10: Testing Nginx configuration..."
sudo nginx -t

# Start Nginx
echo "Step 11: Starting Nginx..."
sudo systemctl start nginx
sudo systemctl enable nginx

# Verify
echo ""
echo "=========================================="
echo "Frontend Deployment Complete!"
echo "=========================================="
echo ""
echo "Verify frontend is running on port 3001:"
echo "curl http://localhost:3001"
echo ""
echo "Frontend URL: http://<EC2_IP>:3001"
