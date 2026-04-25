# Travel Memory - Deployment Checklist

## Pre-Deployment Planning

### Prerequisites Verification
- [ ] AWS account created and verified
- [ ] AWS free tier eligible (check eligibility)
- [ ] Cloudflare account created
- [ ] Custom domain registered
- [ ] MongoDB Atlas account created and cluster ready
- [ ] SSH key pair downloaded and secured
- [ ] Local development environment tested

### Resource Planning
- [ ] EC2 instance types selected (t2.micro/small)
- [ ] Region selected (us-east-1 recommended for free tier)
- [ ] VPC and subnets planned
- [ ] Security group rules documented
- [ ] Elastic IPs allocated (if needed)
- [ ] ALB configuration planned
- [ ] MongoDB connection string obtained

---

## Phase 1: AWS Infrastructure Setup

### EC2 Instance Creation
- [ ] Backend EC2 instance(s) launched
- [ ] Frontend EC2 instance(s) launched
- [ ] Security group created with correct inbound rules:
  - [ ] Port 22 (SSH) - restricted to your IP
  - [ ] Port 80 (HTTP) - open to 0.0.0.0/0
  - [ ] Port 443 (HTTPS) - open to 0.0.0.0/0
  - [ ] Port 3000 (Backend) - open during testing
  - [ ] Port 3001 (Frontend) - open during testing
- [ ] Key pair securely stored
- [ ] Instances running and accessible via SSH
- [ ] Instances have public IP addresses assigned
- [ ] Elastic IPs allocated and associated (optional)

### Instance Tagging
- [ ] Backend instances tagged: Name=travel-memory-backend-1, Environment=prod
- [ ] Frontend instances tagged: Name=travel-memory-frontend-1, Environment=prod
- [ ] ALB tagged appropriately

---

## Phase 2: Backend Deployment

### SSH Connection
- [ ] SSH access working to backend instance
- [ ] Test command: `ssh -i key.pem ubuntu@<BACKEND_IP>`

### System Updates
- [ ] Ubuntu packages updated: `sudo apt update && sudo apt upgrade -y`
- [ ] Git installed: `git --version`
- [ ] curl available: `curl --version`

### Node.js Installation
- [ ] Node.js v18+ installed: `node --version`
- [ ] npm installed: `npm --version`
- [ ] npm packages cache cleared: `npm cache clean --force`

### Application Setup
- [ ] Repository cloned to `/home/ubuntu/TravelMemory`
- [ ] Backend directory accessed: `cd TravelMemory/backend`
- [ ] npm dependencies installed: `npm install`
- [ ] node_modules folder verified

### Environment Configuration
- [ ] `.env` file created in backend directory
- [ ] `MONGO_URI` configured with actual MongoDB credentials
  - [ ] Connection string verified in MongoDB Atlas
  - [ ] Database user created and permissions set
  - [ ] IP whitelist updated in MongoDB Atlas to include EC2 security group
- [ ] `PORT=3000` set in .env
- [ ] .env file contents verified: `cat .env`

### Process Management
- [ ] PM2 installed globally: `sudo npm install -g pm2`
- [ ] Backend started with PM2: `pm2 start index.js --name "travel-memory-backend"`
- [ ] PM2 configured for startup: `pm2 startup` and `pm2 save`
- [ ] PM2 status verified: `pm2 status`
- [ ] PM2 logs checked: `pm2 logs travel-memory-backend`

### Verification
- [ ] Backend health check works: `curl http://localhost:3000/hello`
- [ ] Backend returns: "Hello World!"
- [ ] No errors in PM2 logs
- [ ] Process is running and listening on port 3000

### Multiple Instances (if scaling)
- [ ] Repeat above steps for backend instance 2, 3, etc.
- [ ] All backend instances running independently
- [ ] All instances have same Node version and dependencies

---

## Phase 3: Frontend Deployment

### SSH Connection
- [ ] SSH access working to frontend instance
- [ ] Test command: `ssh -i key.pem ubuntu@<FRONTEND_IP>`

### System Updates
- [ ] Ubuntu packages updated
- [ ] Git installed and verified
- [ ] Build tools available

### Node.js Installation
- [ ] Node.js v18+ installed
- [ ] npm installed and updated

### Application Setup
- [ ] Repository cloned to `/home/ubuntu/TravelMemory`
- [ ] Frontend directory accessed: `cd TravelMemory/frontend`
- [ ] npm dependencies installed: `npm install`
- [ ] React app verified to have all dependencies

