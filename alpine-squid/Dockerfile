# hadolint ignore=DL3007
FROM alpine:latest

ENV container docker

LABEL maintainer="Javier Gómez <gpjavierjob@gmail.com>"

COPY files/uid-entrypoint.sh /usr/local/bin/

# hadolint ignore=DL3018
RUN apk --no-cache add ca-certificates squid tzdata \
    && chmod 755 /usr/local/bin/uid-entrypoint.sh \
    && mkdir -p /etc/squid/conf.d /var/log/squid /var/cache/squid \
    && chgrp -R 0 /var/log/squid /var/cache/squid \
    && chmod -R g=u /etc/passwd /var/log/squid /var/cache/squid

ENV TZ=UTC

COPY files/squid.conf /etc/squid/
COPY files/squid-docker.conf /etc/squid/conf.d/
COPY files/client-ips.conf /etc/squid/conf.d/
COPY files/passwords /etc/squid/conf.d/

ENTRYPOINT ["uid-entrypoint.sh"]

USER 10010
EXPOSE 3128
CMD ["squid", "-N"]
