# Nginx with ModSecurity and OWASP CRS for Juice Shop

This project provides a Dockerized Nginx web server with ModSecurity (a web application firewall) and the OWASP Core Rule Set (CRS) configured as a reverse proxy for OWASP Juice Shop.

## Features
- Nginx as a reverse proxy with ModSecurity WAF
- OWASP Core Rule Set (CRS) for protection against common web attacks
- Pre-configured to protect Juice Shop application
- Easy-to-deploy Docker container

## Prerequisites
- Docker installed on your system
- (Optional) OWASP Juice Shop container running (if you want to test the full setup)

## Quick Start
1. Build the Docker image anc create a network:
   ```bash
   docker build -t nginx-modsecurity .
   docker network create juice-net
   ```
2. Run the containers:
    ```bash
    docker run -d --name juice_shop --network juice-net bkimminich/juice-shop

    docker run -d --name nginx-modsec --network juice-net -p 80:80 modsec-base
    ```

## Nginx Configuration

The default configuration (juice_shop.conf) sets up:
- Nginx listening on port 80
- ModSecurity enabled with OWASP CRS rules
- Reverse proxy to Juice Shop on port 3000

## ModSecurity Configuration
- ModSecurity engine is enabled by default
- OWASP CRS rules are loaded with default configuration
- Main configuration file is at /etc/nginx/modsec/main.conf

## Customizing
To customize the configuration:
- Modify the juice_shop.conf file before building the image, or
- Mount your custom configuration when running the container

## Security Notes
The default configuration enables all OWASP CRS rules. You may need to adjust exclusions based on your application's needs.

For production use, consider:
- Adding SSL/TLS configuration
- Customizing CRS rules
- Setting up proper logging and monitoring
- Hardening the container security

## Troubleshooting
- Check Nginx logs: ```docker logs nginx-waf```

- Verify ModSecurity is loaded: Look for ```ngx_http_modsecurity_module.so``` in Nginx startup logs

- For rule debugging, enable ModSecurity debug logging in ```/etc/nginx/modsec/modsecurity.conf```
