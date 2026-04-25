# Travel Memory - Deployment Architecture

## Architecture Overview

This document describes the deployment architecture for the Travel Memory MERN application on AWS.

---

## System Architecture Diagram (ASCII)

```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                              INTERNET / USERS                                 ║
╚═══════════════════════════════════════════════════════════════════════════════╝
                                       │
                ┌──────────────────────┴──────────────────────┐
                │                                             │
         ┌──────▼─────────┐                          ┌────────▼────────┐
         │   Cloudflare   │                          │   Cloudflare    │
         │   DDoS Guard   │                          │   CDN Cache     │
         │   SSL/TLS      │                          │   Optimization  │
         └──────┬─────────┘                          └────────┬────────┘
                │                                             │
                ├─────────────────────────┬───────────────────┤
                │                         │                   │
         ┌──────▼──────────┐      ┌──────▼────────┐     ┌────▼──────────┐
         │  A Record       │      │  CNAME Record │     │  CNAME Record │
         │  yourdomain.com │      │  api.domain   │     │  www.domain   │
         └──────┬──────────┘      └──────┬────────┘     └────┬──────────┘
                │                        │                   │
         ┌──────▼──────────┐      ┌──────▼────────┐     ┌────▼──────────┐
         │  Frontend EC2   │      │  AWS ALB      │     │  Aliases      │
         │  Elastic IP     │      │  (Backend)    │     │  to Frontend  │
         └──────┬──────────┘      └──────┬────────┘     └───────────────┘
                │                        │
         ┌──────▼──────────┐      ┌──────▼─────────────────────┐
         │  Nginx Server   │      │  Target Group             │
         │  (Port 3001)    │      │  - Backend-1 (Port 3000) │
         │                 │      │  - Backend-2 (Port 3000) │
         │  React Build    │      │  - Backend-N (Port 3000) │
         │  Static Files   │      └──────┬────────────────────┘
         └──────┬──────────┘             │
                │                   ┌────┴──────┬─────────┐
                │                   │           │         │
         ┌──────▼──────────┐  ┌─────▼──┐  ┌────▼──┐  ┌───▼─────┐
         │ Backend API     │  │Backend │  │Backend│  │Backend  │
         │ Communication  │  │Node.js │  │Node.js│  │Node.js  │
         └─────────────────┘  │EC2 #1  │  │EC2 #2│  │EC2 #N   │
                              │PM2     │  │PM2   │  │PM2      │
                              │Process │  │Proc. │  │Process  │
                              └─────┬──┘  └──┬───┘  └───┬─────┘
                                    │       │          │
                              ┌─────┴───────┴──────────┴─┐
                              │                         │
                         ┌────▼────────────────────┐    │
                         │   MongoDB Atlas        │    │
                         │   (Cloud Database)     │    │
                         │                        │    │
                         │  Collections:          │    │
                         │  - trips               │    │
                         │  - users (future)      │    │
                         │                        │    │
                         └────────────────────────┘    │
                                                       │
                         (All backend instances connect)
```

---

## Detailed Architecture Components

### 1. Internet & Users
- Users access the application from their browsers
- Global audience accessing from different regions

### 2. Cloudflare Layer
**Functions:**
- DNS resolution (yourdomain.com → EC2 IP)
- DDoS protection and attack mitigation
- SSL/TLS certificate management
- CDN caching for static assets
- Web Application Firewall (WAF)
- Rate limiting and bot management

**Benefits:**
- Free tier available
- Distributed globally for fast response
- Automatic SSL certificate provisioning
- Bandwidth savings through caching

### 3. DNS Records (Cloudflare)
- **A Record**: Direct connection to frontend EC2 instance
- **CNAME Record (api)**: Points to Application Load Balancer (ALB)
- **CNAME Record (www)**: Points to main domain for alias

### 4. AWS Infrastructure

#### Frontend Layer
- **Elastic IP**: Static public IP for EC2 instance
- **EC2 Instance(s)**: Ubuntu servers running Nginx
- **Nginx Server**: Reverse proxy and web server (port 3001)
- **React Build**: Pre-compiled frontend assets
- **Static Files**: CSS, JavaScript, images

**Features:**
- Serves pre-built React application
- Handles routing with try_files directive
- Caches static assets with long TTL
- Minimal resource requirements

#### Backend Layer
- **Application Load Balancer (ALB)**: Distributes traffic across backend instances
- **Target Group**: Health checks and instance management
- **EC2 Instances**: Multiple instances for high availability
- **Node.js/Express**: Application server running on port 3000
- **PM2**: Process manager for reliability and auto-restart
- **Health Checks**: Continuous validation of instance health

