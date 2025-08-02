# 9. Deployment & Hosting

Once you've created your Scriptorium site, you'll want to deploy it to make it accessible on the web. This section covers various deployment options, from local development to production hosting.

## Local Development

Before deploying to a server, you'll typically want to test your site locally to ensure everything works correctly.

### Local development server

Scriptorium generates static files that can be served by any web server. For local development:

1. **Generate your site**:
   ```bash
   scriptorium generate
   ```

2. **Start a local web server**:
   ```bash
   # Using Python (if available)
   cd output
   python -m http.server 8000
   
   # Using Ruby (if available)
   cd output
   ruby -run -e httpd . -p 8000
   
   # Using Node.js (if available)
   cd output
   npx serve -p 8000
   ```

3. **Access your site** at `http://localhost:8000`

### Live reload development

For a better development experience with automatic reloading:

1. **Install a live reload server**:
   ```bash
   # Using Node.js
   npm install -g live-server
   
   # Or using Python
   pip install livereload
   ```

2. **Start the development server**:
   ```bash
   cd output
   live-server --port=8000
   ```

3. **Your browser will automatically refresh** when you make changes to your site

### Testing different views

During development, you may want to test different views:

1. **Switch between views**:
   ```bash
   scriptorium view view-name
   ```

2. **Generate the specific view**:
   ```bash
   scriptorium generate
   ```

3. **Test the view** in your local development server

### Debugging local issues

Common local development issues and solutions:

- **Files not updating**: Ensure you're running `scriptorium generate` after changes
- **CSS not loading**: Check file paths and ensure CSS files are in the correct location
- **Images not displaying**: Verify image paths and file permissions
- **JavaScript errors**: Check browser console for errors and verify script paths

## Server Deployment

When you're ready to deploy your site to production, you have several hosting options available.

### Static hosting services

Static hosting services are ideal for Scriptorium sites since they generate static HTML files:

#### GitHub Pages

