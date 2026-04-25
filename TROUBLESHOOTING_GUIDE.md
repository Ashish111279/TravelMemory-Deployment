# Travel Memory - Troubleshooting Guide

## Troubleshooting Common Issues

This guide helps resolve common issues encountered during deployment and operation of Travel Memory.

---

## Section 1: SSH & Connection Issues

### Issue 1.1: "Permission denied (publickey)"

**Symptoms**: Cannot SSH into EC2 instance

**Causes**:
- Wrong key file
- Incorrect permissions on key file
- Wrong username
- Wrong IP address

**Solutions**:

```bash
# 1. Check key file permissions (should be 400)
ls -la your-key.pem
chmod 400 your-key.pem

# 2. Verify key file exists and is readable
file your-key.pem

# 3. Try with verbose output to see error details
ssh -v -i your-key.pem ubuntu@<IP>

# 4. Ensure username is correct (usually 'ubuntu' for Ubuntu AMI)
# For Amazon Linux: 'ec2-user'
# For Ubuntu: 'ubuntu'
# For CentOS: 'centos'

# 5. Verify IP address is correct
ping <EC2_IP>

# 6. Check security group allows SSH (port 22)
# AWS Console → Security Groups → Inbound Rules
```

### Issue 1.2: "Network is unreachable" or "No route to host"

**Symptoms**: Cannot connect to EC2 instance by IP

**Causes**:
- EC2 instance not running
- EC2 instance doesn't have public IP
- Security group blocking traffic
- Network ACL blocking traffic

**Solutions**:

```bash
# 1. Verify instance is running
# AWS Console → EC2 Instances → Check Status

# 2. Verify instance has public IP
# AWS Console → Instance Details → Public IPv4

# 3. Check security group inbound rules
# Should have:
# - SSH (22) from your IP
# - HTTP (80) from 0.0.0.0/0
# - HTTPS (443) from 0.0.0.0/0

# 4. Verify ping to instance works
ping <EC2_PUBLIC_IP>

# 5. If in VPC, verify:
# - Subnet has route to internet gateway
# - Internet gateway attached to VPC
# - Network ACL allows SSH traffic
```

### Issue 1.3: "Connection refused" or "Connection timeout"

**Symptoms**: Can SSH but application not responding

**Causes**:
- Application not running
- Application listening on wrong port
- Firewall blocking port
- Security group not configured

**Solutions**:

```bash
# 1. Check if application is running
ps aux | grep node
ps aux | grep nginx

# 2. Check listening ports
netstat -tuln | grep LISTEN
# Should show:
# - :3000 for backend
# - :3001 for frontend nginx

# 3. Check firewall rules
sudo ufw status
sudo ufw allow 3000
sudo ufw allow 3001

# 4. Check PM2 status (backend)
pm2 status
pm2 logs travel-memory-backend

# 5. Check Nginx status (frontend)
sudo systemctl status nginx
sudo tail -f /var/log/nginx/error.log
```

---

## Section 2: Backend Issues

### Issue 2.1: Backend won't start or crashes immediately

**Symptoms**: PM2 shows "stopped" or "errored" status

**Causes**:
- Syntax error in code
- Missing dependencies
- Environment variables not set
- Port already in use

**Solutions**:

```bash
# 1. Check PM2 logs
pm2 logs travel-memory-backend

# 2. Try running directly to see error
cd ~/TravelMemory/backend
node index.js

# 3. Verify dependencies installed
npm list
npm install  # reinstall all

# 4. Check for syntax errors
node -c index.js  # check syntax

# 5. Check if port 3000 is in use
netstat -tuln | grep 3000
# If in use:
sudo lsof -i :3000
sudo kill -9 <PID>

# 6. Restart PM2
pm2 restart travel-memory-backend
pm2 logs
```

### Issue 2.2: Backend error: "Cannot find module"

**Symptoms**: PM2 logs show "Error: Cannot find module 'express'"

**Causes**:
- Dependencies not installed
- Wrong version of Node.js
- node_modules deleted or corrupted

**Solutions**:

```bash
# 1. Reinstall dependencies
cd ~/TravelMemory/backend
rm -rf node_modules
rm package-lock.json
npm install

# 2. Check Node.js version
node --version
# Should be v14+ (recommended v16+)

# 3. Clear npm cache
npm cache clean --force

# 4. Verify package.json is valid
cat package.json  # Check JSON is valid

# 5. Install specific module
npm install express cors mongoose dotenv

# 6. Restart backend
pm2 restart travel-memory-backend
```

