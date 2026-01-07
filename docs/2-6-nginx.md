Contributor: K Long

> **Tip**: If you are unfamiliar with Nginx configuration, you can use [DigitalOcean NginxConfig](https://nginxconfig.io/) to generate a base configuration.

HFish uses `TCP/4433` for the Web Interface/API and `TCP/4434` for Node communication. To use Nginx as a reverse proxy, you must proxy **both ports**.

Below are sample configurations.

#### Standard Configuration (Existing Certificate)

Use this if you already have SSL certificates.

```nginx
server {
    listen                  443 ssl http2;
    listen                  [::]:443 ssl http2;
    client_max_body_size    4G;                                     # Default is 1M, increase for large uploads
    server_name             domain.com;                             # Replace with your domain

    ssl_certificate         /etc/nginx/cert/domain.com.pem;         # Path to your certificate
    ssl_certificate_key     /etc/nginx/cert/domain.com.key;         # Path to your private key

    # Proxy Node Communication API
    location /api/v1 {
        proxy_pass https://127.0.0.1:4434$request_uri;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout              60s;
        proxy_send_timeout                 60s;
        proxy_read_timeout                 60s;
    }

    # Proxy Downloads
    location /tmp {
        proxy_pass https://127.0.0.1:4434$request_uri;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout              60s;
        proxy_send_timeout                 60s;
        proxy_read_timeout                 60s;
    }

    # Proxy Web Interface
    location / {
        proxy_pass https://127.0.0.1:4433$request_uri;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout              60s;
        proxy_send_timeout                 60s;
        proxy_read_timeout                 60s;
    }
}

# Redirect HTTP to HTTPS
server {
    listen      80;
    listen      [::]:80;
    server_name domain.com;
    location / {
        return 301 https://domain.com$request_uri;
    }
}
```

**Notes:**
* Replace `domain.com` with your actual domain.
* Place this file in `/etc/nginx/conf.d/` (e.g., `hfish.conf`).

#### Let's Encrypt Configuration

[Let's Encrypt](https://letsencrypt.org/) provides free, automated SSL/TLS certificates.

**1. Pre-requisites**
Create a temporary Nginx config to allow Certbot verification:

File: `/etc/nginx/conf.d/hfish.conf`
```nginx
server {
    listen      80;
    listen      [::]:80;
    server_name domain.com;

    # ACME Challenge for Let's Encrypt
    location ^~ /.well-known/acme-challenge/ {
        default_type "text/plain";
        root /;
    }
}
```

Reload Nginx:
```bash
nginx -t && systemctl restart nginx
```

**2. Install Certbot**

```bash
# Ubuntu/Debian
apt install certbot

# CentOS/RHEL
yum install certbot
```

**3. Generate Certificate**

```bash
certbot certonly --webroot -w / -d domain.com
```
*Note: We used `root /` in the Nginx config, so `-w /` tells Certbot to use the root directory for validation.*

**4. Final Configuration**
After successfully generating certificates (usually in `/etc/letsencrypt/live/domain.com/`), replace the content of `/etc/nginx/conf.d/hfish.conf` with the full SSL configuration below:

```nginx
server {
    listen                  443 ssl http2;
    listen                  [::]:443 ssl http2;
    client_max_body_size    4G;
    server_name             domain.com;

    ssl_certificate         /etc/letsencrypt/live/domain.com/fullchain.pem;
    ssl_certificate_key     /etc/letsencrypt/live/domain.com/privkey.pem;

    # ... Include the same location blocks (/api/v1, /tmp, /) as the Standard Configuration above ...
    
    # (Repeated for brevity: /api/v1, /tmp proxies to 4434; / proxies to 4433)
    # See Standard Configuration for details.
}

server {
    listen      80;
    listen      [::]:80;
    server_name domain.com;

    location ^~ /.well-known/acme-challenge/ {
        default_type "text/plain";
        root /;
    }

    location / {
        return 301 https://domain.com$request_uri;
    }
}
```

Reload Nginx:
```bash
nginx -t && systemctl restart nginx
```

#### Automatic Certificate Renewal

Edit crontab:
```bash
crontab -e
```

Add the following line to renew certificates automatically (e.g., on the 1st of every month):
```bash
0 0 1 * * certbot renew --force-renewal && systemctl restart nginx
```

#### Nginx Basic Auth (Optional Security)

You can add Basic Auth to the Web Interface to hide the login page from scanners.

**1. Install Utilities**
```bash
# Ubuntu
apt install apache2-utils
# CentOS
yum install httpd-tools
```

**2. Generate Password File**
```bash
htpasswd -c /etc/nginx/.htpasswd myuser
# Enter password when prompted
```

**3. Update Nginx Config**
Add the `auth_basic` lines to the root location block:

```nginx
    location / {
        proxy_pass https://127.0.0.1:4433$request_uri;
        # ... other headers ...
        
        auth_basic "Restricted Access";
        auth_basic_user_file /etc/nginx/.htpasswd;
    }
```
