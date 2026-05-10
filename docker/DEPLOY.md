# Deployment Guide

This app is packaged with Docker and Shiny Server. Once a Docker image is built, the app runs as a self-contained container.

## Prerequisites

Docker must be installed on the server. On Ubuntu/Debian:

```bash
curl -fsSL https://get.docker.com | sh
```

## Build and Run

Clone the repository on the server, then build and start the container:

```bash
git clone <repo-url> MassWateRdash
cd MassWateRdash

docker build -f docker/Dockerfile -t masswater-dash .
docker run -d --restart unless-stopped -p 3838:3838 --name masswater masswater-dash
```

The app will be available at `http://<server-ip>:3838/`.

The `--restart unless-stopped` flag ensures the container restarts automatically after a server reboot.

## Check Logs

```bash
docker logs masswater
# or stream live logs:
docker logs -f masswater
```

Shiny Server logs are also written inside the container at `/var/log/shiny-server/`.

## Update the App

Pull the latest code, rebuild the image, and restart:

```bash
git pull
docker build -f docker/Dockerfile -t masswater-dash .
docker stop masswater && docker rm masswater
docker run -d --restart unless-stopped -p 3838:3838 --name masswater masswater-dash
```

## Optional: Serve on Port 80 with nginx

If the server runs nginx, add a reverse proxy so the app is accessible at `http://<server-ip>/` without specifying a port.

Install nginx if needed:

```bash
apt-get install -y nginx
```

Create `/etc/nginx/sites-available/masswater`:

```nginx
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:3838;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 20d;
    }
}
```

Enable it:

```bash
ln -s /etc/nginx/sites-available/masswater /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

The app will then be accessible at `http://<server-ip>/`.