1. **Create a GitHub repository** for your site
2. **Push your Scriptorium repository** to GitHub:
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/username/repository-name.git
   git push -u origin main
   ```

3. **Enable GitHub Pages** in your repository settings
4. **Configure GitHub Actions** for automatic deployment (optional)

#### Netlify

1. **Sign up for Netlify** and connect your Git repository
2. **Configure build settings**:
   - Build command: `scriptorium generate`
   - Publish directory: `output`
3. **Deploy automatically** on every push to your repository

#### Vercel

1. **Sign up for Vercel** and import your Git repository
2. **Configure build settings**:
   - Build command: `scriptorium generate`
   - Output directory: `output`
3. **Deploy with automatic updates**

### Traditional web hosting

For traditional web hosting providers:

1. **Generate your site**:
   ```bash
   scriptorium generate
   ```

2. **Upload files** to your web server:
   ```bash
   # Using rsync (recommended)
   rsync -avz output/ user@your-server.com:/path/to/web/root/
   
   # Using scp
   scp -r output/* user@your-server.com:/path/to/web/root/
   
   # Using FTP/SFTP client
   # Upload all files from the output directory
   ```

3. **Set proper permissions**:
   ```bash
   chmod 644 output/*.html
   chmod 644 output/*.css
   chmod 644 output/*.js
   chmod 755 output/
   ```

### VPS deployment

For more control, deploy to a Virtual Private Server:

1. **Set up your VPS** with a web server (Apache, Nginx, etc.)
2. **Install required dependencies**:
   ```bash
   # Ubuntu/Debian
   sudo apt update
   sudo apt install nginx ruby ruby-dev
   
   # CentOS/RHEL
   sudo yum install nginx ruby ruby-devel
   ```

3. **Configure your web server** to serve static files
4. **Set up automatic deployment** with Git hooks or CI/CD

### Deployment automation

Automate your deployment process:

1. **Create a deployment script**:
   ```bash
   #!/bin/bash
   # deploy.sh
   
   # Generate the site
   scriptorium generate
   
   # Upload to server
   rsync -avz --delete output/ user@your-server.com:/path/to/web/root/
   
   # Clear cache (if using a CDN)
   # curl -X POST https://api.cloudflare.com/client/v4/zones/zone-id/purge_cache
   ```

2. **Make it executable**:
   ```bash
   chmod +x deploy.sh
   ```

3. **Run deployment**:
   ```bash
   ./deploy.sh
   ```

## Domain Configuration

Configure your domain name to point to your hosted site.

### DNS configuration

1. **Add DNS records** in your domain registrar's control panel:
   - **A record**: Point your domain to your server's IP address
   - **CNAME record**: Point `www` subdomain to your main domain
   - **MX records**: Configure email (if needed)

2. **Example DNS configuration**:
   ```
   Type    Name    Value
   A       @       192.168.1.100
   CNAME   www     yourdomain.com
   ```

### Subdomain setup

Set up subdomains for different sections of your site:

1. **Add subdomain DNS records**:
   ```
   Type    Name    Value
   A       blog    192.168.1.100
   A       docs    192.168.1.100
   ```

2. **Configure web server** to handle subdomains
3. **Set up separate Scriptorium repositories** for each subdomain (if needed)

### Domain verification

Verify your domain is properly configured:

1. **Check DNS propagation**:
   ```bash
   nslookup yourdomain.com
   dig yourdomain.com
   ```

2. **Test website accessibility**:
   ```bash
   curl -I http://yourdomain.com
   ```

3. **Check for redirects** and ensure they're working correctly

## SSL Setup

Secure your site with HTTPS using SSL certificates.

### Let's Encrypt (free SSL)

1. **Install Certbot**:
   ```bash
   # Ubuntu/Debian
   sudo apt install certbot python3-certbot-nginx
   
   # CentOS/RHEL
   sudo yum install certbot python3-certbot-nginx
   ```

2. **Obtain SSL certificate**:
   ```bash
   sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
   ```

3. **Auto-renewal setup**:
   ```bash
   sudo crontab -e
   # Add: 0 12 * * * /usr/bin/certbot renew --quiet
   ```

### Manual SSL certificate

For paid SSL certificates:

1. **Generate CSR (Certificate Signing Request)**:
   ```bash
   openssl req -new -newkey rsa:2048 -nodes -keyout yourdomain.key -out yourdomain.csr
   ```

2. **Submit CSR** to your certificate provider
3. **Install the certificate** on your web server
4. **Configure web server** to use SSL

### Web server SSL configuration

#### Nginx SSL configuration

```nginx
server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;
    
    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;
    
    location / {
        root /path/to/your/site;
        index index.html;
        try_files $uri $uri/ =404;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://$server_name$request_uri;
}
```

#### Apache SSL configuration

```apache
<VirtualHost *:443>
    ServerName yourdomain.com
    ServerAlias www.yourdomain.com
    
    SSLEngine on
    SSLCertificateFile /path/to/certificate.crt
    SSLCertificateKeyFile /path/to/private.key
    
    DocumentRoot /path/to/your/site
    
    <Directory /path/to/your/site>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>

# Redirect HTTP to HTTPS
<VirtualHost *:80>
    ServerName yourdomain.com
    ServerAlias www.yourdomain.com
    Redirect permanent / https://yourdomain.com/
</VirtualHost>
```

### SSL best practices

- **Use strong encryption**: Configure modern SSL protocols and ciphers
- **Enable HSTS**: Add HTTP Strict Transport Security headers
- **Regular renewal**: Set up automatic certificate renewal
- **Monitor certificate expiration**: Use monitoring tools to track certificate status
- **Backup certificates**: Keep secure backups of your SSL certificates and private keys

### Content Delivery Networks (CDN)

Improve site performance with a CDN:

1. **Choose a CDN provider** (Cloudflare, AWS CloudFront, etc.)
2. **Configure DNS** to point to CDN
3. **Set up caching rules** for static assets
4. **Configure SSL** through the CDN provider
5. **Monitor performance** and adjust settings as needed

### Deployment checklist

Before going live:

- [ ] Site generates without errors
- [ ] All links work correctly
- [ ] Images and assets load properly
- [ ] SSL certificate is installed and working
- [ ] Domain DNS is configured correctly
- [ ] Web server is configured properly
- [ ] Backup and recovery procedures are in place
- [ ] Monitoring and analytics are set up
- [ ] Error pages (404, 500) are configured
- [ ] Site is tested across different browsers and devices

Deploying your Scriptorium site can be as simple as uploading static files or as complex as setting up a full CI/CD pipeline. Choose the approach that best fits your needs, technical expertise, and budget. 