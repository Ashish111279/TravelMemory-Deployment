# GitHub Push Instructions

## Step 1: Create Repository on GitHub
Visit: https://github.com/new

Repository Details:
- Name: TravelMemory-Deployment
- Description: Complete deployment documentation and scripts for Travel Memory MERN stack on AWS EC2 with Cloudflare DNS
- Visibility: Public
- Do NOT initialize with README

## Step 2: After Creating Repository on GitHub

Copy the HTTPS URL provided by GitHub (looks like):
https://github.com/Ashish111279/TravelMemory-Deployment.git

## Step 3: Run These Commands in Terminal

```bash
cd "C:\Users\Pramod Singh\TravelMemory-Deployment"

# Add GitHub repository as remote
git remote add origin https://github.com/Ashish111279/TravelMemory-Deployment.git

# Verify remote is added
git remote -v

# Push to GitHub
git push -u origin master

# Or if your default branch is 'main':
git push -u origin main

# Verify push was successful
git log --oneline
```

## Step 4: Share Repository Link

Once pushed, your repository link will be:
https://github.com/Ashish111279/TravelMemory-Deployment

Use this link for your Vlearn submission!

---

If you encounter authentication errors, you have two options:

### Option A: Use Personal Access Token (Recommended)
1. Generate token: https://github.com/settings/tokens
2. Use as password when prompted

### Option B: Configure Git Credentials
```bash
git config --global credential.helper wincred
```

---

**Next**: Create the repo on GitHub, then we'll push!
