# Cloudflare DNS Configuration Guide

## Complete Guide to Setting Up Cloudflare for Travel Memory

---

## Overview

Cloudflare provides:
- DNS management
- DDoS protection
- SSL/TLS certificates
- CDN for static assets
- Web Application Firewall (WAF)
- Performance optimization

---

## Step 1: Create Cloudflare Account

1. Go to https://dash.cloudflare.com
2. Click "Sign up"
3. Enter email and password
4. Verify email
5. Select Free plan

---

## Step 2: Add Your Domain to Cloudflare

1. Log in to Cloudflare dashboard
2. Click "Add a site" or "Add domain"
3. Enter your domain name (e.g., yourdomain.com)
4. Select **Free** plan
5. Click "Continue"
6. Cloudflare will scan your existing DNS records
7. **Update your nameservers** at your domain registrar:
   - Remove existing nameservers
   - Add Cloudflare nameservers (provided by Cloudflare):
     - ns1.cloudflare.com
     - ns2.cloudflare.com
     - (Cloudflare shows 2 nameservers)

**Note**: DNS propagation takes 24-48 hours

---

## Step 3: Create DNS Records

### Record 1: A Record for Frontend

| Field | Value |
|-------|-------|
| Type | A |
| Name | yourdomain.com |
| IPv4 address | <FRONTEND_EC2_ELASTIC_IP> |
| TTL | Auto |
| Proxy status | Proxied (Orange Cloud) |

**Steps:**
1. Go to DNS → Records
2. Click "+ Create record"
3. Select Type: A
4. Name: yourdomain.com (or @)
5. IPv4 address: <YOUR_FRONTEND_ELASTIC_IP>
6. TTL: Auto
7. Proxy status: Proxied (orange cloud)
8. Click Save

### Record 2: CNAME Record for Backend API

| Field | Value |
|-------|-------|
| Type | CNAME |
| Name | api.yourdomain.com |
| Target | <ALB_DNS_NAME> |
| TTL | Auto |
| Proxy status | Proxied (Orange Cloud) |

**Steps:**
1. Click "+ Create record"
2. Select Type: CNAME
3. Name: api.yourdomain.com
4. Target: <YOUR_ALB_DNS_NAME>.us-east-1.elb.amazonaws.com
5. TTL: Auto
6. Proxy status: Proxied (orange cloud)
7. Click Save

### Record 3: CNAME Record for WWW

| Field | Value |
|-------|-------|
| Type | CNAME |
| Name | www |
| Target | yourdomain.com |
| TTL | Auto |
| Proxy status | Proxied (Orange Cloud) |

**Steps:**
1. Click "+ Create record"
2. Select Type: CNAME
3. Name: www
4. Target: yourdomain.com (or @)
5. TTL: Auto
6. Proxy status: Proxied (orange cloud)
7. Click Save

### Record 4: MX Record (Optional - for email)

| Field | Value |
|-------|-------|
| Type | MX |
| Name | yourdomain.com |
| Mail server | mail.yourdomain.com |
| Priority | 10 |
| TTL | Auto |

---

## Step 4: SSL/TLS Configuration

### Enable HTTPS

1. Go to **SSL/TLS** → **Edge Certificates**
2. **Encryption mode**: Select "Full (strict)"
   - Full: Uses certificates even if origin isn't trusted
   - Full (strict): Origin must have valid certificate
3. **Enable**:
   - "Automatic HTTPS Rewrites" ✓
   - "Always Use HTTPS" ✓

### Configure SSL Policies

1. Go to **SSL/TLS** → **Settings**
2. **TLS Version**: 
   - Minimum: TLS 1.2
   - Maximum: TLS 1.3
3. **HSTS (HTTP Strict Transport Security)**:
   - Enable HSTS
   - Max Age: 12 months
   - Include subdomains: Yes
   - Preload: Yes

---

## Step 5: Firewall and Security