### Issue 2.3: Backend error: "MongooseError: Cannot connect to MongoDB"

**Symptoms**: PM2 logs show MongoDB connection error

**Causes**:
- Incorrect connection string
- MongoDB credentials wrong
- MongoDB IP not whitelisted
- MongoDB service not running

**Solutions**:

```bash
# 1. Verify connection string in .env
cat .env
# Should look like:
# MONGO_URI=mongodb+srv://username:password@cluster0.mongodb.net/dbname

# 2. Check credentials
# MongoDB Atlas → Database Access → Check user credentials

# 3. Verify IP whitelist in MongoDB Atlas
# MongoDB Atlas → Network Access → IP Whitelist
# Add current EC2 security group IP or 0.0.0.0/0 for testing

# 4. Test MongoDB connection manually
mongosh "mongodb+srv://username:password@cluster0.mongodb.net/dbname"
# Or with old mongo shell:
mongo "mongodb+srv://username:password@cluster0.mongodb.net/dbname"

# 5. Check MongoDB Atlas cluster status
# Should show "Available"

# 6. Check DNS resolution
nslookup cluster0.mongodb.net
# Should return IP addresses

# 7. If still fails, check firewall from EC2
telnet cluster0.mongodb.net 27017
# Should connect (Ctrl+C to exit)

# 8. Restart backend after fixing
pm2 restart travel-memory-backend
```

### Issue 2.4: Health check failing on ALB

**Symptoms**: ALB target group shows "Unhealthy" for backend

**Causes**:
- /hello endpoint not responding
- Port 3000 not open in security group
- Health check timeout too low
- Backend server crashed

**Solutions**:

```bash
# 1. Test health endpoint locally
curl http://localhost:3000/hello
# Should return: "Hello World!"

# 2. Check from another instance
curl http://<BACKEND_INSTANCE_IP>:3000/hello

# 3. Check security group
# Should allow port 3000 from ALB security group

# 4. Check health check settings in ALB
# AWS Console → Target Groups → Health Checks
# - Path: /hello
# - Port: 3000
# - Protocol: HTTP
# - Timeout: 5 seconds
# - Interval: 30 seconds
# - Healthy threshold: 2

# 5. Increase timeout if network is slow
# Set Timeout to 10 seconds

# 6. Check backend logs
pm2 logs travel-memory-backend

# 7. Restart backend
pm2 stop travel-memory-backend
pm2 start index.js --name "travel-memory-backend"
pm2 save
```

### Issue 2.5: API requests returning 502 Bad Gateway

**Symptoms**: API calls fail with 502 error

**Causes**:
- Backend not accessible through ALB
- Backend crashed
- ALB target unhealthy
- Nginx proxy misconfigured

**Solutions**:

```bash
# 1. Verify target health in ALB
# AWS Console → Target Groups → Targets
# All should show "Healthy"

# 2. Check backend directly
curl http://<BACKEND_IP>:3000/hello

# 3. Check PM2 status
pm2 status
pm2 logs travel-memory-backend

# 4. Check ALB access logs
# AWS Console → Load Balancers → Select ALB
# Access Logs tab (must be enabled)

# 5. Check Nginx logs (if frontend proxy)
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# 6. Verify Nginx upstream servers
sudo cat /etc/nginx/nginx.conf | grep upstream -A 5

# 7. Test through ALB DNS
curl http://<ALB_DNS_NAME>/hello

# 8. Restart backend and check
pm2 restart travel-memory-backend
pm2 save
```

---

## Section 3: Frontend Issues

### Issue 3.1: Nginx won't start or stops immediately

**Symptoms**: Nginx service fails to start

**Causes**:
- Nginx configuration syntax error
- Port 3001 already in use
- Permission issues with build directory
- Nginx process already running

**Solutions**:

```bash
# 1. Test Nginx configuration
sudo nginx -t
# Look for syntax errors in output

# 2. View Nginx error log
sudo tail -f /var/log/nginx/error.log

# 3. Check port 3001 is free
netstat -tuln | grep 3001
sudo lsof -i :3001
# If in use, kill it:
sudo kill -9 <PID>

# 4. Check permissions on build directory
ls -la ~/TravelMemory/frontend/build
# Should be readable by nginx user

# 5. Try starting nginx with details
sudo systemctl start nginx -v

# 6. Check if nginx process is running
ps aux | grep nginx

# 7. Restart nginx
sudo systemctl restart nginx
sudo systemctl status nginx
```

### Issue 3.2: Frontend shows blank page or 404

**Symptoms**: Browser shows empty page when accessing yourdomain.com

