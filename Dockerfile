FROM alpine:latest

MAINTAINER Mickael Bonfill <mickael.bonfill@gmail.com>

ENV PHPMYADMIN_VERSION  4_7_3
ENV TIMEZONE            America/Montreal
ENV PHP_MEMORY_LIMIT    512M
ENV MAX_UPLOAD          64M
ENV PHP_MAX_FILE_UPLOAD 200
ENV PHP_MAX_POST        128M
ENV BLOWFISH_SECRET     \$2a\$07\$sDCBHPdBa99FHv6pdfz9BeemO2VXwpcOVhlGoaEUFh96eiIfxnu5q

RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk update && apk upgrade && \
    apk add --update apache2 php7-apache2 curl ca-certificates git nano wget tzdata \
    php7 \
    php7-phar \
    php7-json \
    php7-iconv \
    php7-openssl \
    php7-ftp \
  	php7-xdebug \
  	php7-mcrypt \
  	php7-soap \
  	php7-gmp \
  	php7-pdo_odbc \
  	php7-dom \
    php7-opcache \
  	php7-pdo \
    php7-zlib \
  	php7-zip \
  	php7-mysqli \
  	php7-sqlite3 \
  	php7-pdo_pgsql \
  	php7-bcmath \
  	php7-gd \
  	php7-odbc \
  	php7-pdo_mysql \
  	php7-pdo_sqlite \
  	php7-gettext \
    php7-xml \
  	php7-xmlreader \
  	php7-xmlrpc \
  	php7-bz2 \
  	php7-pdo_dblib \
  	php7-curl \
  	php7-ctype \
  	php7-session \
  	php7-redis \
    php7-simplexml \
    php7-tokenizer \
    php7-mbstring \
    php7-cli \
    mysql \
    mysql-client \
    && rm -f /var/cache/apk/* && \
    curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer && \
    wget --no-check-certificate -c -q https://github.com/phpmyadmin/phpmyadmin/archive/RELEASE_$PHPMYADMIN_VERSION.tar.gz && \
    tar -zxf RELEASE_$PHPMYADMIN_VERSION.tar.gz && \
    mkdir /www && \
    mv phpmyadmin-RELEASE_$PHPMYADMIN_VERSION /www/ && \
    mv /www/phpmyadmin-RELEASE_$PHPMYADMIN_VERSION /www/phpmyadmin && \
    cd /www/phpmyadmin && \
    composer update --no-dev && \
    composer clear-cache && \
    rm -f /RELEASE_$PHPMYADMIN_VERSION.tar.gz && \
    cp /www/phpmyadmin/config.sample.inc.php /www/phpmyadmin/config.inc.php && \
    sed -i "s#$cfg\['blowfish_secret'\] = '';#$cfg['blowfish_secret'] = '${BLOWFISH_SECRET}';#" /www/phpmyadmin/config.inc.php && \
    cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone && \
    mkdir -p /run/mysqld && \
    chown -R mysql:mysql /run/mysqld /var/lib/mysql && \
    sed -i 's#^\[mysqld\]#[mysqld]\nsql_mode=""#' /etc/mysql/my.cnf && \
    mysql_install_db --user=mysql --verbose=1 --basedir=/usr --datadir=/var/lib/mysql --rpm > /dev/null && \
    ln -s /usr/lib/libxml2.so.2 /usr/lib/libxml2.so && \
    sed -i 's#AllowOverride None#AllowOverride All#' /etc/apache2/httpd.conf && \
    sed -i 's#\#LoadModule rewrite_module#LoadModule rewrite_module#' /etc/apache2/httpd.conf && \
    sed -i 's#ServerName www.example.com:80#\nServerName localhost:80#' /etc/apache2/httpd.conf && \
    sed -i 's#^DocumentRoot ".*#DocumentRoot "/www"#g' /etc/apache2/httpd.conf && \
    sed -i 's#/var/www/localhost/htdocs#/www#g' /etc/apache2/httpd.conf && \
    sed -i "s|;*date.timezone =.*|date.timezone = ${TIMEZONE}|i" /etc/php7/php.ini && \
    sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php7/php.ini && \
    sed -i "s|;*upload_max_filesize =.*|upload_max_filesize = ${MAX_UPLOAD}|i" /etc/php7/php.ini && \
    sed -i "s|;*max_file_uploads =.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php7/php.ini && \
    sed -i "s|;*post_max_size =.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php7/php.ini && \
    sed -i "s|;*cgi.fix_pathinfo=.*|cgi.fix_pathinfo= 0|i" /etc/php7/php.ini && \
    mkdir -p /run/apache2 && \
    chown -R apache:apache /run/apache2 && \
    echo "<?php phpinfo(); ?>" > /www/phpinfo.php && \
    cp /var/www/localhost/htdocs/index.html /www/index.html && \
    chown -R apache:apache /www

RUN nohup mysqld --bind-address 0.0.0.0 --user mysql > /dev/null 2>&1 & \
    sleep 5 && mysqladmin -u root password toor && \
    mysql -u root --password=toor -e "CREATE DATABASE phpmyadmin" && \
    mysql -u root --password=toor phpmyadmin < /www/phpmyadmin/sql/create_tables.sql

RUN echo "#!/bin/sh" > /start.sh && \
    echo "httpd" >> /start.sh && \
    echo "nohup mysqld --bind-address 0.0.0.0 --user mysql > /dev/null 2>&1 &" >> /start.sh && \
    echo "tail -f /var/log/apache2/access.log" >> /start.sh && \
    chmod u+x /start.sh


WORKDIR /www

EXPOSE 80
EXPOSE 3306

ENTRYPOINT ["/start.sh"]
