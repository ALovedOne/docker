from php:apache

WORKDIR /var/www/html/

RUN apt-get update; apt-get install -y wget libpq-dev; \ 
    docker-php-ext-install pdo_pgsql opcache pgsql pcntl; \
    wget -O /tmp/master.tgz https://git.tt-rss.org/fox/tt-rss/archive/master.tar.gz; \
    apt-get purge -y --auto-remove wget; \
    tar -xf /tmp/master.tgz -C /tmp/; \
    mv /tmp/tt-rss/* /var/www/html; \
    chown -R www-data:www-data /var/www/html; \
    rm -r /tmp/*; \
    ln -s /usr/local/bin/php /usr/bin/php;

COPY ./docker-tt-rss-entrypoint /usr/local/bin/docker-tt-rss-entrypoint

CMD ["apache2-foreground"]
ENTRYPOINT ["/usr/local/bin/docker-tt-rss-entrypoint"]
