FROM php:8.1-fpm-alpine3.16 as php
MAINTAINER Trey Jones "trey@cortexdigitalinc.com"

RUN apk add --no-cache bzip2-dev libpng-dev icu-dev libxslt-dev libzip-dev
RUN docker-php-ext-install \
	bcmath \
	bz2 \
	calendar \
	exif \
	gd \
	intl \
	mysqli \
	pdo_mysql \
	shmop \
	soap \
	sockets \
	sysvmsg \
	sysvsem \
	sysvshm \
	xsl \
	zip

# I *think* we can get away without keeping a copy of the source on here
# it saves 8MB - if we need to add exts, we will rebuild
RUN	rm  -R /usr/src/

###############################################
FROM eyesore/httpd:2.4.54 as release

# ensure php runtime deps and create log dir
RUN mkdir -p /usr/local/var/log/ && apk add --no-cache \
		ca-certificates \
		curl \
		tar \
		xz \
	openssl # https://github.com/docker-library/php/issues/494

COPY --from=php /usr/lib/lib* /usr/lib/
COPY --from=php /usr/local/lib/php /usr/local/lib/php
COPY --from=php /usr/local/etc/ /usr/local/etc/
COPY --from=php /usr/local/bin/* /usr/local/bin/
COPY --from=php /usr/local/sbin/* /usr/local/sbin/

COPY --from=composer:2.4 /usr/bin/composer /usr/local/bin/composer

COPY custom-entrypoint /usr/local/bin

# 7.4 will not have default configs, because existing projects would be affected by their addition
# consider using 8+
COPY cfg/* /usr/local/apache2/conf/required.conf.d/

# default webroot
VOLUME /var/www/app

ENTRYPOINT ["custom-entrypoint"]