### Environment Configuration
- [ ] `.env` file created in frontend directory
- [ ] `REACT_APP_BACKEND_URL` set appropriately:
  - [ ] Initially: `http://<BACKEND_INSTANCE_IP>:3000` for testing
  - [ ] Finally: `https://api.yourdomain.com` for production
- [ ] .env file contents verified

### Build Process
- [ ] React build created: `npm run build`
- [ ] Build directory verified: `ls build/`
- [ ] index.html present in build folder
- [ ] No build errors or warnings (review warnings)

### Nginx Installation & Configuration
- [ ] Nginx installed: `sudo apt-get install -y nginx`
- [ ] Nginx installed correctly: `sudo nginx -t` (should show OK)
- [ ] Nginx config file backed up: `sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak`

### Nginx Configuration
- [ ] Nginx configured to serve React build from `/home/ubuntu/TravelMemory/frontend/build`
- [ ] Server listening on port 3001
- [ ] Configured for SPA routing (try_files directive)
- [ ] Static asset caching enabled (1 year)
- [ ] GZIP compression configured

### Nginx Start
- [ ] Nginx syntax valid: `sudo nginx -t`
- [ ] Nginx started: `sudo systemctl start nginx`
- [ ] Nginx enabled on startup: `sudo systemctl enable nginx`
- [ ] Nginx status verified: `sudo systemctl status nginx`

### Verification
- [ ] Frontend loads locally: `curl http://localhost:3001`
- [ ] HTML response received
- [ ] No Nginx errors: `sudo tail -f /var/log/nginx/error.log`

### Multiple Instances (if scaling)
- [ ] Repeat above steps for frontend instance 2, 3, etc.
- [ ] All frontend instances running Nginx on port 3001
- [ ] All instances serving same React build

---

## Phase 4: Load Balancing

### Application Load Balancer Setup
- [ ] ALB created in AWS
- [ ] Name: travel-memory-alb
- [ ] Scheme: Internet-facing
- [ ] Subnets: Selected all available subnets
- [ ] Security group: travel-memory-sg
- [ ] Listeners configured: HTTP:80

### Target Groups Configuration

#### Backend Target Group
- [ ] Target group created: travel-memory-backend-tg
- [ ] Protocol: HTTP
- [ ] Port: 3000
- [ ] Health check enabled:
  - [ ] Protocol: HTTP
  - [ ] Path: /hello
  - [ ] Port: 3000
  - [ ] Interval: 30 seconds
  - [ ] Threshold (healthy): 2
  - [ ] Threshold (unhealthy): 2
  - [ ] Timeout: 5 seconds
- [ ] Backend instances registered in target group
- [ ] All instances showing as "healthy"

#### Frontend Target Group
- [ ] Target group created: travel-memory-frontend-tg
- [ ] Protocol: HTTP
- [ ] Port: 3001
- [ ] Health check enabled:
  - [ ] Protocol: HTTP
  - [ ] Path: /
  - [ ] Port: 3001
  - [ ] Other settings same as backend
- [ ] Frontend instances registered
- [ ] All instances showing as "healthy"

### ALB Rules Configuration
- [ ] Rule 1: Host(api.yourdomain.com) → Backend TG
- [ ] Rule 2: Host(yourdomain.com) → Frontend TG
- [ ] Rule 3: Host(www.yourdomain.com) → Frontend TG
- [ ] Default action configured for both rules
- [ ] Rules priority set correctly

### ALB Verification
- [ ] ALB DNS name noted: `<ALB_DNS_NAME>.us-east-1.elb.amazonaws.com`
- [ ] All targets healthy
- [ ] ALB responding to health checks
- [ ] Traffic routing correctly:
  - [ ] Backend requests reaching backend instances
  - [ ] Frontend requests reaching frontend instances

---

## Phase 5: DNS Configuration (Cloudflare)

### Cloudflare Setup
- [ ] Cloudflare account created
- [ ] Domain added to Cloudflare
- [ ] Cloudflare nameservers updated at domain registrar
- [ ] DNS propagation verified (can take 24-48 hours)

### Create DNS Records

#### A Record (Frontend)
- [ ] Type: A
- [ ] Name: yourdomain.com (or @)
- [ ] IPv4 address: <FRONTEND_ELASTIC_IP>
- [ ] TTL: Auto
- [ ] Proxy status: Proxied (orange cloud)
- [ ] Record created and verified

