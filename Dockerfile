FROM nextcloud:apache

# 1. Ép IPv4, timeout và chuyển sang mirror ổn định để tăng tốc độ tải
RUN echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4 \
    && echo 'Acquire::Retries "5";' >> /etc/apt/apt.conf.d/99force-ipv4 \
    && echo 'Acquire::http::Timeout "30";' >> /etc/apt/apt.conf.d/99force-ipv4 \
    && sed -i 's|deb.debian.org|mirror.polytechnic.edu.vn|g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ffmpeg \
        imagemagick \
        libmagickcore-*-extra \
        ghostscript \
        nodejs \
        npm \
        cron \
        smbclient \
    && rm -rf /var/lib/apt/lists/*

# 2. Tối ưu cấu hình PHP cho upload file lớn và render hình ảnh[cite: 1]
RUN echo "memory_limit=1024M" > /usr/local/etc/php/conf.d/memory-limit.ini \
    && echo "upload_max_filesize=16G" >> /usr/local/etc/php/conf.d/upload-limit.ini \
    && echo "post_max_size=16G" >> /usr/local/etc/php/conf.d/upload-limit.ini \
    && echo "max_execution_time=3600" >> /usr/local/etc/php/conf.d/execution-time.ini

# 3. Khởi động cron ngầm cùng Apache web server[cite: 1]
CMD cron && apache2-foreground
