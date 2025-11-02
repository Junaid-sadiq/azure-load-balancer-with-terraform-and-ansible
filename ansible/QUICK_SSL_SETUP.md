# Quick SSL Setup - 3 Steps

## Step 1: Update Configuration
```bash
cd ansible
./update_inventory.sh
```

## Step 2: Set Your Email
```bash
# Edit this file
nano group_vars/azure_proxy.yml


# To your real email:
certbot_email: "junaid.sadiq009@gmail.com"
```

## Step 3: Run Ansible
```bash
# Install Ansible first if needed
pip3 install ansible
# or
brew install ansible

# Run the playbook
ansible-playbook pb.yml
```

## Test It
```bash
# Test HTTP redirect
curl -I http://nginx-lb-e9cx0pxb.westeurope.cloudapp.azure.com

# Test HTTPS
curl https://nginx-lb-e9cx0pxb.westeurope.cloudapp.azure.com

# Open in browser
open https://nginx-lb-e9cx0pxb.westeurope.cloudapp.azure.com
```

## What You Get
✅ Free SSL certificate from Let's Encrypt  
✅ HTTPS on port 443  
✅ HTTP to HTTPS redirect  
✅ Automatic certificate renewal  
✅ Security headers configured  
✅ Load balancing across 3 backend servers  

## Troubleshooting
If SSL fails, the playbook automatically falls back to HTTP-only mode.

Check logs:
```bash
ssh -i ~/.ssh/azure_lb_key azureadmin@4.210.162.174
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```
