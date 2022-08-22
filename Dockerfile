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

# # all built extensions and deps; intl and xsl are the fat ones in case we want to remove it from default?
# copying these deps instead of installing them on runtime saves about 14MB
# COPY --from=php /usr/lib/libbz2.so.1 \
# 	/usr/lib/libpng16.so.16 \
# 	/usr/lib/libicuio.so.67 \
# 	/usr/lib/libicui18n.so.67 \
# 	/usr/lib/libicuuc.so.67 \
# 	/usr/lib/libicudata.so.67 \
# 	/usr/lib/libstdc++.so.6 \
# 	/usr/lib/libgcc_s.so.1 \
# 	/usr/lib/libxslt.so.1 \
# 	/usr/lib/libexslt.so.0 \
# 	/usr/lib/libgcrypt.so.20 \
# 	/usr/lib/libgpg-error.so.0 \
# 	/usr/lib/libzip.so* \
# 	/usr/lib/libsodium.so.23 \
# 	/usr/lib/libargon2.so.1 \
# 	/usr/lib/libsqlite3.so.0 \
# 	/usr/lib/libonig.so.5 \
# 	/usr/lib/libncursesw.so.6 \
# 	/usr/lib/libedit.so.0 /usr/lib/

COPY --from=php /usr/lib/lib* /usr/lib/
COPY --from=php /usr/local/lib/php /usr/local/lib/php
COPY --from=php /usr/local/etc/ /usr/local/etc/
COPY --from=php /usr/local/bin/* /usr/local/bin/
COPY --from=php /usr/local/sbin/* /usr/local/sbin/

COPY custom-entrypoint /usr/local/bin

# 7.4 will not have default configs, because existing projects would be affected by their addition
# consider using 8+
COPY cfg/* /usr/local/apache2/conf/required.conf.d/

# default webroot
VOLUME /var/www/app

ENTRYPOINT ["custom-entrypoint"]
