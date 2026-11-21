FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

# Apache és Perl telepítése
RUN apt update && \
    apt install -y --no-install-recommends \
        apache2 \
        perl \
        libcgi-pm-perl \
        ca-certificates \
        locales && \
    sed -i 's/^# hu_HU ISO-8859-2/hu_HU ISO-8859-2/' /etc/locale.gen && \
    locale-gen hu_HU && \
    rm -rf /var/lib/apt/lists/*

# Szükséges Apache modulok
RUN a2enmod cgi headers mime reqtimeout && \
    a2disconf serve-cgi-bin

# Apache konfiguráció
COPY apache-vhost.conf /etc/apache2/sites-available/000-default.conf

# Apache naplózás Docker stdout/stderr-re
RUN sed -i 's/^Listen 80$/Listen 8080/' /etc/apache2/ports.conf && \
    sed -i 's|ErrorLog .*|ErrorLog /dev/stderr|' \
    /etc/apache2/apache2.conf && \
    ln -sf /dev/stdout /var/log/apache2/access.log && \
    ln -sf /dev/stderr /var/log/apache2/error.log

# Alkalmazás
WORKDIR /app

COPY www/ /app/www/
COPY data/ /app/data/
COPY .htpasswd /app/

# Jogosultságok
RUN chown -R root:root /app && \
    find /app -type d -exec chmod 755 {} \; && \
    find /app/www -type f -exec chmod 644 {} \; && \
    find /app/www -type f -name "*.pl" -exec chmod 755 {} \; && \
    find /app/data -type d -exec chmod 750 {} \; && \
    find /app/data -type f -exec chmod 640 {} \; && \
    chown -R root:www-data /app/data && \
    chown -R www-data:www-data \
        /app/www/cgi-bin/mazsola/log \
        /app/www/cgi-bin/mazsola/tmp && \
    chmod 750 /app/www/cgi-bin/mazsola/log \
              /app/www/cgi-bin/mazsola/tmp

EXPOSE 8080

STOPSIGNAL SIGWINCH

CMD ["apache2ctl", "-D", "FOREGROUND"]
