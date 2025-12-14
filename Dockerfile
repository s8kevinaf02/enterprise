FROM debian:bookworm-slim

# Install Apache (and clean up cache to keep it lean)
RUN apt-get update && \
    apt-get install -y apache2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory and copy app files
WORKDIR /var/www/html
COPY app/index.html ./index.html
    

# Expose Apache's default port
EXPOSE 80

# Start Apache in foreground
CMD ["apache2ctl", "-D", "FOREGROUND"]

