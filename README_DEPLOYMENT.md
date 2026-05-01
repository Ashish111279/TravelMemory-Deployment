# Travel Memory MERN Stack - Deployment Documentation

Complete deployment documentation and guides for the Travel Memory MERN application on AWS EC2 with Cloudflare DNS.

## Repository Purpose

This repository contains comprehensive documentation, configuration files, and deployment scripts for deploying the Travel Memory application on AWS EC2 instances with proper load balancing, DNS configuration via Cloudflare, and production-ready security.

## Contents

### Documentation Files

1. **[DEPLOYMENT_DOCUMENTATION.md](DEPLOYMENT_DOCUMENTATION.md)** - Main deployment guide
   - Complete step-by-step deployment procedures
   - Local development setup
   - AWS EC2 configuration
   - Backend deployment (Node.js)
   - Frontend deployment (React + Nginx)
   - Nginx reverse proxy setup
   - Load balancer configuration
   - Cloudflare DNS setup
   - Monitoring and maintenance

2. **[AWS_DEPLOYMENT_GUIDE.md](AWS_DEPLOYMENT_GUIDE.md)** - AWS-specific setup guide
   - EC2 instance creation and configuration
   - SSH access and connection
   - Backend deployment procedures
   - Frontend deployment procedures
   - Application Load Balancer (ALB) setup
   - Security group configuration
   - Elastic IP allocation
   - Cost optimization tips

3. **[CLOUDFLARE_DNS_SETUP.md](CLOUDFLARE_DNS_SETUP.md)** - DNS configuration guide
   - Cloudflare account setup
   - DNS record creation (A, CNAME)
   - SSL/TLS configuration
   - Firewall and security rules
   - DDoS protection setup
   - Rate limiting configuration
   - Performance optimization

4. **[ARCHITECTURE_GUIDE.md](ARCHITECTURE_GUIDE.md)** - System architecture documentation
   - Architecture diagrams (ASCII)
   - Component descriptions
   - Data flow diagrams
   - Scaling strategies
   - Disaster recovery procedures
   - Performance optimization
   - Security layers
   - Cost analysis

5. **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)** - Complete deployment checklist
   - Pre-deployment verification
   - Phase-by-phase checklist (10 phases)
   - Task verification for each step
   - Post-deployment monitoring
   - Maintenance schedules

6. **[TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md)** - Comprehensive troubleshooting
   - SSH connection issues
   - Backend issues and solutions
   - Frontend/Nginx issues
   - DNS and Cloudflare issues
   - Load balancer troubleshooting
   - MongoDB connection issues
   - Performance optimization
   - Debug commands reference

### Configuration Files

- **nginx-backend.conf** - Nginx reverse proxy for backend API
- **nginx-frontend.conf** - Nginx reverse proxy for frontend React app
- **.env** - Environment variables templates

### Deployment Scripts

- **deploy-backend.sh** - Automated backend deployment script
- **deploy-frontend.sh** - Automated frontend deployment script

## Quick Start Deployment

### Step 1: Initial Setup
```bash
# 1. Clone the original Travel Memory repository
git clone https://github.com/UnpredictablePrashant/TravelMemory.git

# 2. Review documentation
# Start with: DEPLOYMENT_DOCUMENTATION.md

# 3. Create MongoDB Atlas database
# Visit: https://www.mongodb.com/cloud/atlas
```

### Step 2: AWS Setup
```bash
# 1. Launch EC2 instances (backend and frontend)
# See: AWS_DEPLOYMENT_GUIDE.md

# 2. Configure security groups
# See: AWS_DEPLOYMENT_GUIDE.md - Security Group Configuration

# 3. Create Application Load Balancer
# See: DEPLOYMENT_DOCUMENTATION.md - Load Balancer Configuration
```

### Step 3: Backend Deployment
```bash
# SSH into backend EC2 instance
ssh -i your-key.pem ubuntu@<BACKEND_IP>

# Download and run deployment script
cd ~
wget https://raw.githubusercontent.com/Ashish111279/TravelMemory-Deployment/main/deploy-backend.sh
chmod +x deploy-backend.sh
./deploy-backend.sh

# Update environment variables
sudo nano ~/TravelMemory/backend/.env
# Add MongoDB credentials
```

