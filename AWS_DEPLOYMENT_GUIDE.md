# AWS EC2 Deployment Setup Guide

## AWS Infrastructure Setup for Travel Memory

This guide provides step-by-step instructions for setting up the complete AWS infrastructure for deploying Travel Memory MERN application.

---

## Prerequisites

- AWS Account with EC2 access
- Credit/Debit card for payment
- SSH key pair downloaded
- Custom domain name (for Cloudflare setup)

---

## Step 1: Create EC2 Instances

### Launch Backend Instance(s)

1. **Log in to AWS Console**: https://aws.amazon.com/console/
2. **Navigate to EC2**: Go to EC2 Dashboard
3. **Click "Launch Instances"**
4. **Configure Instance**:
   - **Name**: travel-memory-backend-1
   - **AMI**: Ubuntu Server 22.04 LTS (free tier eligible)
   - **Instance Type**: t2.micro (free tier) or t2.small
   - **Key Pair**: Create new or select existing
   - **Network Settings**:
     - VPC: Default VPC
     - Subnet: Default subnet
     - Auto-assign public IP: Enable
   - **Security Group**: Create new
     - Name: travel-memory-sg
     - Inbound Rules:
       ```
       SSH (22): 0.0.0.0/0 (Restrict to your IP in production)
       HTTP (80): 0.0.0.0/0
       HTTPS (443): 0.0.0.0/0
       Port 3000: 0.0.0.0/0 (For testing; restrict in production)
       Port 3001: 0.0.0.0/0 (For testing; restrict in production)
       ```
   - **Storage**: 20 GB (default is fine)
5. **Launch Instance**
6. **Wait for instance to start** (Status: running)
7. **Note the Public IP address**

### Launch Frontend Instance(s)

Repeat the above process with:
- **Name**: travel-memory-frontend-1
- Use the same security group (travel-memory-sg)

### Launch Additional Instances (for scaling)

Create 1-2 additional instances for load balancing:
- Backend Instance 2 (optional)
- Frontend Instance 2 (optional)

---

## Step 2: Connect to EC2 Instance via SSH

### On Windows (using PowerShell):

```powershell
# Set key permissions (if new)
$path = "C:\path\to\your-key.pem"
icacls $path /inheritance:r

# Connect to instance
ssh -i "C:\path\to\your-key.pem" ubuntu@<PUBLIC_IP>
```

### On Mac/Linux:

```bash
# Set key permissions
chmod 400 ~/path/to/your-key.pem

# Connect to instance
ssh -i ~/path/to/your-key.pem ubuntu@<PUBLIC_IP>
```

---

## Step 3: Deploy Backend to EC2

### Option A: Manual Deployment

```bash
# Connect to backend instance
ssh -i your-key.pem ubuntu@<BACKEND_IP>

# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Git
sudo apt-get install -y git

# Clone repository
cd /home/ubuntu
git clone https://github.com/UnpredictablePrashant/TravelMemory.git
cd TravelMemory/backend

# Install dependencies
npm install

# Create .env file
sudo nano .env
# Add:
# MONGO_URI=mongodb+srv://username:password@cluster0.mongodb.net/travelmemory?retryWrites=true&w=majority
# PORT=3000

# Install PM2
sudo npm install -g pm2

# Start backend
pm2 start index.js --name "travel-memory-backend"
pm2 startup
pm2 save

# Verify
curl http://localhost:3000/hello
```

### Option B: Automated Deployment

```bash
# Connect to backend instance
ssh -i your-key.pem ubuntu@<BACKEND_IP>

# Download and run deployment script
cd ~
wget https://raw.githubusercontent.com/UnpredictablePrashant/TravelMemory/main/deploy-backend.sh
chmod +x deploy-backend.sh
./deploy-backend.sh

# Update .env file with MongoDB credentials
sudo nano /home/ubuntu/TravelMemory/backend/.env
```

---

## Step 4: Deploy Frontend to EC2

### Option A: Manual Deployment

```bash
# Connect to frontend instance
ssh -i your-key.pem ubuntu@<FRONTEND_IP>

# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Git
sudo apt-get install -y git

# Clone repository
cd /home/ubuntu
git clone https://github.com/UnpredictablePrashant/TravelMemory.git
cd TravelMemory/frontend

# Install dependencies
npm install

# Create .env file
sudo nano .env
# Add:
# REACT_APP_BACKEND_URL=http://<BACKEND_IP>:3000

# Build React app
npm run build

# Install Nginx
sudo apt-get install -y nginx

# Configure Nginx
sudo tee /etc/nginx/sites-available/default > /dev/null << 'NGINX_CONFIG'
server {
    listen 3001 default_server;
    listen [::]:3001 default_server;

    root /home/ubuntu/TravelMemory/frontend/build;
    index index.html;

    server_name _;

    location / {
        try_files $uri /index.html;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
NGINX_CONFIG

# Test Nginx
sudo nginx -t

# Start Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Verify
curl http://localhost:3001
```

