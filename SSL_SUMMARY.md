# SSL Certificate Setup - Summary

## ✅ What's Been Configured

Your Ansible playbook now automatically installs SSL certificates!

### Features Added:
1. **Let's Encrypt Integration** - Free SSL certificates
2. **Automatic Installation** - Certbot installs and configures everything
3. **HTTPS Support** - Port 443 with strong security settings
4. **HTTP Redirect** - Automatically redirects HTTP to HTTPS
5. **Auto-Renewal** - Certificates renew automatically every 90 days
6. **Security Headers** - HSTS, X-Frame-Options, etc.

## 🚀 How to Use

### Option 1: Automatic (Recommended)

```bash
# 1. Update inventory and configs
cd ansible
./update_inventory.sh

# 2. Edit your email
nano group_vars/azure_proxy.yml
# Change: certbot_email: "your-email@example.com"

# 3. Run playbook
ansible-playbook pb.yml
```

### Option 2: Disable SSL (HTTP only)

Edit `group_vars/azure_proxy.yml`:
```yaml
enable_ssl: false
```

Then run: `ansible-playbook pb.yml`

## 📋 Files Created/Modified

### New Files:
- `ansible/templates/nginx_http_temp.conf.j2` - Temporary HTTP config for verification
- `ansible/templates/nginx_proxy_ssl.conf.j2` - Final HTTPS config with SSL
- `ansible/group_vars/azure_proxy.yml` - Variables (domain, email, backend IPs)
- `ansible/SSL_SETUP.md` - Detailed SSL setup guide
- `ansible/QUICK_SSL_SETUP.md` - Quick reference guide

### Modified Files:
- `ansible/pb.yml` - Updated with SSL installation tasks
- `ansible/update_inventory.sh` - Now updates group_vars with domain/IPs

## 🔍 How It Works

1. **Playbook runs** → Installs Nginx, Certbot, Python3-certbot-nginx
2. **Temporary HTTP config** → Allows Let's Encrypt to verify domain ownership
3. **Certbot requests certificate** → Contacts Let's Encrypt API
4. **Domain verification** → Let's Encrypt checks HTTP endpoint
5. **Certificate issued** → Saved to `/etc/letsencrypt/live/`
6. **Final HTTPS config** → Nginx reconfigured with SSL
7. **Cron job created** → Auto-renewal every 90 days

## 🌐 Your URLs

**HTTP (redirects to HTTPS):**
- http://4.210.162.174
- http://nginx-lb-e9cx0pxb.westeurope.cloudapp.azure.com

**HTTPS (secure):**
- https://4.210.162.174
- https://nginx-lb-e9cx0pxb.westeurope.cloudapp.azure.com

## 🔐 Security Features

- **TLS 1.2 & 1.3** only
- **Strong ciphers** - No weak encryption
- **HSTS** - Forces HTTPS for 1 year
- **Security headers** - XSS, clickjacking protection
- **Auto-renewal** - Never expires

## 📊 Certificate Info

- **Issuer**: Let's Encrypt
- **Validity**: 90 days
- **Renewal**: Automatic (30 days before expiry)
- **Cost**: FREE
- **Type**: Domain Validated (DV)

## 🛠️ Troubleshooting

### If SSL installation fails:
- Playbook automatically falls back to HTTP-only
- Check: `sudo tail -f /var/log/letsencrypt/letsencrypt.log`
- Verify DNS: `nslookup nginx-lb-e9cx0pxb.westeurope.cloudapp.azure.com`
- Test HTTP: `curl http://nginx-lb-e9cx0pxb.westeurope.cloudapp.azure.com`

### Rate limits:
Let's Encrypt limits:
- 5 failed validations per hour
- 50 certificates per domain per week

If you hit limits, wait and try again.

## 📞 Next Steps

1. **Install Ansible** (if not installed):
   ```bash
   pip3 install ansible
   # or
   brew install ansible
   ```

2. **Update your email** in `group_vars/azure_proxy.yml`

3. **Run the playbook**:
   ```bash
   cd ansible
   ansible-playbook pb.yml
   ```

4. **Test HTTPS**:
   ```bash
   curl https://nginx-lb-e9cx0pxb.westeurope.cloudapp.azure.com
   ```

5. **Open in browser** and verify the 🔒 padlock icon

## 📚 Documentation

- **Quick Start**: `ansible/QUICK_SSL_SETUP.md`
- **Detailed Guide**: `ansible/SSL_SETUP.md`
- **Ansible README**: `ansible/README.md`
- **Main README**: `terraform/README.md`