### Step 4: Frontend Deployment
```bash
# SSH into frontend EC2 instance
ssh -i your-key.pem ubuntu@<FRONTEND_IP>

# Download and run deployment script
cd ~
wget https://raw.githubusercontent.com/Ashish111279/TravelMemory-Deployment/main/deploy-frontend.sh
chmod +x deploy-frontend.sh
./deploy-frontend.sh

# Update backend URL
sudo nano ~/TravelMemory/frontend/.env
```

### Step 5: Cloudflare DNS Setup
```bash
# 1. Add domain to Cloudflare
# Visit: https://dash.cloudflare.com

# 2. Create DNS records:
# - A Record: yourdomain.com → Frontend EC2 IP
# - CNAME Record: api.yourdomain.com → ALB DNS
# - CNAME Record: www → yourdomain.com

# 3. Update nameservers at domain registrar

# See: CLOUDFLARE_DNS_SETUP.md for detailed instructions
```

## Architecture Overview

```
┌─────────────────┐
│  User Browser   │
└────────┬────────┘
         │
    ┌────▼────────────────────┐
    │    Cloudflare DNS       │
    │  DDoS + CDN + SSL/TLS   │
    └────┬────────────────────┘
         │
    ┌────┴──────────────────────┬──────────────────────┐
    │                           │                      │
┌───▼────┐            ┌────────▼────────┐      ┌──────▼──────┐
│Frontend │            │  AWS ALB        │      │   Static    │
│   EC2   │            │ (Load Balancer) │      │   Content   │
│ (React) │            └────────┬────────┘      └─────────────┘
└───┬────┘                      │
    │                    ┌──────┴──────┐
    │                    │             │
 ┌──▼──┐          ┌─────▼──┐   ┌─────▼──┐
 │Nginx │          │Backend │   │Backend │
 │3001  │          │Node.js │   │Node.js │
 └──────┘          │3000    │   │3000    │
                   └─────┬──┘   └───┬────┘
                         │         │
                    ┌────▼─────────▼────┐
                    │  MongoDB Atlas    │
                    │  (Database)       │
                    └───────────────────┘
```

## Deployment Phases

### Phase 1: AWS Infrastructure
- Launch EC2 instances
- Configure security groups
- Create VPC and subnets
- Allocate Elastic IPs

### Phase 2: Backend Deployment
- Install Node.js
- Deploy application
- Configure environment
- Set up PM2 process manager

### Phase 3: Frontend Deployment
- Install Node.js
- Build React application
- Install Nginx
- Configure server

### Phase 4: Load Balancing
- Create target groups
- Set up ALB
- Configure routing rules
- Register instances

### Phase 5: DNS Configuration
- Add domain to Cloudflare
- Create DNS records
- Configure SSL/TLS
- Set up security rules

### Phase 6-10: Testing, Monitoring, and Production

## Requirements

### AWS
- EC2 instances (minimum 2: 1 backend, 1 frontend)
- Application Load Balancer
- Security Groups
- VPC (can use default)
- Elastic IPs (optional but recommended)

### Services
- MongoDB Atlas (free tier available)
- Cloudflare (free tier available)
- GitHub (for code hosting)
- Custom domain name

### Software
- Node.js v16+
- npm v7+
- Git
- Nginx
- PM2

## Estimated Costs

### First 12 Months (Free Tier)
- 2x t2.micro EC2 instances: $0
- MongoDB Atlas free: $0
- Cloudflare free: $0
- **Total: $0**

### Production Setup (Monthly)
- 4x t2.small EC2 instances: ~$40
- ALB: ~$20 + data processing
- MongoDB Atlas M10: ~$57
- Data transfer: ~$10
- Cloudflare Pro: $20
- **Total: ~$150-200/month**

## Security Considerations

- SSH access restricted to specific IPs
- Security groups properly configured
- HTTPS/SSL/TLS enabled
- MongoDB IP whitelist configured
- Cloudflare DDoS protection active
- Regular backups enabled
- Monitoring and alerting configured

## Performance Metrics

