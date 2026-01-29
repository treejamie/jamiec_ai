# Deployment Guide

This document describes the Docker-based deployment process for Jamiec using GitHub Actions and Coolify on Raspberry Pi.

## Docker Setup

The application uses a multi-stage Dockerfile that:
- Builds for both AMD64 (x86_64) and ARM64 (aarch64) architectures
- Uses Elixir 1.18.3 with OTP 27.3.4
- Compiles assets (Tailwind CSS + esbuild)
- Creates an optimized release build
- Runs as a non-root user for security

## CI/CD Pipeline

When code is merged to the `main` branch:

1. GitHub Actions automatically triggers (`.github/workflows/docker-build.yml`)
2. Builds multi-architecture Docker images using QEMU and Buildx
3. Pushes images to GitHub Container Registry (ghcr.io)
4. Tags images with:
   - `latest` (main branch)
   - `main` (branch name)
   - `sha-<commit-sha>` (specific commit)

## GitHub Container Registry

Images are published to: `ghcr.io/jamiec/jamiec`

The registry is public by default. To make images public:
1. Go to https://github.com/users/jamiec/packages/container/jamiec/settings
2. Change package visibility to "Public"

## Coolify Deployment on Raspberry Pi

### Initial Setup

1. **Create a new service in Coolify**:
   - Type: Docker Image
   - Registry: `ghcr.io`
   - Image: `jamiec/jamiec:latest`
   - Pull policy: Always (to get latest on redeploy)

2. **Set required environment variables**:
   ```bash
   # Generate a secret key base (run locally):
   mix phx.gen.secret

   # Then set in Coolify:
   SECRET_KEY_BASE=<generated-secret>
   DATABASE_URL=postgresql://user:password@host/database
   PHX_HOST=yourdomain.com
   PHX_SERVER=true
   PORT=4000
   POOL_SIZE=10
   ```

3. **Optional environment variables**:
   ```bash
   ECTO_IPV6=false
   DNS_CLUSTER_QUERY=<your-cluster-query>
   ```

### Database Setup

Before first deployment, run migrations:

1. In Coolify, go to your service
2. Open a shell/terminal
3. Run: `/app/bin/migrate`

Or use Coolify's pre-deployment command feature to run migrations automatically.

### Deployment Process

1. **Push/merge code to main branch**
2. **Wait for GitHub Actions build** (check Actions tab)
3. **In Coolify**: Click "Redeploy" or it will auto-deploy if configured
4. **Coolify will**:
   - Pull the latest ARM64 image from ghcr.io
   - Stop the old container
   - Start the new container
   - No compilation needed on the Pi!

### Health Checks

The application responds on the root path `/`. Configure Coolify health checks:
- Path: `/`
- Expected status: 200
- Interval: 30s

## Manual Docker Testing

### Build locally:
```bash
docker build -t jamiec:test .
```

### Run locally with environment variables:
```bash
docker run --rm \
  -e SECRET_KEY_BASE=<secret> \
  -e DATABASE_URL=<db-url> \
  -e PHX_HOST=localhost \
  -e PHX_SERVER=true \
  -e PORT=4000 \
  -p 4000:4000 \
  jamiec:test
```

### Test multi-arch build:
```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t jamiec:multi-arch \
  .
```

## Rollback Strategy

If a deployment fails:

1. **Check Coolify logs** for errors
2. **Roll back to previous image**:
   - Change image tag from `latest` to a specific SHA: `sha-<commit>`
   - Or use a previous `main` tag
   - Click "Redeploy"

3. **Or revert the main branch**:
   - Revert the problematic commit
   - Push to main
   - GitHub Actions will build a new image
   - Coolify will pull the reverted version

## Architecture

- **Build Platform**: GitHub Actions (Ubuntu runners)
- **Target Platforms**:
  - linux/amd64 (for local testing)
  - linux/arm64 (for Raspberry Pi)
- **Image Registry**: GitHub Container Registry (ghcr.io)
- **Deployment Platform**: Coolify on Raspberry Pi 4/5
- **Runtime**: Elixir release (no Mix in production)

## Security Notes

- Container runs as `nobody` user (non-root)
- Secrets are environment variables only (never in image)
- Images can be scanned for vulnerabilities via GitHub
- Regular base image updates recommended

## Troubleshooting

### Image pull fails
- Check package visibility in GitHub (should be Public)
- Verify image name matches: `ghcr.io/<username>/jamiec:latest`

### Container crashes on startup
- Check SECRET_KEY_BASE is set
- Verify DATABASE_URL is correct and accessible from Pi
- Check Coolify logs: `docker logs <container-id>`

### Migrations fail
- Ensure DATABASE_URL is correct
- Check database is accessible from Pi
- Verify database user has migration permissions

### Port conflicts
- Default port is 4000
- Change PORT env var if needed
- Ensure Coolify port mapping is correct

## Performance Tips

- The Raspberry Pi pulls pre-built ARM64 images (no compilation needed)
- First deployment may be slow (downloading layers)
- Subsequent deployments only pull changed layers (faster)
- Keep images lean by using .dockerignore properly
