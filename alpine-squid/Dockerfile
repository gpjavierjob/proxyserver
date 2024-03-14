# Crea una imagen de Squid sobre de Alpine Linux. Se definen dos variables
# de compilación que, si son utilizadas, permiten indicar las versiones de 
# Alpine Linux y Squid a utilizar.
#   ALPINE_VERSION:     Versión de Alpine Linux.
#   SQUID_VERSION:      Versión de Squid.
# De forma predeterminada instala Squid 6.6-r0 sobre alpine:latest
ARG ALPINE_VERSION=latest

# hadolint ignore=DL3007
FROM "alpine:$ALPINE_VERSION"

LABEL maintainer="Javier Gómez <gpjavierjob@gmail.com>"

ENV SQUID_CACHE_DIR=/var/spool/squid \
    SQUID_LOG_DIR=/var/log/squid \
    SQUID_SNIPPETS_DIR=/etc/squid/conf.d \
    SQUID_USER=squid \
    TZ=UTC

COPY files/uid-entrypoint.sh /usr/local/bin/

ARG SQUID_VERSION=6.6-r0

# hadolint ignore=DL3018
RUN apk "--no-cache" "add" "ca-certificates" "squid=$SQUID_VERSION" "tzdata" \
    && chmod 755 /usr/local/bin/uid-entrypoint.sh \
    && mkdir "-p" "$SQUID_SNIPPETS_DIR" "$SQUID_LOG_DIR" "$SQUID_CACHE_DIR" \
    && chown "-R" "$SQUID_USER:" "$SQUID_LOG_DIR" "$SQUID_CACHE_DIR"

COPY files/squid.conf /etc/squid/
COPY files/snippet.conf /etc/squid/conf.d/

ENTRYPOINT ["uid-entrypoint.sh"]

USER "$SQUID_USER"

EXPOSE 3128

CMD ["squid", "-N"]