#### CNAME Record (API)
- [ ] Type: CNAME
- [ ] Name: api.yourdomain.com
- [ ] Target: <ALB_DNS_NAME>
- [ ] TTL: Auto
- [ ] Proxy status: Proxied (orange cloud)
- [ ] Record created and verified

#### CNAME Record (WWW)
- [ ] Type: CNAME
- [ ] Name: www
- [ ] Target: yourdomain.com
- [ ] TTL: Auto
- [ ] Proxy status: Proxied (orange cloud)
- [ ] Record created and verified

### DNS Verification
- [ ] `nslookup yourdomain.com` returns Cloudflare IP
- [ ] `nslookup api.yourdomain.com` returns ALB IP
- [ ] `nslookup www.yourdomain.com` returns frontend IP
- [ ] DNS propagation complete globally (check whatsmydns.net)

### SSL/TLS Configuration
- [ ] SSL/TLS enabled in Cloudflare
- [ ] Encryption mode: Full (strict)
- [ ] Automatic HTTPS Rewrites: Enabled
- [ ] Always Use HTTPS: Enabled
- [ ] HSTS: Enabled with 12-month max age
- [ ] SSL certificate issued and active

### Firewall & Security
- [ ] DDoS protection enabled (default)
- [ ] Challenge (CAPTCHA) configured
- [ ] Security level set (Medium/High)
- [ ] WAF rules enabled (if Pro plan)
- [ ] Rate limiting configured (optional)

---

## Phase 6: Testing & Verification

### Frontend Access
- [ ] Access application via domain: `https://yourdomain.com`
- [ ] Application loads without errors
- [ ] React logo/interface visible
- [ ] No mixed content warnings (all HTTPS)
- [ ] Responsive on mobile devices

### API Connectivity
- [ ] Frontend able to communicate with backend API
- [ ] API calls working (console should show no errors)
- [ ] GET /trip endpoint working: `curl https://api.yourdomain.com/trip`
- [ ] POST /trip endpoint working with sample data
- [ ] CORS headers present in responses

### Database Integration
- [ ] Sample trip data visible in frontend
- [ ] Create new trip through frontend:
  - [ ] Form submission successful
  - [ ] Trip appears in database
  - [ ] Trip displays in list
- [ ] Edit functionality working
- [ ] Delete functionality working

### Load Balancing
- [ ] Monitor ALB target health (all healthy)
- [ ] Terminate one backend instance
  - [ ] Traffic automatically routed to remaining instances
  - [ ] Frontend still responsive
  - [ ] No data loss
- [ ] Restart terminated instance
  - [ ] Instance rejoins load balancer
  - [ ] All instances healthy again

### Performance
- [ ] Page load time < 2 seconds (from browser)
- [ ] API response time < 500ms
- [ ] Images loading properly
- [ ] Static assets cached (check response headers)
- [ ] No console errors or warnings

### Security
- [ ] All traffic over HTTPS
- [ ] HSTS header present
- [ ] No sensitive data in logs
- [ ] Cloudflare DDoS protection active
- [ ] Rate limiting preventing abuse

### Cross-Browser Testing
- [ ] Chrome: Working
- [ ] Firefox: Working
- [ ] Safari: Working
- [ ] Edge: Working
- [ ] Mobile browsers: Working

---

## Phase 7: Monitoring & Maintenance

### CloudWatch Monitoring
- [ ] CloudWatch dashboards created
- [ ] Metrics monitored:
  - [ ] ALB response time
  - [ ] Target health
  - [ ] Request count
  - [ ] Error rates (4xx, 5xx)
- [ ] Alarms configured for:
  - [ ] High CPU utilization (> 80%)
  - [ ] High memory usage (> 80%)
  - [ ] Unhealthy targets
  - [ ] High error rate (> 5%)

### Logs Configuration
- [ ] CloudWatch Logs enabled for ALB
- [ ] Application logs being written
- [ ] Log retention set (e.g., 7 days)
- [ ] Log analysis tools configured (optional)

### Backup & Disaster Recovery
- [ ] MongoDB Atlas backups enabled
- [ ] Backup retention policy verified
- [ ] Test backup restore procedure documented
- [ ] GitHub repository up to date with all code
- [ ] Infrastructure as Code (Terraform) scripts created

