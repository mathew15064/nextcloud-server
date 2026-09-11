FROM nextcloud:apache

# 1. Cấu hình APT cơ bản
RUN echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4 && \
    echo 'Acquire::Retries "3";' >> /etc/apt/apt.conf.d/99force-ipv4

# 2. Cài đặt các công cụ xử lý đa phương tiện & hệ thống
RUN apt-get update && apt-get install -y --no-install-recommends \
        ffmpeg \
        imagemagick \
        ghostscript \
        cron \
        smbclient \
        procps \
    && rm -rf /var/lib/apt/lists/*

# 3. Cài đặt NodeJS (nếu dùng cho Memories / Recognize)
# Nếu không thực sự cần npm để build mã nguồn, chỉ cần cài nodejs để tiết kiệm dung lượng và tránh lỗi
RUN apt-get update && apt-get install -y --no-install-recommends \
        nodejs \
        npm \
    && rm -rf /var/lib/apt/lists/*

# 4. Tối ưu PHP
RUN echo "memory_limit=1024M" > /usr/local/etc/php/conf.d/memory-limit.ini \
    && echo "upload_max_filesize=16G" >> /usr/local/etc/php/conf.d/upload-limit.ini \
    && echo "post_max_size=16G" >> /usr/local/etc/php/conf.d/upload-limit.ini \
    && echo "max_execution_time=3600" >> /usr/local/etc/php/conf.d/execution-time.ini

CMD cron && apache2-foreground
