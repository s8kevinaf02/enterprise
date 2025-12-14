# Nexus Enterprises — Static Website (Docker + Jenkins)

Small project that serves a static website via Apache in a Debian-based container.

Files
- [Dockerfile](Dockerfile) — builds an Apache image that expects the site files in an `app/` folder and sets `WORKDIR /var/www/html`.
- [JenkinsFile](JenkinsFile) — pipeline that builds, tags, pushes the image and deploys a container. It uses environment variables such as [`environment.DOCKER_HUB_USERNAME`](JenkinsFile) and parameters like [`parameters.APP1_TAG`](JenkinsFile), [`parameters.PORT_ON_DOCKER_HOST_01`](JenkinsFile), and [`parameters.CONTAINER_NAME`](JenkinsFile).
- [website-enterprise.html](website-enterprise.html) — example website content to place under `app/`.

Prerequisites
- Docker installed and running
- (Optional) Jenkins configured with Docker access and credentials id `docker-hub-credentials` (used in the pipeline)

Local build & run
1. Put your website files in `./app` (e.g., `app/index.html` or rename `website-enterprise.html` to `index.html`).
2. Build the image:
   ```sh
   docker build -t <hub_user>/<repo>:<tag> .
