FROM nextcloud:apache

# 1. Ép IPv4, tăng retry và timeout cho apt
RUN echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4 \
    && echo 'Acquire::Retries "5";' >> /etc/apt/apt.conf.d/99force-ipv4 \
    && echo 'Acquire::http::Timeout "30";' >> /etc/apt/apt.conf.d/99force-ipv4 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ffmpeg \
        imagemagick \
        libmagickcore-6.q16-6-extra \
        ghostscript \
        nodejs \
        npm \
        cron \
        smbclient \
    && rm -rf /var/lib/apt/lists/*

# 2. Tối ưu cấu hình PHP cho upload file lớn và render hình ảnh
RUN echo "memory_limit=1024M" > /usr/local/etc/php/conf.d/memory-limit.ini \
    && echo "upload_max_filesize=16G" >> /usr/local/etc/php/conf.d/upload-limit.ini \
    && echo "post_max_size=16G" >> /usr/local/etc/php/conf.d/upload-limit.ini \
    && echo "max_execution_time=3600" >> /usr/local/etc/php/conf.d/execution-time.ini

# 3. Khởi động cron ngầm cùng Apache web server
CMD cron && apache2-foreground