**Features:**
- Auto-scaling capability
- Load balancing across instances
- High availability and fault tolerance
- Automatic instance restart on failure

#### Database Layer
- **MongoDB Atlas**: Cloud-hosted MongoDB database
- **Collections**:
  - `trips`: Stores travel memory records
  - `users`: Future user management
- **Replication**: Built-in replica sets for reliability
- **Backups**: Automatic backup strategy available

---

## Data Flow

### 1. Initial Page Load
```
User Browser
    ↓
Cloudflare DNS (yourdomain.com)
    ↓
Route to Frontend EC2 (A record)
    ↓
Nginx Server (port 3001)
    ↓
React Application (index.html + assets)
    ↓
Rendered in Browser
```

### 2. API Request from Frontend
```
React Component (useState/useEffect)
    ↓
Fetch Request to api.yourdomain.com
    ↓
Cloudflare DNS (CNAME record)
    ↓
Application Load Balancer
    ↓
Route to Backend EC2 Instance (port 3000)
    ↓
Express.js API Handler
    ↓
MongoDB Query/Update
    ↓
Response JSON
    ↓
Display in React Component
```

### 3. Example: Get All Trips
```
Frontend: GET http://api.yourdomain.com/trip
    ↓
ALB selects healthy backend instance (round-robin)
    ↓
Backend: Express route handler
    ↓
Query: db.trips.find({})
    ↓
MongoDB returns array of trips
    ↓
Express formats JSON response
    ↓
CORS headers attached
    ↓
Response sent to Frontend
    ↓
React renders trip list
```

---

## Deployment Scenarios

### Scenario 1: Single Instance Deployment (Testing)
```
User
    ↓
Cloudflare
    ↓
Single EC2 Instance
    ├── Frontend (Nginx, port 3001)
    ├── Backend (Node.js, port 3000)
    └── MongoDB Atlas (separate)
```

**Pros:** Simplicity, cost-effective
**Cons:** Single point of failure, limited scalability

### Scenario 2: Multi-Instance with Load Balancing (Production)
```
Users
    ↓
Cloudflare
    ├── Frontend DNS → EC2-Frontend-1
    └── Backend DNS → ALB → [EC2-Backend-1, EC2-Backend-2, EC2-Backend-3]
         ↓
    MongoDB Atlas (shared database)
```

**Pros:** High availability, scalability, load distribution
**Cons:** More complex, higher costs

### Scenario 3: Geographically Distributed (Advanced)
```
Users in Different Regions
    ↓
Cloudflare Global Network
    ├── US Users → ALB us-east-1
    ├── EU Users → ALB eu-west-1
    └── AP Users → ALB ap-southeast-1
         ↓
    MongoDB Atlas (global replica sets)
```

**Pros:** Low latency worldwide, disaster recovery
**Cons:** Complex setup, expensive

---

## Security Layers

### 1. Cloudflare Security
- DDoS mitigation
- WAF (Web Application Firewall)
- Rate limiting
- Bot management
- SSL/TLS encryption

### 2. AWS Security Groups
- SSH access restricted to admin IPs only
- HTTP/HTTPS ports open to Cloudflare IPs only
- Internal ports (3000, 3001) restricted to ALB

### 3. Application Security
- CORS headers configured
- Input validation in backend
- MongoDB connection string in environment variables
- API rate limiting (future)

### 4. Database Security
- MongoDB Atlas firewall (IP whitelist)
- Database user credentials
- Encryption in transit (TLS)
- Encryption at rest (optional)

---

## Scaling Strategy

### Horizontal Scaling (Add more instances)

1. **Frontend Scaling**:
   - Create additional EC2 instances
   - Run same Nginx configuration
   - Update DNS A records (or use Route 53)
   - Load balance with Application Load Balancer

2. **Backend Scaling**:
   - Create additional EC2 instances
   - Deploy same Node.js application
   - Register with ALB target group
   - ALB automatically distributes traffic

3. **Database Scaling**:
   - MongoDB Atlas automatic replica sets
   - Sharding available on paid tier
   - Read replicas for distribution

### Auto-Scaling Configuration

```
ALB + Target Group + Auto Scaling Group
    ↓
Metrics: CPU Utilization > 70%
    ↓
Automatically launch new EC2 instance
    ↓
Register with target group
    ↓
ALB distributes traffic
    ↓
Metrics: CPU < 30%
    ↓
Scale down after cooldown period
```

---

## Disaster Recovery

### Backup Strategy
1. **Database**: MongoDB Atlas automated backups (daily)
2. **Code**: GitHub repository (version control)
3. **Configuration**: Infrastructure as Code (Terraform/CloudFormation)