### Enable DDoS Protection

1. Go to **Security** → **DDoS**
2. Leave on default "Managed" setting
3. Cloudflare automatically protects from DDoS attacks

### Configure Firewall Rules

1. Go to **Security** → **Settings**
2. **Challenge (CAPTCHA)**:
   - Sensitivity: Medium to High
   - Challenge passage: 30 minutes
3. **Security Level**: High

### WAF (Web Application Firewall)

1. Go to **Security** → **WAF**
2. Enable **OWASP ModSecurity Core Rule Set**
3. Set sensitivity: Medium

### Rate Limiting (Optional but Recommended)

1. Go to **Security** → **Rate Limiting**
2. Click "+ Create rule"
3. **Example rule** to protect API:
   - Request rate: 50 requests per 10 seconds
   - Path: /api/*
   - Action: Challenge (CAPTCHA)

---

## Step 6: Performance Optimization

### Enable Caching

1. Go to **Caching** → **Cache Rules**
2. Create rule for static assets:
   - **Criteria**: File extension matches (js, css, jpg, png, gif)
   - **Cache level**: Cache everything
   - **Browser cache TTL**: 1 year

### Optimize Images

1. Go to **Speed** → **Optimization**
2. Enable:
   - Polish: Enable (free plan)
   - Rocket Loader: Enable
   - Mirage: Enable (optional)
   - Minify HTML/CSS/JS: Enable

### Enable HTTP/2

1. Go to **Speed** → **HTTP/2**
2. Enable HTTP/2 Push (automatic)

### Content Delivery Network (CDN)

- Cloudflare automatically caches and serves from nearest data center
- No additional configuration needed for free plan

---

## Step 7: Verify DNS Setup

### Method 1: Using nslookup
```bash
nslookup yourdomain.com
# Should show Cloudflare nameservers

nslookup api.yourdomain.com
# Should return ALB IP
```

### Method 2: Using dig
```bash
dig yourdomain.com
# Check for Cloudflare nameservers in response

dig api.yourdomain.com
# Check for CNAME record
```

### Method 3: Using Cloudflare Dashboard

1. Go to **DNS** → **Records**
2. Verify all records show "Proxied" (orange cloud)
3. Check Status column for green checkmarks

### Method 4: Browser Test

1. Open browser
2. Navigate to https://yourdomain.com
3. Should load your frontend
4. Open browser console (F12)
5. Check Network tab for requests going through Cloudflare

---

## Step 8: Monitor and Analyze

### View Traffic Analytics

1. Go to **Analytics & Logs** → **Analytics**
2. View:
   - Total requests
   - Bandwidth saved
   - Security events
   - Bot traffic

### Check Security Events

1. Go to **Analytics & Logs** → **Security Events**
2. View blocked/challenged requests
3. Review patterns

### View Page Rules (Legacy)

If using older Cloudflare account, go to **Page Rules** to configure advanced rules

---

## DNS Record Examples

### Complete Example Setup

```
Record Type   Name                  Target/IP              Proxy Status
A             yourdomain.com        1.2.3.4 (Frontend)     Proxied
A             @                     1.2.3.4                Proxied
CNAME         api                   alb-xxx.elb.amazonaws  Proxied
CNAME         www                   yourdomain.com         Proxied
MX            yourdomain.com        mail.yourdomain.com    DNS only
TXT           yourdomain.com        v=spf1 ...            DNS only
```

---

## Common DNS Issues and Solutions

### Problem: Domain not resolving

**Solution:**
```bash
# Check nameserver propagation
nslookup yourdomain.com

# Expected result: Cloudflare nameservers

# If still using old nameservers:
1. Check domain registrar settings
2. Wait up to 48 hours for propagation
3. Use https://www.whatsmydns.net to check global propagation
```

### Problem: HTTPS certificate issues

**Solution:**
1. Go to SSL/TLS → Overview
2. Check certificate status
3. Ensure encryption mode is "Full (strict)"
4. Wait 5 minutes for certificate issuance
5. Clear browser cache: Ctrl+Shift+Delete

### Problem: API not accessible at api.yourdomain.com

**Solution:**
```bash
# Verify CNAME record
dig api.yourdomain.com

# Should show CNAME pointing to ALB

# Check ALB is working
curl http://<ALB_DNS_NAME>

# Verify ALB security group allows traffic from Cloudflare IPs
# See: https://www.cloudflare.com/ips/
```

### Problem: Slow performance

**Solution:**
1. Go to **Speed** → **Optimization**
2. Enable all optimization options
3. Enable Polish (compress images)
4. Enable Rocket Loader
5. Check cache settings in **Caching** → **Cache Rules**

---

## Cloudflare Features by Plan

| Feature | Free | Pro | Business |
|---------|------|-----|----------|
| Basic DNS | ✓ | ✓ | ✓ |
| DDoS Protection | ✓ | ✓ | ✓ |
| SSL/TLS | ✓ | ✓ | ✓ |
| CDN | ✓ | ✓ | ✓ |
| WAF | - | ✓ | ✓ |
| Advanced Rate Limiting | - | ✓ | ✓ |
| Page Rules | 3 | 20 | 125 |
| Page Caching | ✓ | ✓ | ✓ |
| Image Optimization (Polish) | Basic | Advanced | Advanced |
| Cost | Free | $20/month | $200/month |

**Recommendation**: Start with Free plan for testing, upgrade to Pro for production.

---

## Best Practices

1. **Always use HTTPS**: Enable "Always Use HTTPS" in SSL/TLS settings
2. **Enable HSTS**: Prevent SSL stripping attacks
3. **Monitor security events**: Check Analytics for threats
4. **Regular backups**: Keep backups of DNS configuration
5. **Test DNS changes**: Use nslookup/dig before going live
6. **Enable DDoS protection**: Cloudflare automatically protects
7. **Use rate limiting**: Prevent API abuse
8. **Cache static assets**: Reduce server load

---

## API Integration Example

### Fetch data from backend through Cloudflare

```javascript
// Frontend code (React)
const baseUrl = process.env.REACT_APP_BACKEND_URL || "http://localhost:3000";

fetch(`${baseUrl}/trip`)
  .then(res => res.json())
  .then(data => console.log(data))
  .catch(err => console.error(err));

// .env file should have:
// REACT_APP_BACKEND_URL=https://api.yourdomain.com
```

---

## Rollback Procedure

If you need to revert to original nameservers:

1. Log in to domain registrar
2. Update nameservers back to original:
   - Note: Your original nameservers (from registrar)
3. Go to Cloudflare dashboard
4. Note → Remove site (optional)
5. Wait 24-48 hours for propagation

---

## Advanced Topics

### Custom Nameservers (Enterprise)

Available only on Business/Enterprise plans:
- Use your own nameservers
- DNSSEC signing
- Advanced zone management

### API Documentation

Cloudflare provides REST API for programmatic DNS management:
- API Docs: https://developers.cloudflare.com/api/
- Get API token from Account Settings
- Use for automation and CI/CD

### Terraform Configuration

```hcl
resource "cloudflare_zone" "example" {
  zone = "yourdomain.com"
  plan = "free"
}

resource "cloudflare_record" "example" {
  zone_id = cloudflare_zone.example.id
  name    = "api"
  type    = "CNAME"
  value   = "your-alb.us-east-1.elb.amazonaws.com"
  proxied = true
}
```

---

## Support Resources

- Cloudflare Documentation: https://developers.cloudflare.com/
- Cloudflare Community: https://community.cloudflare.com/
- Status Page: https://www.cloudflarestatus.com/
- Support Portal: https://dash.cloudflare.com/support

---

**Last Updated**: April 25, 2026
**Status**: Ready for Production
