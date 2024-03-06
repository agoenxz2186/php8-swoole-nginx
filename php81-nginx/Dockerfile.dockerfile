FROM php:8.1.7-cli-alpine3.16

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/


# make sure you can use HTTPS
RUN apk --update add ca-certificates

RUN \
    curl -sfL https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer && \
    chmod +x /usr/bin/composer                                                                     && \
    composer self-update --clean-backups 2.7.1  && \
    apk update && \
    apk add --no-cache libstdc++

RUN CFLAGS="$CFLAGS -D_GNU_SOURCE"
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS git gcc \
    && pecl install uploadprogress \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && docker-php-ext-enable uploadprogress \
    && apk del .build-deps $PHPIZE_DEPS \
    && chmod uga+x /usr/local/bin/install-php-extensions && sync \
    && install-php-extensions bcmath \
            bz2 \
            calendar \
            curl \
            exif \                                                                                                                                                                                                           fileinfo \                                                                                                                                                                                                       ftp \
            gd \
            gettext \
#            imagick \
            imap \
            intl \
            ldap \
            mcrypt \
            memcached \
            mongodb \
            mysqli \
            opcache \
            pdo \
            pdo_mysql \
            pgsql \
            pdo_pgsql \
            soap \
            sodium \
            sysvsem \
            sysvshm \
            zip
RUN echo "extension=redis.so" > /usr/local/etc/php/conf.d/redis.ini
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS curl-dev \
    openssl-dev pcre-dev pcre2-dev zlib-dev ghostscript imagemagick-dev
RUN docker-php-ext-install sockets
RUN pecl install imagick
RUN docker-php-ext-enable imagick && \
    docker-php-source extract && \
    mkdir /usr/src/php/ext/swoole && \
    curl -sfL https://github.com/swoole/swoole-src/archive/v5.1.2.tar.gz -o swoole.tar.gz && \
    tar xfz swoole.tar.gz --strip-components=1 -C /usr/src/php/ext/swoole && \
    docker-php-ext-configure swoole  --enable-sockets --enable-swoole-curl  --enable-openssl --enable-mysqlnd
#        --enable-http2   \
#        --enable-mysqlnd \
#        --enable-openssl \
#        --enable-sockets --enable-swoole-curl --enable-swoole-json
RUN docker-php-ext-install -j$(nproc) swoole && \
    rm -f swoole.tar.gz $HOME/.composer/*-old.phar && \
    docker-php-source delete && \
    apk del .build-deps
RUN apk add --update supervisor && rm -rf /tmp/* /var/cache/apk/*
RUN apk add poppler-utils
RUN apk add --update nodejs-current npm
RUN apk update && apk add nginx php81-fpm
RUN mkdir -p /run/nginx

RUN sed -i "s|;cgi.fix_pathinfo=1|cgi.fix_pathinfo=0|g" /etc/php81/php.ini && \
    sed -i "s|listen = 127.0.0.1:9000|listen = /var/run/php-fpm.sock|g" /etc/php81/php-fpm.d/www.conf && \
    sed -i "s|;listen.owner = nobody|listen.owner = nobody|g" /etc/php81/php-fpm.d/www.conf && \
    sed -i "s|;listen.group = nobody|listen.group = nobody|g" /etc/php81/php-fpm.d/www.conf && \
    sed -i "s|user = nobody|user = nginx|g" /etc/php81/php-fpm.d/www.conf && \
    sed -i "s|group = nobody|group = nginx|g" /etc/php81/php-fpm.d/www.conf

COPY nginx.conf /etc/nginx/http.d/default.conf

RUN php-fpm81

WORKDIR /var/www
COPY ./src /var/www
COPY ./config/run.sh /docker/run.sh
RUN chmod +x /docker/run.sh
EXPOSE 80 
CMD ["sh", "-c", "php-fpm81 && nginx -g 'daemon off;'"]