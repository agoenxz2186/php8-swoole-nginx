FROM php:8.2-fpm-alpine
ENV COMPOSER_ALLOW_SUPERUSER=1

RUN apk --update add ca-certificates

RUN curl -sfL https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer && \
    chmod +x /usr/bin/composer                                                                     && \
    composer self-update --clean-backups 2.7.1  && \
    apk update && \
    apk add --no-cache libstdc++
    
RUN apk --update add nginx wget \
  curl \
  git \
  grep \
  build-base \
  libmemcached-dev \
  libmcrypt-dev \
  libxml2-dev \
  imagemagick-dev \
  pcre-dev \
  libtool \
  make \
  autoconf \
  g++ \
  cyrus-sasl-dev \
  libgsasl-dev \
  supervisor
 
RUN set -ex \
    && apk --no-cache add \
    postgresql-dev
RUN apk add oniguruma-dev

RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS curl-dev libpng-dev \
    openssl-dev pcre-dev pcre2-dev zlib-dev ghostscript \
    && pecl install uploadprogress \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && docker-php-ext-enable uploadprogress \
    && docker-php-ext-install mysqli pdo pdo_mysql pgsql pdo_pgsql mbstring xml gd \
    && pecl channel-update pecl.php.net \
    && pecl install memcached \
    && pecl install imagick \
    && docker-php-ext-enable memcached \
    && docker-php-ext-enable imagick \
    && apk del .build-deps $PHPIZE_DEPS 

RUN apk add --no-cache libzip-dev && docker-php-ext-configure zip && docker-php-ext-install zip

# I recommend being explicit with node version here...
# but we'll see if livewire complains
RUN apk add poppler-utils
RUN apk add --update nodejs-current npm

RUN rm /var/cache/apk/* && \
    mkdir -p /var/www
 

WORKDIR /var/www
COPY ./src /var/www
COPY ./config/supervisord.conf /etc/supervisord.conf
COPY ./nginx.conf /etc/nginx/http.d/default.conf
EXPOSE 80
ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]