### Recovery Procedure
```
Disaster Event
    ↓
1. Restore MongoDB from backup
2. Launch new EC2 instances from AMI
3. Redeploy application from GitHub
4. Update DNS if needed
5. Verify health checks
6. Resume operations
```

### RTO/RPO Targets
- **RTO (Recovery Time Objective)**: < 30 minutes
- **RPO (Recovery Point Objective)**: < 1 hour

---

## Performance Optimization

### Caching Strategy
1. **Static Assets**: 1-year browser cache
2. **API Responses**: 5-minute server cache (future Redis)
3. **CDN Cache**: Cloudflare caches HTML and static files
4. **Database Indexes**: Optimized MongoDB queries

### Compression
- Gzip compression on Nginx (text, JSON)
- Image optimization via Cloudflare Polish
- Asset minification in React build

### Network Optimization
- HTTP/2 enabled
- Connection pooling
- Cloudflare Rocket Loader for JavaScript

---

## Monitoring & Alerting

### Metrics to Monitor
1. **Frontend**:
   - Nginx response time
   - Traffic volume
   - Error rates (4xx, 5xx)

2. **Backend**:
   - API response time
   - Request rate
   - PM2 process status
   - CPU/Memory usage

3. **Database**:
   - Connection count
   - Query performance
   - Disk usage
   - Replication lag

4. **Infrastructure**:
   - EC2 CPU utilization
   - Network I/O
   - Disk usage
   - ALB health check status

### Monitoring Tools
- AWS CloudWatch (native)
- Datadog (recommended)
- New Relic
- Prometheus + Grafana
- Cloudflare Analytics

---

## Cost Analysis

### Free Tier (Monthly)
- 2x t2.micro EC2 instances: $0
- Data transfer within AWS: $0
- MongoDB Atlas free tier: $0
- Cloudflare free plan: $0
- **Total**: $0 (first 12 months with AWS free tier)

### Small Scale (Monthly)
- 2x t2.small EC2 instances: ~$20
- ALB: ~$16 + data processing
- Data transfer: ~$10
- MongoDB Atlas M10 (dedicated): ~$57
- Cloudflare Pro: $20
- **Total**: ~$123/month

### Medium Scale (Monthly)
- 4x t2.medium EC2 instances: ~$80
- ALB: ~$20 + data processing (~$5)
- Data transfer: ~$30
- MongoDB Atlas M30: ~$200
- Cloudflare Business: $200
- **Total**: ~$535/month

---

## DNS Resolution Flow

```
Browser: yourdomain.com
    ↓
Cloudflare Nameserver (ns1.cloudflare.com)
    ↓
Cloudflare DNS Resolution Service
    ↓
A Record Check: yourdomain.com → Frontend EC2 IP
    ↓
Return IP address to browser
    ↓
Browser connects to Frontend EC2
    ↓
Nginx serves React application
```

---

## LoadBalancer Routing Rules

### Frontend ALB Rules
```
Listener: HTTP:80
  Rule 1: Host(yourdomain.com) → Frontend Target Group
  Rule 2: Host(www.yourdomain.com) → Frontend Target Group
```

### Backend ALB Rules
```
Listener: HTTP:80
  Rule 1: Host(api.yourdomain.com) → Backend Target Group
  Rule 2: Path(/trip*) → Backend Target Group (alternative)
```

---

## Troubleshooting Architecture Issues

### Issue: Requests taking too long

**Check Path:**
```
Browser → Cloudflare (< 100ms)
Cloudflare → ALB (< 50ms)
ALB → Backend EC2 (< 100ms)
Backend → MongoDB (< 200ms)
Total: < 500ms acceptable
```

### Issue: Database connection failing

**Check Path:**
```
EC2 Instance
    ↓ (Verify MONGO_URI in .env)
MongoDB Atlas
    ↓ (Check IP whitelist in Atlas)
Network Access
    ↓ (Verify credentials)
Database User
    ↓ (Check connection string)
```

### Issue: Load balancer not distributing traffic

**Check Path:**
```
ALB Health Checks
    ↓ (Verify health check endpoint)
Target Group
    ↓ (Verify instance status: healthy/unhealthy)
Backend Instance
    ↓ (Verify PM2 process running)
Application
    ↓ (Check logs for errors)
```

---

## Architecture Documentation Template for Draw.io

Visit https://www.draw.io and import this XML to create visual diagram:

[Refer to separate draw.io XML file for visual representation]

---

**Last Updated**: April 25, 2026
**Architecture Version**: 2.0
**Status**: Ready for Implementation
