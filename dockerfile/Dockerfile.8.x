# syntax=docker/dockerfile:1
ARG UPSTREAM
ARG CONFIGUS=wyga/configus:latest
FROM ${CONFIGUS} AS configus
FROM ${UPSTREAM} AS mold
RUN find /usr/local/bin -type f -not -name phar.phar -not -name phar -not -name php-config -not -name php -not -name pear
RUN find /usr/local/bin -type f -not -name phar.phar -not -name phar -not -name php-config -not -name php -not -name pear -delete
WORKDIR /config/php/etc
RUN cp /usr/local/etc/pear.conf  .
COPY php-fpm.conf .
WORKDIR /config/php/main
COPY main/ .
WORKDIR /config/php/ini
WORKDIR /config/php/extension/present
COPY extension/ .
WORKDIR /config/php/extension/enable
COPY default-extensions default
WORKDIR /config/php/fpm
COPY fpm-pool pool
WORKDIR /.metadata/php
RUN echo -n "${PHP_VERSION}" >version
RUN /usr/local/bin/php-config --extension-dir >extension-dir
WORKDIR /.entrypoint
COPY --chmod=755 entrypoint.sh uphp
WORKDIR /
COPY --chmod=444 configus.meta /.metadata/configus
COPY --chmod=755 md /bin/.md
COPY --chmod=755 template-engine /sbin/template-engine
COPY --from=configus --chmod=755 /client/config-service /sbin/config-service
COPY --chmod=755 configus-config.sh /sbin/configus-config
COPY --chmod=755 extension-config.sh /sbin/extension-config
COPY --chmod=755 xdebug-config.sh /sbin/xdebug-config
COPY --chmod=755 profile-config.sh /sbin/profile-config
COPY --chmod=755 timezone-config.sh /sbin/timezone-config
COPY --chmod=755 home-config.sh /sbin/home-config
COPY --chmod=755 container-config.sh /sbin/container-config
COPY --chmod=755 health-check.sh /sbin/health-check
COPY --chmod=755 php-fpm /sbin/php-fpm
# Make sure www-data has UID/GID 33
RUN deluser xfs || true
RUN deluser www-data || true
RUN addgroup -g 33 -S www-data && adduser -S -u 33 -G www-data -g "PHP Engine" -D -H -h /web www-data
RUN find /etc -name "*-"  -delete -type f
RUN rm -rf /usr/local/include /usr/local/php/man /usr/src
RUN rm -rf /usr/local/etc && ln -s /config/php/etc /usr/local/etc
RUN find /config/php/ini /config/php/main /config/php/extension/enable /config/php/fpm /var/log -type d -exec chmod 777 {} \; && \
    find /config/php/ini /config/php/main /config/php/extension/enable /config/php/fpm -type f -exec chmod 666 {} \; && \
    find $(/usr/local/bin/php-config --extension-dir) -type f -exec chmod 644 {} \;

WORKDIR /config/php/profile
COPY profile/ /config/php/profile/

FROM scratch
COPY --from=mold / /
ENV PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
ENV PHPRC=/config/php/main
ENV PHP_INI_DIR=/config/php/ini
ENV PHP_INI_SCAN_DIR=/config/php/ini
ENV HOME=/dev/shm/.home
ENV PROFILES=ON
STOPSIGNAL SIGQUIT
USER 40000:40000
# Waiting for --start-interval (docker >=25.0)
#HEALTHCHECK --interval=60 --timeout=1 --start-period=60 --start-interval=1 --retries=5 CMD /sbin/health-check
CMD [ "php-fpm" ]
ENTRYPOINT ["tini", "--","/.entrypoint/uphp" ]