### Option B: Automated Deployment

```bash
# Connect to frontend instance
ssh -i your-key.pem ubuntu@<FRONTEND_IP>

# Download and run deployment script
cd ~
wget https://raw.githubusercontent.com/UnpredictablePrashant/TravelMemory/main/deploy-frontend.sh
chmod +x deploy-frontend.sh
./deploy-frontend.sh

# Update .env file with backend URL
sudo nano /home/ubuntu/TravelMemory/frontend/.env
```

---

## Step 5: Create Application Load Balancer (ALB)

### Create Target Groups

#### Backend Target Group:
1. Go to EC2 Dashboard → Target Groups
2. Click "Create target group"
3. **Configuration**:
   - Name: travel-memory-backend-tg
   - Protocol: HTTP
   - Port: 3000
   - VPC: Default VPC
4. **Health Checks**:
   - Protocol: HTTP
   - Path: /hello
   - Port: 3000
   - Healthy threshold: 2
   - Unhealthy threshold: 2
   - Timeout: 5 seconds
   - Interval: 30 seconds
5. Click "Create target group"
6. **Register targets**: Add backend EC2 instance(s)

#### Frontend Target Group:
Repeat above with:
- Name: travel-memory-frontend-tg
- Port: 3001
- Health check path: /

### Create Application Load Balancer

1. Go to EC2 Dashboard → Load Balancers
2. Click "Create load balancer"
3. Choose "Application Load Balancer"
4. **Configuration**:
   - Name: travel-memory-alb
   - Scheme: Internet-facing
   - IP address type: IPv4
5. **Network mapping**:
   - VPC: Default VPC
   - Subnets: Select all available subnets (at least 2)
6. **Security groups**: Select travel-memory-sg
7. **Listeners**:
   - HTTP (port 80) → Add forward rule:
     - Host header = api.yourdomain.com → Backend Target Group
     - Host header = yourdomain.com → Frontend Target Group
8. Review and create

**Note the ALB DNS name** for Cloudflare CNAME setup.

---

## Step 6: Allocate Elastic IP (Optional but Recommended)

Elastic IP ensures your instance IP doesn't change on restart:

1. Go to EC2 Dashboard → Elastic IPs
2. Click "Allocate Elastic IP address"
3. Select VPC: Default VPC
4. Allocate
5. **Associate Elastic IP**:
   - Instance: Select your backend/frontend instance
   - Network interface: Select eth0
   - Associate

---

## Step 7: Security Group Configuration

### Edit Security Group Rules

1. Go to EC2 Dashboard → Security Groups
2. Select travel-memory-sg
3. Click "Edit inbound rules"
4. Add/modify rules:

| Type | Protocol | Port | Source | Purpose |
|------|----------|------|--------|---------|
| SSH | TCP | 22 | Your IP (or 0.0.0.0/0) | Admin access |
| HTTP | TCP | 80 | 0.0.0.0/0 | Web traffic |
| HTTPS | TCP | 443 | 0.0.0.0/0 | Secure web traffic |
| Custom TCP | TCP | 3000 | 0.0.0.0/0 | Backend development |
| Custom TCP | TCP | 3001 | 0.0.0.0/0 | Frontend development |

---

## Step 8: Configure Cloudflare DNS

### Add Domain to Cloudflare

1. Go to https://dash.cloudflare.com
2. Click "Add a Site"
3. Enter your domain name
4. Select Free plan
5. Update nameservers at your domain registrar to:
   - ns1.cloudflare.com
   - ns2.cloudflare.com
   - (Cloudflare will provide 2 nameservers)

### Create DNS Records

#### A Record (Frontend - Direct EC2 IP):
- Type: A
- Name: yourdomain.com
- Content: <FRONTEND_ELASTIC_IP>
- TTL: Auto
- Proxy status: Proxied (orange cloud)

#### CNAME Record (API - ALB):
- Type: CNAME
- Name: api.yourdomain.com
- Content: <ALB_DNS_NAME>
- TTL: Auto
- Proxy status: Proxied (orange cloud)

#### WWW Record:
- Type: CNAME
- Name: www
- Content: yourdomain.com
- TTL: Auto
- Proxy status: Proxied (orange cloud)

