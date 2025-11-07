# OmniDB Subdomain Configuration

## Overview

Starting with this version, OmniDB is configured to run on a subdomain (e.g., `omnidb.yourdomain.com`) instead of a path-based URL (`yourdomain.com/omnidb/`). This provides better URL isolation and a cleaner routing structure.

## Changes Made

1. **OmniDB WSGI Configuration** (`omnidb/wsgi.py`)
   - Changed `custom_settings.PATH` from `/omnidb/` to `/`
   - OmniDB now serves from the root path on its subdomain

2. **Apache VirtualHost** (`portal/omnidb-subdomain.conf`)
   - New Apache configuration file for OmniDB subdomain
   - Handles both HTTP (redirects to HTTPS) and HTTPS traffic
   - Configured with proper authentication and SSL

3. **Portal Homepage** (`portal/template/portalmain.html`)
   - Updated OmniDB link to use subdomain routing
   - Falls back to path-based routing if subdomain is not configured

4. **Portal CGI Script** (`portal/cgi-bin/portalmain.pl`)
   - Extracts base domain from `SERVER_NAME`
   - Constructs OmniDB subdomain URL dynamically
   - Passes the subdomain URL to the template

## Setup Instructions

### Production Environment

1. **DNS Configuration**
   - Add an A record for `omnidb.yourdomain.com` pointing to your server's IP address
   - Or configure a wildcard subdomain `*.yourdomain.com` to point to your server

2. **Apache Configuration**
   - Copy `portal/omnidb-subdomain.conf` to `/etc/apache2/sites-available/`
   - **IMPORTANT**: Edit the configuration file and replace `omnidb.localhost` with your actual domain (e.g., `omnidb.yourdomain.com`)
   - Enable the site:
     ```bash
     sudo a2ensite omnidb-subdomain.conf
     ```
   - Reload Apache:
     ```bash
     sudo systemctl reload apache2
     ```

3. **SSL Certificate**
   - **CRITICAL**: Replace the self-signed certificate with a proper SSL certificate before deploying to production
   - Update the paths in `omnidb-subdomain.conf`:
     - `SSLCertificateFile`
     - `SSLCertificateKeyFile`
   - Consider using Let's Encrypt for free SSL certificates:
     ```bash
     sudo certbot --apache -d omnidb.yourdomain.com
     ```

### Local Development / Testing

For local development, you need to configure your hosts file:

1. **Linux/Mac** - Edit `/etc/hosts`:
   ```
   127.0.0.1   localhost
   127.0.0.1   omnidb.localhost
   ```

2. **Windows** - Edit `C:\Windows\System32\drivers\etc\hosts`:
   ```
   127.0.0.1   localhost
   127.0.0.1   omnidb.localhost
   ```

3. **Access the applications**:
   - Main portal: `http://localhost/` or `https://localhost/`
   - OmniDB: `http://omnidb.localhost/` or `https://omnidb.localhost/`

## Backward Compatibility

The main Apache configuration (`portal/elephant-shed.conf`) still contains the path-based OmniDB configuration for backward compatibility. However, the subdomain configuration takes precedence when properly set up.

If you want to completely disable path-based access:
1. Remove or comment out the `<IfModule wsgi_module>` section for OmniDB in `portal/elephant-shed.conf`
2. Reload Apache

## Troubleshooting

### OmniDB subdomain shows 404 or doesn't load
- Verify DNS/hosts configuration
- Check that `omnidb-subdomain.conf` is enabled in Apache
- Review Apache error logs: `/var/log/apache2/omnidb-error.log`

### Portal still shows path-based OmniDB link
- Check that `OMNIDB_SUBDOMAIN` variable is being passed correctly in `portalmain.pl`
- Verify `SERVER_NAME` environment variable is set correctly
- Check Apache configuration for `ServerName` directive

### SSL certificate warnings
- For local development, you can accept the self-signed certificate warning
- For production, obtain a proper SSL certificate from a trusted CA

## Migration Guide

If you're upgrading from a path-based OmniDB configuration:

1. Ensure all users are logged out of OmniDB
2. Deploy the new configuration files
3. Update DNS records
4. Enable the subdomain VirtualHost
5. Reload Apache
6. Inform users of the new OmniDB URL

## Technical Details

- **OmniDB Port**: OmniDB runs as a WSGI application through Apache (no separate port binding)
- **Authentication**: Uses the same `pwauth` authentication as the main portal
- **Session Management**: OmniDB sessions are isolated to the subdomain
- **Other Applications**: All other applications (Grafana, Prometheus, etc.) remain on path-based routing

## Security Considerations

1. **Host Header Validation**: The portal CGI script validates the SERVER_NAME environment variable using a strict regex pattern to prevent Host header injection attacks. Only valid domain names are accepted.

2. **SSL Certificates**: The default configuration uses self-signed certificates which are only suitable for development. Always replace these with proper SSL certificates from a trusted CA for production deployments.

3. **ServerName Configuration**: The Apache VirtualHost uses an explicit ServerName (not wildcard aliases) to prevent subdomain takeover attacks. Update the ServerName to match your specific domain.

4. **Subdomain URL Construction**: The OmniDB subdomain URL is only constructed when SERVER_NAME passes validation. If validation fails, the template falls back to the path-based URL (/omnidb/).
