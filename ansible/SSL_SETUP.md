# SSL Certificate Setup Guide

This guide explains how to set up free SSL certificates using Let's Encrypt for your Azure load balancer.

## 🔒 What This Does

The Ansible playbook will automatically:
1. Install Certbot (Let's Encrypt client)
2. Obtain a free SSL certificate for your domain
3. Configure Nginx with HTTPS (port 443)
4. Redirect HTTP to HTTPS
5. Set up automatic certificate renewal (every 90 days)

## 📋 Prerequisites

1. Your domain must be accessible via HTTP (port 80) - Azure NSG already allows this
2. DNS must point to your public IP (Azure FQDN already configured)
3. You need a valid email address for Let's Encrypt notifications

## 🚀 Quick Setup

### Step 1: Update Your Email

Edit the file: `group_vars/azure_proxy.yml`

```yaml
certbot_email: "junaid.sadiq009@gmail.com"  # ⚠️ CHANGE THIS!
```

Or the script will auto-update it, but you should manually set your email.

### Step 2: Run the Update Script

```bash
cd ansible
./update_inventory.sh
```

This automatically updates:
- Domain name from Terraform output
- Backend server IPs
- Ansible inventory

### Step 3: Update Email in group_vars

```bash
# Edit the file to add your real email
nano group_vars/azure_proxy.yml
# or
vim group_vars/azure_proxy.yml
```


To your actual email:
```yaml
certbot_email: "junaid.sadiq009@gmail.com"
```

### Step 4: Run Ansible Playbook

```bash
ansible-playbook pb.yml
```

## 🎯 What Happens During Installation

1. **Install packages**: Nginx, Certbot, Python3-certbot-nginx
2. **Temporary HTTP config**: Sets up basic HTTP server for verification
3. **Certificate request**: Certbot contacts Let's Encrypt and verifies domain ownership
4. **SSL configuration**: Nginx is reconfigured with HTTPS and security headers
5. **Auto-renewal**: Cron job set up to renew certificates automatically

## 🔍 Verification

After running the playbook:

### Test HTTP to HTTPS redirect:
```bash
curl -I http://nginx-lb-e9cx0pxb.westeurope.cloudapp.azure.com
# Should return: HTTP/1.1 301 Moved Permanently
# Location: https://...
```

### Test HTTPS:
```bash
curl https://nginx-lb-e9cx0pxb.westeurope.cloudapp.azure.com
# Should return content from backend servers
```

### Check SSL certificate:
```bash
openssl s_client -connect nginx-lb-e9cx0pxb.westeurope.cloudapp.azure.com:443 -servername nginx-lb-e9cx0pxb.westeurope.cloudapp.azure.com < /dev/null
```

### Test in browser:
Open: https://nginx-lb-e9cx0pxb.westeurope.cloudapp.azure.com

You should see:
- 🔒 Padlock icon (secure connection)
- Valid SSL certificate
- Content from backend servers

## 🛠️ Manual SSL Installation (Alternative)

If you prefer to install SSL manually:

### SSH to load balancer:
```bash
ssh -i ~/.ssh/azure_lb_key azureadmin@4.210.162.174
```

### Install Certbot:
```bash
sudo apt update
sudo apt install certbot python3-certbot-nginx -y
```

### Obtain certificate:
```bash
sudo certbot --nginx -d nginx-lb-e9cx0pxb.westeurope.cloudapp.azure.com
```

Follow the prompts:
- Enter your email
- Agree to terms
- Choose to redirect HTTP to HTTPS (recommended)

### Test auto-renewal:
```bash
sudo certbot renew --dry-run
```

## 🔄 Certificate Renewal

Certificates are automatically renewed via cron job:
- Runs daily at 3:00 AM
- Checks if certificate needs renewal (< 30 days until expiry)
- Automatically renews and reloads Nginx

### Check renewal status:
```bash
ssh -i ~/.ssh/azure_lb_key azureadmin@4.210.162.174
sudo certbot certificates
```

### Manual renewal:
```bash
sudo certbot renew
sudo systemctl reload nginx
```

## ⚙️ Configuration Options

### Disable SSL (for testing):

Edit `group_vars/azure_proxy.yml`:
```yaml
enable_ssl: false
```

Then run:
```bash
ansible-playbook pb.yml
```

This will configure HTTP-only load balancing.

### Use Custom Domain:

If you have your own domain (not Azure FQDN):

1. Point your domain's A record to: `4.210.162.174`
2. Update `group_vars/azure_proxy.yml`:
   ```yaml
   domain_name: "yourdomain.com"
   ```
3. Run: `ansible-playbook pb.yml`

## 🐛 Troubleshooting

### Certificate request fails:

**Check DNS resolution:**
```bash
nslookup nginx-lb-e9cx0pxb.westeurope.cloudapp.azure.com
```

**Check port 80 is accessible:**
```bash
curl http://nginx-lb-e9cx0pxb.westeurope.cloudapp.azure.com
```

**Check Nginx logs:**
```bash
ssh -i ~/.ssh/azure_lb_key azureadmin@4.210.162.174
sudo tail -f /var/log/nginx/error.log
```

**Check Certbot logs:**
```bash
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

### Rate limits:

Let's Encrypt has rate limits:
- 5 failed validations per hour
- 50 certificates per domain per week

If you hit limits, wait an hour and try again.

### Certificate not trusted:

Make sure you're using the correct domain name. Let's Encrypt only issues certificates for domains you can prove ownership of.

## 📁 File Locations

- **Certificates**: `/etc/letsencrypt/live/{{ domain_name }}/`
- **Nginx config**: `/etc/nginx/nginx.conf`
- **Nginx logs**: `/var/log/nginx/`
- **Certbot logs**: `/var/log/letsencrypt/`
- **Cron job**: `/etc/cron.d/` or `crontab -l`

## 🔐 Security Features

The SSL configuration includes:
- TLS 1.2 and 1.3 only
- Strong cipher suites
- HTTP Strict Transport Security (HSTS)
- X-Frame-Options header
- X-Content-Type-Options header
- X-XSS-Protection header

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review Ansible playbook output for errors
3. Check Nginx and Certbot logs
4. Verify DNS and firewall settings