**Causes**:
- React build missing or incomplete
- Nginx not configured for SPA
- Wrong document root
- Corrupted build files

**Solutions**:

```bash
# 1. Verify build exists
ls -la ~/TravelMemory/frontend/build/
# Should contain: index.html, static/, favicon.ico

# 2. Rebuild React app
cd ~/TravelMemory/frontend
npm run build
# Should complete without errors

# 3. Check Nginx configuration
sudo cat /etc/nginx/sites-available/default
# Should have:
# - root /home/ubuntu/TravelMemory/frontend/build;
# - location / { try_files $uri /index.html; }

# 4. Test Nginx locally
curl -I http://localhost:3001/
# Should return 200 OK

# 5. Check file ownership
ls -la ~/TravelMemory/frontend/build/index.html
sudo chown -R www-data:www-data ~/TravelMemory/frontend/build

# 6. Reload Nginx
sudo nginx -s reload
sudo systemctl reload nginx

# 7. Clear browser cache
# Browser: Ctrl+Shift+Delete → Clear cache
```

### Issue 3.3: React app shows errors in console

**Symptoms**: Browser console shows JavaScript errors

**Causes**:
- Frontend can't connect to backend
- Backend URL incorrect in .env
- CORS not configured
- Build has errors

**Solutions**:

```bash
# 1. Check .env file
cat ~/TravelMemory/frontend/.env
# Should have:
# REACT_APP_BACKEND_URL=http://api.yourdomain.com

# 2. Rebuild frontend to include env
cd ~/TravelMemory/frontend
npm run build

# 3. Verify API is accessible
curl https://api.yourdomain.com/hello
# Should return: "Hello World!"

# 4. Check CORS headers in backend
# Backend index.js should have:
# const cors = require('cors')
# app.use(cors())

# 5. Check browser console for actual error message
# Browser: F12 → Console tab → Look for red errors

# 6. Network tab shows API responses
# Browser: F12 → Network tab → Reload → Look for API calls
# Check response status and body

# 7. If mixed content warning:
# Ensure all requests use HTTPS
# Update backend URL to https://

# 8. Restart Nginx
sudo systemctl restart nginx
```

### Issue 3.4: Static assets not loading (CSS/JS broken)

**Symptoms**: Page loads but styling missing, JavaScript not working

**Causes**:
- Static files missing from build
- Nginx not serving static files
- File permissions incorrect
- Browser caching old files

**Solutions**:

```bash
# 1. Verify static files exist
ls -la ~/TravelMemory/frontend/build/static/
# Should contain js/ and css/ folders

# 2. Check file permissions
ls -la ~/TravelMemory/frontend/build/static/js/
# Should be readable

# 3. Check Nginx logs for 404s
sudo tail -f /var/log/nginx/access.log
# Look for 404 entries

# 4. Test static file access
curl http://localhost:3001/static/js/main.*.js
# Should return JavaScript file content (not HTML)

# 5. Clear browser cache
# Ctrl+Shift+Delete → Clear all time period

# 6. Hard refresh in browser
# Ctrl+Shift+R (Chrome)
# Cmd+Shift+R (Mac)
# Ctrl+F5 (Firefox/Edge)

# 7. Check Nginx cache settings
sudo grep -A 3 "location ~\* \\.(js|css" /etc/nginx/sites-available/default
# Should have expires 1y;

# 8. Rebuild frontend
cd ~/TravelMemory/frontend
npm run build
sudo systemctl restart nginx
```

### Issue 3.5: Health check failing on ALB (frontend)

**Symptoms**: ALB target group shows "Unhealthy" for frontend

**Causes**:
- Nginx not responding to root path
- Nginx returning wrong status code
- Port 3001 not open

**Solutions**:

```bash
# 1. Test root path response
curl http://localhost:3001/
# Should return HTML with 200 status

# 2. Test with verbose output
curl -v http://localhost:3001/
# Check response code is 200

# 3. Check Nginx configuration for / location
sudo grep -A 5 "location /" /etc/nginx/sites-available/default
# Should have: try_files $uri /index.html;

# 4. Check ALB health check settings
# AWS Console → Target Groups → Health Checks
# - Path: /
# - Port: 3001
# - Protocol: HTTP
# - Timeout: 5 seconds

# 5. Increase timeout if slow network
# Set to 10 seconds

# 6. Check security group allows 3001
# Should have port 3001 open to ALB security group

# 7. Restart Nginx
sudo systemctl restart nginx

# 8. Check ALB marks targets as healthy
# Sometimes takes a minute after restart
```

---

