# Deployment Guide

This app is packaged with Docker and Shiny Server. Once a Docker image is built, the app runs as a self-contained container.

## Prerequisites

Docker must be installed on the server. On Ubuntu/Debian:

```bash
curl -fsSL https://get.docker.com | sh
```

## Build and Push to Docker Hub

Build the image locally, tag it with your Docker Hub username, and push:

```bash
docker build -f docker/Dockerfile -t fawda123/masswater-dash:latest .
docker push fawda123/masswater-dash:latest
```

Log in first if prompted:

```bash
docker login
```

## Deploy from Docker Hub

On the server, pull the image and start the container (no repo clone or build required):

```bash
docker pull fawda123/masswater-dash:latest
docker run -d --restart unless-stopped -p 3838:3838 --name masswater fawda123/masswater-dash:latest
```

The app will be available at `http://<server-ip>:3838/`.

The `--restart unless-stopped` flag ensures the container restarts automatically after a server reboot.

## Local Testing

To test the image on your local machine before deploying, build and run without the restart policy:

```bash
docker build -f docker/Dockerfile -t fawda123/masswater-dash:latest .
docker run --rm -p 3838:3838 --name masswater fawda123/masswater-dash:latest
```

The app will be available at `http://localhost:3838/`. The `--rm` flag removes the container automatically when you stop it (Ctrl+C).

To run it in the background instead:

```bash
docker run -d -p 3838:3838 --name masswater fawda123/masswater-dash:latest
```

Stop and remove it when done:

```bash
docker stop masswater && docker rm masswater
```

## Check Logs

```bash
docker logs masswater
# or stream live logs:
docker logs -f masswater
```

Shiny Server logs are also written inside the container at `/var/log/shiny-server/`.

## Update the App

Rebuild and push a new image locally:

```bash
docker build -f docker/Dockerfile -t fawda123/masswater-dash:latest .
docker push fawda123/masswater-dash:latest
```

Then on the server, pull and restart:

```bash
docker pull fawda123/masswater-dash:latest
docker stop masswater && docker rm masswater
docker run -d --restart unless-stopped -p 3838:3838 --name masswater fawda123/masswater-dash:latest
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
