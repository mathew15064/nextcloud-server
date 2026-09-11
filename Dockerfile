FROM nextcloud:apache

# Dùng dấu * ở libmagickcore-*-extra để tự động tương thích với mọi phiên bản hệ điều hành của base image
RUN apt-get update && apt-get install -y \
    ffmpeg \
    imagemagick \
    libmagickcore-*-extra \
    ghostscript \
    nodejs \
    npm \
    cron \
    smbclient \
    && rm -rf /var/lib/apt/lists/*

# Mở giới hạn tài nguyên của PHP cho xử lý ảnh nặng và AI
RUN echo "memory_limit=1024M" > /usr/local/etc/php/conf.d/memory-limit.ini \
    && echo "upload_max_filesize=16G" >> /usr/local/etc/php/conf.d/upload-limit.ini \
    && echo "post_max_size=16G" >> /usr/local/etc/php/conf.d/upload-limit.ini \
    && echo "max_execution_time=3600" >> /usr/local/etc/php/conf.d/execution-time.ini

# Đảm bảo cron service chạy ngầm để render thumbnail
CMD cron && apache2-foreground