Target metrics:
- Page load time: < 2 seconds
- API response time: < 500ms
- Server uptime: 99.9%
- Database query time: < 200ms

## Monitoring

- AWS CloudWatch for EC2 and ALB metrics
- PM2 Plus for application monitoring (optional)
- Cloudflare Analytics for CDN and security
- Application logs in PM2 and Nginx

## Support and Troubleshooting

Comprehensive troubleshooting guide available in [TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md)

Common issues covered:
- SSH connection errors
- Backend deployment issues
- Frontend/Nginx problems
- DNS configuration issues
- Load balancer troubleshooting
- MongoDB connection errors
- Performance optimization

## Deployment Verification

After deployment, verify:
- [ ] Frontend accessible at https://yourdomain.com
- [ ] API accessible at https://api.yourdomain.com
- [ ] No SSL/TLS certificate warnings
- [ ] API calls working from frontend
- [ ] Database data displaying in UI
- [ ] Load balancer distributing traffic
- [ ] All instances healthy in ALB
- [ ] CloudWatch monitoring active

## Next Steps

1. **Read** [DEPLOYMENT_DOCUMENTATION.md](DEPLOYMENT_DOCUMENTATION.md) completely
2. **Review** [AWS_DEPLOYMENT_GUIDE.md](AWS_DEPLOYMENT_GUIDE.md) for AWS setup
3. **Use** [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md) to track progress
4. **Reference** [TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md) if issues occur
5. **Follow** [CLOUDFLARE_DNS_SETUP.md](CLOUDFLARE_DNS_SETUP.md) for DNS configuration

## Git Repository Setup

To create your own deployment repository:

```bash
# 1. Create new repository on GitHub
# Visit: https://github.com/new

# 2. Clone this deployment repo locally
git clone https://github.com/Ashish111279/TravelMemory-Deployment.git

# 3. Create your own repository
git remote add your-repo https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push your-repo main

# 4. Update deployment scripts with your repo URLs
```

## Submission Instructions

To submit your assignment:

1. **Create a new GitHub repository** with all deployment documentation
2. **Include**:
   - All markdown documentation files
   - Configuration files (nginx, .env templates)
   - Deployment scripts (deploy-backend.sh, deploy-frontend.sh)
   - A complete README with setup instructions
   - Screenshots of successful deployment (add to README)
   - Architecture diagram (link to draw.io or image)

3. **Document**:
   - All steps taken for deployment
   - Screenshots at each stage
   - Issues encountered and resolutions
   - Final working application URL
   - DNS configuration details

4. **Submit via Vlearn**:
   - Create a text, Word, or PDF file
   - Include your repository link
   - Add any relevant notes or comments
   - Submit to assignment portal

## Architecture Diagram

To create a visual diagram:

1. Visit https://www.draw.io
2. Create new diagram
3. Use the ASCII diagram in [ARCHITECTURE_GUIDE.md](ARCHITECTURE_GUIDE.md) as reference
4. Export as PNG/PDF
5. Add to README

## Additional Resources

- [TravelMemory Original Repository](https://github.com/UnpredictablePrashant/TravelMemory)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [Cloudflare Documentation](https://developers.cloudflare.com/)
- [MongoDB Atlas Documentation](https://docs.atlas.mongodb.com/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [PM2 Documentation](https://pm2.keymetrics.io/)

## Contributing

Feel free to improve this documentation:

1. Fork the repository
2. Create a new branch
3. Make improvements
4. Submit a pull request

## License

This deployment documentation is provided as-is for educational purposes.

## Contact & Support

For issues or questions:
- Check [TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md)
- Review relevant documentation sections
- Create an issue in this repository

## Version History

- **v1.0** (April 25, 2026) - Initial comprehensive deployment documentation
  - Complete deployment guide
  - AWS setup procedures
  - Cloudflare DNS configuration
  - Troubleshooting guide
  - Deployment checklist
  - Automated scripts
  - Architecture documentation

---

**Last Updated**: April 25, 2026  
**Status**: Production Ready  
**Maintained by**: Pramod Singh (pramodsingh3503@gmail.com)

For the most up-to-date information, visit: https://github.com/Ashish111279/TravelMemory-Deployment