### Regular Maintenance
- [ ] Update schedule defined (weekly/monthly)
- [ ] Security patches auto-enabled in EC2
- [ ] Node.js and npm dependencies updated plan
- [ ] Database maintenance window scheduled
- [ ] Performance review scheduled (monthly)

---

## Phase 8: Documentation

### Documentation Completed
- [ ] Deployment guide written and finalized
- [ ] AWS EC2 setup documented
- [ ] Backend deployment steps documented
- [ ] Frontend deployment steps documented
- [ ] Nginx configuration documented
- [ ] Cloudflare DNS setup documented
- [ ] Architecture diagram created (draw.io)
- [ ] Troubleshooting guide created
- [ ] Screenshots added to documentation:
  - [ ] AWS EC2 instances launched
  - [ ] Security group configuration
  - [ ] ALB setup
  - [ ] Target groups healthy
  - [ ] Cloudflare DNS records
  - [ ] Frontend loaded
  - [ ] API working
  - [ ] Database data visible

### GitHub Repository
- [ ] All documentation pushed to repository
- [ ] Code also in repository if private
- [ ] README.md updated with deployment instructions
- [ ] Branch strategy documented
- [ ] Contribution guidelines added (if needed)

---

## Phase 9: Pre-Production Review

### Code Quality
- [ ] No console errors or warnings
- [ ] ESLint/Prettier passed (if applicable)
- [ ] Backend validated with test data
- [ ] Security best practices followed
- [ ] Sensitive data removed from logs

### Infrastructure Review
- [ ] Security groups restrictive enough
- [ ] No unnecessary open ports
- [ ] IAM roles configured properly
- [ ] Encryption enabled where appropriate
- [ ] Backups tested and working

### Performance Review
- [ ] Page load time optimized
- [ ] API response time acceptable
- [ ] Database queries optimized
- [ ] Caching strategy effective
- [ ] CDN properly configured

### Compliance
- [ ] SSL/TLS certificates valid
- [ ] Privacy policy in place
- [ ] Terms of service ready
- [ ] GDPR compliance checked (if applicable)
- [ ] Data retention policy defined

---

## Phase 10: Production Deployment

### Final Checks
- [ ] All team members notified of deployment
- [ ] Maintenance window scheduled (if needed)
- [ ] Rollback plan prepared
- [ ] Support team trained
- [ ] Monitoring alerts tested

### Go-Live
- [ ] Update production environment variable (if different)
- [ ] Final DNS verification
- [ ] Production load test (low traffic initially)
- [ ] Monitor closely first 24 hours
- [ ] Document any issues encountered

### Post-Deployment
- [ ] Send announcement to users
- [ ] Monitor error rates and performance
- [ ] Check user feedback channels
- [ ] Document lessons learned
- [ ] Schedule post-deployment review

---

## Post-Deployment Maintenance

### Daily Tasks
- [ ] Check ALB health status
- [ ] Monitor error logs
- [ ] Verify backups completed
- [ ] Check system resources

### Weekly Tasks
- [ ] Review performance metrics
- [ ] Check for security updates
- [ ] Update npm packages (security patches only)
- [ ] Database optimization review

### Monthly Tasks
- [ ] Full system review
- [ ] Performance analysis
- [ ] Capacity planning
- [ ] Cost optimization review
- [ ] Test disaster recovery

### Quarterly Tasks
- [ ] Major version updates for dependencies
- [ ] Security audit
- [ ] Architecture review
- [ ] Scaling assessment
- [ ] Compliance review

---

## Deployment Status

- **Date Started**: [Insert Date]
- **Target Completion**: [Insert Date]
- **Overall Progress**: 0%
  - Phase 1 (AWS Setup): 0%
  - Phase 2 (Backend): 0%
  - Phase 3 (Frontend): 0%
  - Phase 4 (Load Balancing): 0%
  - Phase 5 (DNS): 0%
  - Phase 6 (Testing): 0%
  - Phase 7 (Monitoring): 0%
  - Phase 8 (Documentation): 0%
  - Phase 9 (Review): 0%
  - Phase 10 (Production): 0%

---

## Sign-Off

- [ ] Project Manager: __________________ Date: ________
- [ ] DevOps Engineer: __________________ Date: ________
- [ ] QA Lead: __________________ Date: ________
- [ ] Tech Lead: __________________ Date: ________

---

**Last Updated**: April 25, 2026
**Version**: 1.0
**Status**: Ready for Deployment
