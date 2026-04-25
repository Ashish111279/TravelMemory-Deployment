# Travel Memory MERN Stack - Deployment Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture Overview](#architecture-overview)
3. [Prerequisites](#prerequisites)
4. [Local Setup](#local-setup)
5. [AWS EC2 Deployment](#aws-ec2-deployment)
6. [Backend Configuration](#backend-configuration)
7. [Frontend Configuration](#frontend-configuration)
8. [Nginx Reverse Proxy Setup](#nginx-reverse-proxy-setup)
9. [Load Balancer Configuration](#load-balancer-configuration)
10. [Cloudflare DNS Setup](#cloudflare-dns-setup)
11. [Deployment Architecture Diagram](#deployment-architecture-diagram)
12. [Troubleshooting](#troubleshooting)

---

## Project Overview

**Travel Memory** is a full-stack MERN (MongoDB, Express, React, Node.js) application that allows users to:
- Record and manage travel memories
- Store trip details including dates, hotels, places visited, costs, and experiences
- Upload trip images
- Mark trips as featured

**Repository**: https://github.com/UnpredictablePrashant/TravelMemory

---

## Architecture Overview

### Components:
- **Frontend**: React application running on port 3001
- **Backend**: Node.js/Express API running on port 3000
- **Database**: MongoDB Atlas (Cloud)
- **Web Server**: Nginx (reverse proxy & load balancer)
- **Deployment**: AWS EC2 instances
- **DNS**: Cloudflare

### Traffic Flow:
```
User → Cloudflare → AWS Load Balancer → Nginx Reverse Proxy → 
  Frontend (React) & Backend (Node.js) → MongoDB Atlas
```

---

## Prerequisites

### Local Machine:
- Node.js (v14+) and npm
- Git
- MongoDB Atlas account (free tier)
- AWS account with EC2 access
- Cloudflare account
- Custom domain name

### AWS Requirements:
- EC2 instances (minimum 2-4 for scaling)
- Security Groups (ports: 22, 80, 443, 3000, 3001)
- Elastic IP addresses
- Application Load Balancer (ALB)
- SSH key pair

---

## Local Setup

### 1. Clone Repository
\`\`\`bash
git clone https://github.com/UnpredictablePrashant/TravelMemory.git
cd TravelMemory
\`\`\`

### 2. Backend Setup
\`\`\`bash
cd backend
npm install
\`\`\`

Create `.env` file:
\`\`\`
MONGO_URI=mongodb+srv://username:password@cluster0.mongodb.net/travelmemory?retryWrites=true&w=majority
PORT=3000
\`\`\`

Start backend:
\`\`\`bash
npm start
# Or with nodemon for development:
npx nodemon index.js
\`\`\`

### 3. Frontend Setup
\`\`\`bash
cd ../frontend
npm install
\`\`\`

Create `.env` file:
\`\`\`
REACT_APP_BACKEND_URL=http://localhost:3000
\`\`\`

Start frontend:
\`\`\`bash
npm start
# Runs on http://localhost:3000 (React development server)
\`\`\`

### 4. MongoDB Setup
1. Create MongoDB Atlas account: https://www.mongodb.com/cloud/atlas
2. Create a free cluster
3. Create database user with credentials
4. Get connection string and update `.env`

### 5. Test Application
- Frontend: http://localhost:3000
- Backend: http://localhost:3000/hello
- API: http://localhost:3000/trip

---

## AWS EC2 Deployment

### Step 1: Launch EC2 Instances

1. Go to AWS Console → EC2 Dashboard
2. Click "Launch Instances"
3. **Configuration**:
   - **AMI**: Ubuntu Server 22.04 LTS (free tier eligible)
   - **Instance Type**: t2.micro (free tier) or t2.small (for better performance)
   - **Key Pair**: Create or select existing SSH key
   - **Security Group**: Create new with rules:
     - SSH (22): Your IP only
     - HTTP (80): 0.0.0.0/0
     - HTTPS (443): 0.0.0.0/0
     - Port 3000: Internal (load balancer)
     - Port 3001: Internal (load balancer)

4. Launch instances (create at least 2 for both backend and frontend)

### Step 2: Connect to Instance
\`\`\`bash
# Change permissions on key file
chmod 400 your-key.pem

# Connect via SSH
ssh -i your-key.pem ec2-user@<PUBLIC_IP>
# Or for Ubuntu:
ssh -i your-key.pem ubuntu@<PUBLIC_IP>
\`\`\`

### Step 3: Update System
\`\`\`bash
sudo apt update
sudo apt upgrade -y
\`\`\`

---

## Backend Configuration

### On EC2 Backend Instance(s):

#### 1. Install Node.js and npm
\`\`\`bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
node --version
npm --version
\`\`\`

#### 2. Install Git and Clone Repository
\`\`\`bash
sudo apt-get install -y git
cd /home/ubuntu
git clone https://github.com/UnpredictablePrashant/TravelMemory.git
cd TravelMemory/backend
\`\`\`

#### 3. Install Dependencies
\`\`\`bash
npm install
\`\`\`

#### 4. Create .env File
\`\`\`bash
sudo nano .env
\`\`\`

Add the following:
\`\`\`
MONGO_URI=mongodb+srv://username:password@cluster0.mongodb.net/travelmemory?retryWrites=true&w=majority
PORT=3000
\`\`\`

#### 5. Install PM2 (Process Manager)
\`\`\`bash
sudo npm install -g pm2
\`\`\`

#### 6. Start Backend with PM2
\`\`\`bash
pm2 start index.js --name "travel-memory-backend"
pm2 startup
pm2 save
\`\`\`

#### 7. Verify Backend
\`\`\`bash
pm2 status
curl http://localhost:3000/hello
\`\`\`

---

## Frontend Configuration

### On EC2 Frontend Instance(s):

#### 1. Install Node.js and npm (same as backend)
\`\`\`bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
\`\`\`

#### 2. Clone Repository and Install
\`\`\`bash
sudo apt-get install -y git
cd /home/ubuntu
git clone https://github.com/UnpredictablePrashant/TravelMemory.git
cd TravelMemory/frontend
npm install
\`\`\`

#### 3. Create .env File
\`\`\`bash
sudo nano .env
\`\`\`

Add the following:
\`\`\`
REACT_APP_BACKEND_URL=http://api.yourdomain.com
# Or during initial testing:
# REACT_APP_BACKEND_URL=http://<BACKEND_INSTANCE_IP>:3000
\`\`\`

#### 4. Build Frontend
\`\`\`bash
npm run build
\`\`\`

#### 5. Install Nginx
\`\`\`bash
sudo apt-get install -y nginx
\`\`\`

#### 6. Configure Nginx for Frontend
\`\`\`bash
sudo nano /etc/nginx/sites-available/default
\`\`\`

Replace with:
\`\`\`nginx
server {
    listen 3001 default_server;
    listen [::]:3001 default_server;

    root /home/ubuntu/TravelMemory/frontend/build;
    index index.html;

    server_name _;

    location / {
        try_files $uri /index.html;
    }

    location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
\`\`\`

#### 7. Test and Start Nginx
\`\`\`bash
sudo nginx -t
sudo systemctl start nginx
sudo systemctl enable nginx
\`\`\`

---

## Nginx Reverse Proxy Setup

### Main Load Balancer Server Configuration

Create `/etc/nginx/nginx.conf` or `/etc/nginx/sites-available/default`:

\`\`\`nginx
http {
    # Backend upstream servers
    upstream backend {
        server <BACKEND_IP_1>:3000 weight=1;
        server <BACKEND_IP_2>:3000 weight=1;
    }

    # Frontend upstream servers
    upstream frontend {
        server <FRONTEND_IP_1>:3001 weight=1;
        server <FRONTEND_IP_2>:3001 weight=1;
    }

    server {
        listen 80;
        server_name yourdomain.com www.yourdomain.com;

        # Frontend routes
        location / {
            proxy_pass http://frontend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }

    server {
        listen 80;
        server_name api.yourdomain.com;

        # Backend routes
        location / {
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
\`\`\`

---

## Load Balancer Configuration

### Using AWS Application Load Balancer (ALB)

#### 1. Create Target Groups

**Backend Target Group:**
- Protocol: HTTP
- Port: 3000
- Health check path: /hello
- Healthy threshold: 2
- Unhealthy threshold: 2
- Timeout: 5 seconds
- Interval: 30 seconds

**Frontend Target Group:**
- Protocol: HTTP
- Port: 3001
- Health check path: /
- Healthy threshold: 2
- Unhealthy threshold: 2
- Timeout: 5 seconds
- Interval: 30 seconds

#### 2. Create Application Load Balancer

1. Go to EC2 Dashboard → Load Balancers → Create Load Balancer
2. Choose Application Load Balancer
3. **Configuration**:
   - Name: travel-memory-alb
   - Scheme: Internet-facing
   - Subnets: Select all available subnets
4. **Security Groups**: Select created security group
5. **Listeners**:
   - HTTP (port 80) → Route to appropriate target groups
6. **Rules**:
   - Host header = api.yourdomain.com → Backend Target Group
   - Host header = yourdomain.com → Frontend Target Group

#### 3. Register Targets

Add EC2 instances to respective target groups:
- Backend instances → Backend Target Group
- Frontend instances → Frontend Target Group

---

## Cloudflare DNS Setup

### Step 1: Add Domain to Cloudflare

1. Go to https://dash.cloudflare.com
2. Add Site → Enter your domain
3. Select Free plan
4. Update nameservers at domain registrar to Cloudflare's nameservers

### Step 2: Create DNS Records

#### A Record (Frontend - Direct IP):
\`\`\`
Type: A
Name: yourdomain.com
Content: <EC2_FRONTEND_INSTANCE_IP>
TTL: Auto
Proxy status: Proxied (orange cloud)
\`\`\`

#### CNAME Record (API - Load Balancer):
\`\`\`
Type: CNAME
Name: api.yourdomain.com
Content: <ALB_DNS_NAME>
TTL: Auto
Proxy status: Proxied (orange cloud)
\`\`\`

#### WWW Record:
\`\`\`
Type: CNAME
Name: www
Content: yourdomain.com
TTL: Auto
Proxy status: Proxied (orange cloud)
\`\`\`

### Step 3: SSL/TLS Configuration

1. Go to SSL/TLS → Edge Certificates
2. Select "Full" or "Full (strict)" for SSL mode
3. Enable Auto HTTPS Rewrites
4. Create Origin Rule to redirect HTTP to HTTPS

### Step 4: Firewall Rules (Optional)

Enable DDoS protection and rate limiting:
- Security Level: High
- Challenge Passage: 30 minutes
- Rate Limiting: 50 requests per 10 seconds

---

## Deployment Architecture Diagram

```
                        INTERNET
                           |
                    ┌──────┴──────┐
                    |  Cloudflare  |
                    | DNS + DDoS   |
                    └──────┬──────┘
                           |
                    ┌──────┴──────┐
                    |   Route 53   |
                    |  (Optional)  |
                    └──────┬──────┘
                           |
                 ┌─────────┴─────────┐
                 |                   |
        ┌────────┴────────┐  ┌───────┴───────┐
        |    Frontend     |  |    Backend    |
        |   Domain.com    |  | api.domain.com|
        └────────┬────────┘  └───────┬───────┘
                 |                   |
        ┌────────┴────────┐  ┌───────┴───────┐
        |  ALB (Frontend  |  |  ALB (Backend |
        |   Port 80/443)  |  |   Port 80)    |
        └────────┬────────┘  └───────┬───────┘
                 |                   |
      ┌──────────┴──────────┐ ┌──────┴───────────┐
      |                     | |                  |
   Frontend EC2          Backend EC2       Backend EC2
   Instance 1            Instance 1        Instance 2
   (Nginx-3001)          (Node-3000)       (Node-3000)
      |                     |                  |
      |                     ├──────────────────┤
      |                     |                  |
      └─────────────────────┴─────────────────┘
                           |
                    ┌──────┴──────┐
                    | MongoDB     |
                    | Atlas Cloud |
                    └─────────────┘
```

---

## Troubleshooting

### Common Issues and Solutions

#### 1. Backend Connection Error
**Problem**: Frontend can't connect to backend
**Solution**:
```bash
# Check backend status
pm2 status

# Check backend logs
pm2 logs travel-memory-backend

# Verify backend is running on port 3000
netstat -tuln | grep 3000

# Test backend directly
curl http://localhost:3000/hello
```

#### 2. Nginx Not Proxying
**Problem**: Nginx returns 502 Bad Gateway
**Solution**:
```bash
# Check nginx configuration
sudo nginx -t

# Check nginx error logs
sudo tail -f /var/log/nginx/error.log

# Restart nginx
sudo systemctl restart nginx

# Verify upstream servers are reachable
curl http://<BACKEND_IP>:3000
```

#### 3. CORS Issues
**Problem**: Frontend requests blocked by CORS
**Solution**: Backend already has CORS configured in index.js. Verify:
```javascript
const cors = require('cors')
app.use(cors())
```

#### 4. MongoDB Connection Error
**Problem**: "MongoNetworkError"
**Solution**:
```bash
# Verify connection string in .env
cat .env | grep MONGO_URI

# Check if database user has correct permissions in MongoDB Atlas
# Whitelist EC2 security group IP in MongoDB Atlas Network Access
```

#### 5. Cloudflare DNS Not Resolving
**Problem**: Domain not resolving to server
**Solution**:
```bash
# Check DNS propagation
nslookup yourdomain.com
dig yourdomain.com

# Verify Cloudflare nameservers are active (can take 24-48 hours)
# Check in Cloudflare dashboard → Overview → Nameservers
```

#### 6. Load Balancer Health Check Failing
**Problem**: Instances show "unhealthy" in ALB
**Solution**:
- Verify backend/frontend running on correct ports
- Check security group allows traffic on specified ports
- Review health check endpoint (backend: /hello, frontend: /)
- Check logs for connection errors

---

## Monitoring and Maintenance

### Enable CloudWatch Monitoring
```bash
# Set up CloudWatch agent for EC2 instances
sudo wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb
```

### Regular Updates
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update npm packages
cd ~/TravelMemory/backend && npm update
cd ~/TravelMemory/frontend && npm update
```

### Backup Database
- Enable automated MongoDB Atlas backups
- Test backup restore procedures monthly

---

## Performance Optimization

### Caching Strategy
- Frontend static assets: 1 year cache (handled by Nginx)
- API responses: Cache GET /trip requests for 5 minutes
- Database queries: Implement Redis caching (future enhancement)

### Compression
Enable gzip in Nginx:
```nginx
gzip on;
gzip_types text/plain text/css text/javascript application/json;
gzip_min_length 1000;
```

### CDN
- Use Cloudflare's free CDN for static assets
- Enable Rocket Loader for JavaScript optimization

---

## Security Best Practices

1. **SSH Access**: Restrict to specific IPs
2. **Firewall**: Use Security Groups to restrict traffic
3. **HTTPS**: Set up SSL/TLS certificates
4. **Database**: Use strong MongoDB credentials
5. **Environment Variables**: Never commit .env files
6. **Backups**: Automated daily backups for database
7. **Monitoring**: Set up alerts for high CPU/Memory usage

---

## Deployment Checklist

- [ ] MongoDB Atlas cluster created and accessible
- [ ] EC2 instances launched and security groups configured
- [ ] Node.js and npm installed on all instances
- [ ] Repository cloned on all instances
- [ ] .env files configured on all instances
- [ ] Backend PM2 process running
- [ ] Frontend Nginx serving React build
- [ ] Application Load Balancer created and health checks passing
- [ ] Cloudflare DNS records created (A record and CNAME record)
- [ ] Domain resolves correctly
- [ ] Frontend accessible via yourdomain.com
- [ ] API accessible via api.yourdomain.com
- [ ] CORS working properly
- [ ] MongoDB connection verified
- [ ] Load balancing tested with multiple instances
- [ ] Cloudflare DDoS protection enabled

---

## Next Steps

1. Set up SSL certificates using Let's Encrypt
2. Implement Redis caching for performance
3. Set up CI/CD pipeline using GitHub Actions
4. Add monitoring with Datadog or New Relic
5. Implement auto-scaling policies
6. Create disaster recovery plan

---

**Last Updated**: April 25, 2026
**Deployment Stack**: MERN + Nginx + AWS EC2 + Cloudflare
**Status**: Ready for Production Deployment