## Section 4: DNS & Cloudflare Issues

### Issue 4.1: Domain not resolving

**Symptoms**: Cannot access yourdomain.com in browser (Domain not found)

**Causes**:
- Cloudflare nameservers not updated at registrar
- DNS propagation not complete
- Nameserver update failed
- Domain registration expired

**Solutions**:

```bash
# 1. Check current nameservers
nslookup yourdomain.com
# Should show Cloudflare nameservers

# 2. Check what registrar shows
# Login to domain registrar (GoDaddy, Namecheap, etc.)
# Go to DNS/Nameservers settings
# Should show Cloudflare nameservers

# 3. Verify Cloudflare nameservers are correct
# Cloudflare Dashboard → Overview
# Look for "Nameserver" section
# Get exact nameserver addresses

# 4. Update nameservers at registrar if wrong
# Remove old nameservers
# Add Cloudflare nameservers (exactly as shown)
# Save changes

# 5. Wait for propagation (24-48 hours)
# Check status: https://www.whatsmydns.net
# Enter domain name and check DNS propagation globally

# 6. If still not working after 48 hours:
# Verify domain registration is active
# Check for any DNS errors in Cloudflare dashboard
# Contact Cloudflare support

# 7. Test DNS from different locations
# Use online DNS checker: https://www.mxtoolbox.com/
# Check A record points to correct IP
```

### Issue 4.2: API domain not resolving (api.yourdomain.com)

**Symptoms**: Can access yourdomain.com but api.yourdomain.com fails

**Causes**:
- CNAME record not created
- CNAME points to wrong target
- DNS propagation incomplete
- Cloudflare CNAME flattening

**Solutions**:

```bash
# 1. Check CNAME record in Cloudflare
# Cloudflare Dashboard → DNS → Records
# Look for api.yourdomain.com CNAME record
# Should point to: <ALB_DNS_NAME>

# 2. Test CNAME resolution
nslookup api.yourdomain.com
# Should return: CNAME alb-xxx.elb.amazonaws.com
# Should return: A <ALB_IP>

# 3. Verify ALB DNS name is correct
# AWS Console → Load Balancers → Select ALB
# Look for "DNS name" field
# Compare with Cloudflare CNAME target

# 4. Correct CNAME record if wrong
# Cloudflare Dashboard → DNS → Records
# Click api record → Edit
# Update target to correct ALB DNS name
# Save

# 5. Wait for DNS propagation
# Check: https://www.whatsmydns.net
# Enter: api.yourdomain.com

# 6. Test from command line
dig api.yourdomain.com
# Should show CNAME and A record resolution

# 7. Check ALB is responding
curl http://<ALB_DNS_NAME>
# Should work
```

### Issue 4.3: SSL certificate not working (HTTPS shows error)

**Symptoms**: Browser shows SSL certificate error when accessing https://yourdomain.com

**Causes**:
- SSL certificate not issued
- Wrong encryption mode in Cloudflare
- Certificate expired
- Mixed content (HTTP resources on HTTPS page)

**Solutions**:

```bash
# 1. Check SSL status in Cloudflare
# Cloudflare Dashboard → SSL/TLS → Overview
# Should show: "Active Certificate"

# 2. Check encryption mode
# Cloudflare Dashboard → SSL/TLS → Overview
# Should show: "Flexible", "Full", or "Full (strict)"
# Recommended: "Full (strict)"

# 3. Change encryption mode if needed
# Click on encryption mode
# Select "Full (strict)"
# Wait a few minutes for certificate to issue

# 4. Check certificate details
# Browser → Click lock icon → Details
# Verify certificate is for your domain
# Check expiration date

# 5. Clear browser cache and cookies
# Ctrl+Shift+Delete → Clear all data

# 6. Try different browser to isolate issue
# Chrome, Firefox, Edge

# 7. Check for mixed content warnings
# Browser: F12 → Console → Look for mixed content errors
# Ensure all resources load via HTTPS

# 8. Force HTTPS in Cloudflare
# Cloudflare Dashboard → SSL/TLS → Edge Certificates
# Enable: "Always Use HTTPS"

# 9. Wait 5-15 minutes for certificate issue
# Usually immediate but sometimes takes time

# 10. Test SSL certificate
curl https://yourdomain.com -v
# Should connect without certificate warnings
```

### Issue 4.4: DNS records showing as "DNS only" instead of "Proxied"

**Symptoms**: Cloudflare shows "DNS only" (grey cloud) instead of "Proxied" (orange cloud)

**Causes**:
- DNS record incorrectly configured
- Trying to proxy unsupported record type
- Cloudflare limitations