### SSL/TLS Configuration in Cloudflare

1. Go to SSL/TLS → Edge Certificates
2. Encryption mode: Full (strict)
3. Enable "Automatic HTTPS Rewrites"
4. Enable "Always Use HTTPS"

---

## Step 9: Update Frontend .env for Production

```bash
# SSH into frontend instance
ssh -i your-key.pem ubuntu@<FRONTEND_IP>

# Update .env
sudo nano /home/ubuntu/TravelMemory/frontend/.env

# Change to:
REACT_APP_BACKEND_URL=http://api.yourdomain.com

# Rebuild frontend
cd /home/ubuntu/TravelMemory/frontend
npm run build

# Restart Nginx
sudo systemctl restart nginx
```

---

## Step 10: Testing and Verification

### Test Backend
```bash
# From local machine
curl http://api.yourdomain.com/hello

# Should return: "Hello World!"
```

### Test Frontend
```bash
# Open browser
http://yourdomain.com

# Should load Travel Memory application
```

### Test API Communication
```bash
# Create a new trip via API
curl -X POST http://api.yourdomain.com/trip \
  -H "Content-Type: application/json" \
  -d '{
    "tripName": "Test Trip",
    "startDateOfJourney": "01-01-2024",
    "endDateOfJourney": "05-01-2024",
    "nameOfHotels": "Test Hotel",
    "placesVisited": "Place 1, Place 2",
    "totalCost": 10000,
    "tripType": "leisure",
    "experience": "Great trip!",
    "image": "https://example.com/image.jpg",
    "shortDescription": "A wonderful trip",
    "featured": true
  }'
```

---

## Monitoring and Maintenance

### View Application Logs

```bash
# SSH into instance
ssh -i your-key.pem ubuntu@<INSTANCE_IP>

# Backend logs
pm2 logs travel-memory-backend

# Frontend/Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Update Application Code

```bash
# SSH into instance
ssh -i your-key.pem ubuntu@<INSTANCE_IP>

# Update backend
cd /home/ubuntu/TravelMemory/backend
git pull origin main
npm install
pm2 restart travel-memory-backend

# Update frontend
cd /home/ubuntu/TravelMemory/frontend
git pull origin main
npm install
npm run build
sudo systemctl restart nginx
```

### Monitor Instance Performance

1. Go to EC2 Dashboard → Instances
2. Select instance
3. Go to "Monitoring" tab to see:
   - CPU Utilization
   - Network In/Out
   - Instance Status

---

## Cost Optimization

1. **Use Free Tier**: t2.micro instances qualify for free tier
2. **Stop unused instances**: Stop instances not in use
3. **Use Reserved Instances**: Plan for long-term cost savings
4. **Monitor data transfer**: Data transfer costs vary by region
5. **Use Cloudflare Free**: Reduces bandwidth from AWS

**Estimated Monthly Cost** (us-east-1 region):
- 2x t2.micro instances: $0 (free tier)
- ALB: ~$16 + data processing
- Data transfer: ~$0.50-5 depending on traffic
- **Total**: $16-25 for free tier; $50-100+ for scaled setup

---

## Troubleshooting Common Issues

### Instance won't start
- Check account billing is active
- Verify instance type is available in region
- Check account limits (default: 20 instances)

### Can't connect via SSH
- Verify security group allows port 22
- Check key pair is correct
- Verify instance has public IP
- Check SSH key permissions (chmod 400)

### Backend not accessible
- Verify PM2 is running: `pm2 status`
- Check backend logs: `pm2 logs`
- Verify security group allows port 3000
- Test locally: `curl http://localhost:3000/hello`

### Frontend not loading
- Verify Nginx is running: `sudo systemctl status nginx`
- Check Nginx logs: `sudo tail -f /var/log/nginx/error.log`
- Verify React build exists: `ls /home/ubuntu/TravelMemory/frontend/build`
- Verify .env has correct backend URL

### MongoDB Connection Error
- Verify connection string in .env
- Check MongoDB Atlas firewall allows EC2 IP
- Verify database user credentials
- Test connection: `telnet cluster0.mongodb.net 27017`

---

## Next Steps

1. Set up automatic backups for database
2. Implement auto-scaling policies
3. Configure CloudWatch alarms for monitoring
4. Set up CI/CD pipeline with GitHub Actions
5. Implement SSL certificates with Let's Encrypt
6. Add caching layer with Redis
7. Set up disaster recovery procedures

---

**Last Updated**: April 25, 2026
**Status**: Ready for Deployment
