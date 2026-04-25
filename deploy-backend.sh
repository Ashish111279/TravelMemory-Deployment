#!/bin/bash

# Travel Memory - Backend Deployment Script for EC2
# This script automates backend deployment on Ubuntu EC2 instance

set -e

echo "=========================================="
echo "Travel Memory - Backend Deployment Script"
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

# Navigate to backend
cd TravelMemory/backend

# Install dependencies
echo "Step 5: Installing backend dependencies..."
npm install

# Create .env file (update with your values)
echo "Step 6: Creating .env file..."
cat > .env << 'EOF'
MONGO_URI=mongodb+srv://username:password@cluster0.mongodb.net/travelmemory?retryWrites=true&w=majority
PORT=3000
EOF

echo "⚠️  IMPORTANT: Update .env file with your MongoDB credentials:"
echo "   sudo nano /home/ubuntu/TravelMemory/backend/.env"

# Install PM2 globally
echo "Step 7: Installing PM2..."
sudo npm install -g pm2

# Start backend with PM2
echo "Step 8: Starting backend with PM2..."
pm2 start index.js --name "travel-memory-backend"
pm2 startup
pm2 save

# Verify
echo ""
echo "=========================================="
echo "Backend Deployment Complete!"
echo "=========================================="
pm2 status
echo ""
echo "Verify backend is running:"
echo "curl http://localhost:3000/hello"