**Solutions**:

```bash
# 1. Edit DNS record in Cloudflare
# Cloudflare Dashboard → DNS → Records
# Click on record → Edit

# 2. Change proxy status
# Click "DNS only" → Select "Proxied"
# Blue/Orange cloud means proxied through Cloudflare
# Grey cloud means direct DNS

# 3. For A records:
# Should be "Proxied" (orange cloud) for benefits

# 4. For CNAME records:
# Can be "Proxied" but may show warning about CNAME flattening
# Still works fine with orange cloud

# 5. For MX, TXT, SRV records:
# Must be "DNS only" (grey cloud)
# Can't be proxied

# 6. Some record types can't be proxied:
# - MX (mail)
# - TXT (SPF, DKIM, DMARC, verification)
# - NS (nameserver delegation)
# - CAA (certificate authority authorization)

# 7. Save changes and wait for update
# Usually instant but can take up to 5 minutes
```

---

## Section 5: Load Balancer Issues

### Issue 5.1: ALB showing "Unhealthy" targets

**Symptoms**: All targets in target group show "Unhealthy"

**Causes**:
- Instances not running
- Application not responding on specified port
- Health check endpoint not implemented
- Security group blocking health checks

**Solutions**:

```bash
# 1. Verify instances are running
# AWS Console → EC2 Instances
# Check status is "running"

# 2. SSH into instance and check application
ssh -i key.pem ubuntu@<INSTANCE_IP>

# 3. Check if backend is running
pm2 status
curl http://localhost:3000/hello

# 4. Check if frontend is running
sudo systemctl status nginx
curl http://localhost:3001/

# 5. Check health check configuration
# AWS Console → Target Groups → Select target group
# Health Checks tab
# Verify:
# - Protocol: HTTP (not HTTPS)
# - Port: 3000 (backend) or 3001 (frontend)
# - Path: /hello (backend) or / (frontend)
# - Interval: 30 seconds
# - Timeout: 5 seconds
# - Healthy threshold: 2
# - Unhealthy threshold: 2

# 6. Check security group allows health checks
# AWS Console → Security Groups
# Inbound rules should allow:
# - Port 3000 from ALB security group
# - Port 3001 from ALB security group

# 7. Check ALB has correct security group
# AWS Console → Load Balancers → ALB
# Associated Security Groups

# 8. Increase health check timeout if slow
# Set Timeout to 10 seconds

# 9. Restart application
pm2 restart travel-memory-backend
sudo systemctl restart nginx

# 10. Deregister and re-register target
# AWS Console → Target Groups
# Select target → Deregister → Re-register

# 11. Check ALB logs (if enabled)
# AWS Console → Load Balancers → ALB
# Access Logs → View logs in S3
```

### Issue 5.2: ALB requests going to wrong target group

**Symptoms**: Frontend requests going to backend or vice versa

**Causes**:
- ALB listener rules misconfigured
- Rule priority wrong
- Host header matching not working

**Solutions**:

```bash
# 1. Check ALB listener rules
# AWS Console → Load Balancers → ALB
# Listeners → HTTP:80
# View Rules

# 2. Verify rule order (processed top to bottom)
# Rule 1: Host(api.yourdomain.com) → Backend TG (should be first)
# Rule 2: Host(yourdomain.com) → Frontend TG
# Default: → Frontend TG

# 3. Check rules use correct host headers
# Edit rule → Conditions
# Should match exact domain names

# 4. Add Host header condition if missing
# Rule should check: IF Host header = yourdomain.com
# THEN route to Frontend TG

# 5. Test routing with curl
curl -H "Host: yourdomain.com" http://<ALB_DNS_NAME>/
# Should go to frontend

curl -H "Host: api.yourdomain.com" http://<ALB_DNS_NAME>/hello
# Should go to backend

# 6. Check Cloudflare is forwarding correct Host header
# Add logging to see Host header

# 7. Modify rule priority
# Rules are processed in order
# API rule should come before main domain rule

# 8. Save changes and test again
```

### Issue 5.3: High latency or slow performance through ALB

**Symptoms**: Requests take longer than expected

**Causes**:
- Health check interval too aggressive
- Connection limits reached
- Stickiness enabled when not needed
- ALB in different region than targets

**Solutions**:

```bash
# 1. Check ALB performance metrics
# AWS Console → Load Balancers → Select ALB
# Monitoring tab
# Check: Target Response Time, Request Count

# 2. Optimize health check interval
# Target Group → Health Checks
# Current: 30 seconds interval
# If many targets, increase to 60 seconds

# 3. Check for connection pooling issues
# Enable connection draining:
# Target Group → Attributes
# Deregistration Delay: 30 seconds

# 4. Verify session stickiness
# Target Group → Attributes
# Stickiness disabled unless needed

# 5. Check target response time
# AWS Console → CloudWatch → Metrics
# Search: TargetResponseTime
# If high (> 1 second), targets may be slow

# 6. Monitor target CPU and memory
# SSH into instances
# top  # Check CPU usage
# free -h  # Check memory usage

# 7. Scale horizontally (add more instances)
# Add new instances to target group
# Distribute load

# 8. Check backend response time
# Add timing logs to Node.js backend
# Time database queries

# 9. Enable ALB access logs
# ALB → Attributes → Access logs
# Store in S3 for analysis

# 10. Optimize database queries
# Check MongoDB query performance
# Add indexes if needed
```

---

## Section 6: MongoDB Connection Issues

### Issue 6.1: "MongoServerSelectionError: connect ENOTFOUND"

**Symptoms**: Cannot connect to MongoDB, DNS lookup fails

**Causes**:
- Connection string wrong
- MongoDB Atlas domain typo
- DNS not resolving MongoDB domain
- Network timeout

**Solutions**:

```bash
# 1. Verify connection string format
# Should be: mongodb+srv://username:password@cluster0.mongodb.net/dbname
cat .env | grep MONGO_URI

# 2. Check cluster name is correct
# MongoDB Atlas → Clusters
# Verify cluster name matches in connection string

# 3. Resolve MongoDB domain
nslookup cluster0.mongodb.net
# Should return IP addresses

# 4. Test DNS from EC2
# SSH into instance
ssh -i key.pem ubuntu@<IP>
nslookup cluster0.mongodb.net

# 5. Check MongoDB Atlas cluster is running
# MongoDB Atlas Dashboard
# Cluster should show "Available"

# 6. Increase connection timeout
# Add to connection string: ?retryWrites=true&w=majority&maxPoolSize=50

# 7. Update MONGO_URI in .env
# Ensure no extra spaces or typos
cat .env

# 8. Restart backend
pm2 restart travel-memory-backend
pm2 logs

# 9. Test with mongosh (if installed)
mongosh "mongodb+srv://username:password@cluster0.mongodb.net/dbname"
```

### Issue 6.2: "MongoAuthenticationError: authentication failed"

**Symptoms**: Cannot connect to MongoDB - authentication error

**Causes**:
- Wrong username or password
- User doesn't exist
- User permissions wrong
- Special characters in password not escaped

**Solutions**:

```bash
# 1. Verify credentials
# MongoDB Atlas → Database Access
# Check username and password match .env

# 2. Check user permissions
# MongoDB Atlas → Database Access
# User should have at least "Read and write to any database"

# 3. If password has special characters:
# Escape them in connection string
# @ → %40
# : → %3A
# # → %23
# ? → %3F

# Example: password="p@ss:word"
# Use in URI: p%40ss%3Aword

# 4. Recreate database user if needed
# MongoDB Atlas → Database Access
# Click user → Delete
# Create new user with simpler password

# 5. Reset password
# MongoDB Atlas → Database Access
# Click user → Edit → Change password
# Update .env with new password

# 6. Check connection string format
# mongo URI should be:
# mongodb+srv://username:password@cluster0.mongodb.net/dbname?retryWrites=true&w=majority

# 7. Test new credentials locally
mongosh "mongodb+srv://newuser:newpassword@cluster0.mongodb.net/travelmemory"

# 8. Update .env and restart
# Backend: pm2 restart travel-memory-backend
# Frontend: sudo systemctl restart nginx
```

### Issue 6.3: IP not whitelisted (MongoDB Atlas firewall)

**Symptoms**: Cannot connect from EC2, "connection timeout"

**Causes**:
- EC2 IP not in MongoDB Atlas whitelist
- Security group IP changed (Elastic IP needed)
- Wrong source IP

**Solutions**:

```bash
# 1. Add EC2 security group to whitelist
# MongoDB Atlas → Network Access
# Add IP Address
# Enter: 0.0.0.0/0 (for testing - not recommended for prod)
# Or: <EC2_INSTANCE_IP>/32

# 2. For production, add Elastic IP
# AWS Console → Elastic IPs
# Associate with EC2 instance if not already
# Note the Elastic IP address

# 3. Add Elastic IP to MongoDB whitelist
# MongoDB Atlas → Network Access
# Add IP Address: <ELASTIC_IP>/32

# 4. Find current EC2 IP
# AWS Console → EC2 Instance details
# Check "Public IPv4 address"

# 5. Whitelist entire security group
# MongoDB Atlas → Network Access
# Some versions allow security group selection
# Or whitelist 0.0.0.0/0 temporarily

# 6. Test connection from EC2
ssh -i key.pem ubuntu@<EC2_IP>
telnet cluster0.mongodb.net 27017

# 7. If still fails, check firewall from EC2 side
# Security group should allow outbound HTTPS (443)
# Usually enabled by default

# 8. Restart backend after whitelisting
pm2 restart travel-memory-backend
pm2 logs
```

---

## Section 7: Performance Issues

### Issue 7.1: High CPU usage on EC2 instance

**Symptoms**: EC2 instance using 80-100% CPU

**Causes**:
- Infinite loop in code
- Database query too slow
- Too many requests
- Memory leak causing garbage collection stress

**Solutions**:

```bash
# 1. Check processes using CPU
top
# Press 'q' to quit
# Look for node or nginx processes

# 2. Get detailed process info
ps aux --sort=-%cpu | head -10
# Shows top CPU-using processes

# 3. Check Node.js process
ps aux | grep node
# Get process ID

# 4. Use diagnostic tools
kill -USR2 <NODE_PID>  # Create heapdump

# 5. Check database query performance
# MongoDB Atlas → Performance Advisor
# Look for slow queries

# 6. Add logging to backend
# Log request start and end time
// In Express middleware:
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    console.log(`${req.method} ${req.path}: ${Date.now() - start}ms`);
  });
  next();
});

# 7. Identify slow endpoints
# Restart backend with logging
pm2 restart travel-memory-backend
# Make requests and watch logs

# 8. Optimize slow code
# Add indexes to database queries
# Cache frequently accessed data
# Use pagination for large result sets

# 9. Monitor continuously
# AWS CloudWatch → EC2 Metrics → CPU Utilization
# Set alarm if > 70%

# 10. Scale if needed
# Add more instances behind ALB
```

### Issue 7.2: High memory usage causing OOM (Out of Memory)

**Symptoms**: Server crashes with "FATAL ERROR" or "JavaScript heap out of memory"

**Causes**:
- Memory leak in Node.js application
- Too many concurrent connections
- Large dataset in memory
- Inefficient data structures

**Solutions**:

```bash
# 1. Check memory usage
free -h
# Shows total, used, available memory

# 2. Monitor Node.js process memory
ps aux | grep node
# Look at RSS (resident set size)

# 3. Check PM2 memory usage
pm2 monit
# Real-time memory monitoring

# 4. Increase Node.js heap limit (temporary)
# Stop backend
pm2 stop travel-memory-backend

# Start with more memory
node --max-old-space-size=2048 index.js

# Or with PM2:
pm2 start index.js --name "travel-memory-backend" --max-memory-restart 1G

# 5. Find memory leaks
# Add heap dumps at intervals
# Analyze with Chrome DevTools

# 6. Optimize code
# Don't store large objects in global scope
# Properly close database connections
# Clean up event listeners

# 7. Use streaming for large data
// Instead of:
const data = await collection.find({}).toArray(); // All in memory

// Use:
collection.find({}).stream(); // Stream results

# 8. Implement pagination for APIs
// Limit results
const trips = await db.collection('trips')
  .find({})
  .skip(skip)
  .limit(20)
  .toArray();

# 9. Scale vertically
# Use larger instance type (t2.small → t2.medium)

# 10. Scale horizontally
# Add more backend instances
# Distribute load with ALB

# 11. Monitor memory over time
# AWS CloudWatch → Custom Metrics
# Track memory trends
```

---

## Section 8: Deployment Issues

### Issue 8.1: Code changes not reflected in production

**Symptoms**: Deployed new code but changes not visible

**Causes**:
- Forgot to rebuild frontend
- Nginx serving old cached files
- PM2 not restarted
- Old branch deployed

**Solutions**:

```bash
# 1. For backend changes:
# SSH into backend instance
ssh -i key.pem ubuntu@<BACKEND_IP>

# Update code
cd ~/TravelMemory/backend
git pull origin main
npm install  # If dependencies changed

# Restart PM2
pm2 restart travel-memory-backend
pm2 logs

# 2. For frontend changes:
# SSH into frontend instance
ssh -i key.pem ubuntu@<FRONTEND_IP>

# Update code
cd ~/TravelMemory/frontend
git pull origin main
npm install  # If dependencies changed

# Rebuild
npm run build

# Reload Nginx
sudo systemctl reload nginx

# 3. Clear browser cache
# Ctrl+Shift+Delete → Clear cache

# 4. Clear CDN cache (Cloudflare)
# Cloudflare Dashboard → Caching → Purge Cache

# 5. Verify correct branch deployed
cd ~/TravelMemory
git branch
git log --oneline -5  # Show recent commits

# 6. Check file timestamps
ls -la ~/TravelMemory/frontend/build/index.html
# Should be recent

# 7. Verify build contents
cat ~/TravelMemory/frontend/build/index.html | head -20
```

### Issue 8.2: Can't connect to repository (GitHub)

**Symptoms**: "Permission denied" when running git pull

**Causes**:
- SSH key not set up on EC2
- GitHub SSH key not added
- Wrong permissions on key

**Solutions**:

```bash
# 1. Generate SSH key on EC2 (if not done)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# 2. Add SSH key to ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

# 3. Copy public key
cat ~/.ssh/id_rsa.pub

# 4. Add to GitHub
# GitHub → Settings → SSH and GPG keys → New SSH key
# Paste public key

# 5. Set proper permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# 6. Test GitHub connection
ssh -T git@github.com
# Should show: "Hi <username>! You've successfully authenticated..."

# 7. If still fails, use HTTPS with token
# Generate personal access token on GitHub
# Use in clone URL: https://token@github.com/user/repo.git

# 8. Clone with HTTPS
git clone https://github.com/UnpredictablePrashant/TravelMemory.git

# 9. Configure git credentials
git config --global credential.helper store
# Next push will prompt for password (use token)
```

---

## Section 9: General Debugging

### Enable Verbose Logging

**Backend**:
```javascript
// Add to index.js
const express = require('express');
const app = express();

// Log all requests
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path} from ${req.ip}`);
  next();
});

// Log request body for POST requests
app.use(express.json());
app.use((req, res, next) => {
  if (req.method === 'POST') {
    console.log('Request body:', req.body);
  }
  next();
});

// Log response
app.use((req, res, next) => {
  const originalSend = res.send;
  res.send = function(data) {
    console.log(`[${new Date().toISOString()}] Response: ${data?.substring?.(0, 100)}`);
    return originalSend.call(this, data);
  };
  next();
});
```

**Frontend**:
```javascript
// Add to React component
const baseUrl = process.env.REACT_APP_BACKEND_URL;
console.log('Backend URL:', baseUrl);

fetch(`${baseUrl}/trip`)
  .then(res => {
    console.log('Response status:', res.status);
    return res.json();
  })
  .then(data => {
    console.log('Response data:', data);
  })
  .catch(err => {
    console.error('Fetch error:', err);
  });
```

### Check System Resources

```bash
# Memory usage
free -h

# Disk usage
df -h

# CPU usage
top
uptime

# Network usage
nethogs  # If installed

# Listening ports
netstat -tuln
lsof -i -P -n | grep LISTEN

# Process list
ps aux
```

---

## Quick Reference Commands

```bash
# Backend
pm2 status                                    # Check PM2 processes
pm2 logs travel-memory-backend                # View backend logs
pm2 restart travel-memory-backend             # Restart backend
pm2 stop travel-memory-backend                # Stop backend
pm2 start index.js --name "travel-memory-backend"  # Start backend

# Frontend/Nginx
sudo systemctl status nginx                   # Check Nginx status
sudo systemctl restart nginx                  # Restart Nginx
sudo systemctl reload nginx                   # Reload Nginx config
sudo tail -f /var/log/nginx/error.log        # View Nginx errors
sudo tail -f /var/log/nginx/access.log       # View Nginx access

# Database
mongosh "mongodb+srv://user:pass@cluster.mongodb.net/dbname"  # Connect to MongoDB
db.trips.find({})                            # View all trips
db.trips.count()                             # Count documents

# Testing
curl http://localhost:3000/hello             # Test backend
curl http://localhost:3001/                  # Test frontend
curl -H "Host: yourdomain.com" http://alb-dns/  # Test through ALB
dig yourdomain.com                           # Check DNS
nslookup api.yourdomain.com                  # Check DNS

# System
ps aux | grep node                           # Find Node processes
ps aux | grep nginx                          # Find Nginx processes
netstat -tuln | grep 3000                    # Check port 3000
sudo lsof -i :3001                           # Check port 3001
top                                          # Monitor resources
free -h                                      # Check memory
df -h                                        # Check disk
```

---

**Last Updated**: April 25, 2026
**Version**: 1.0
**Status**: Ready for Reference
