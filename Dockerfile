# Use a base image
FROM alpine:3.17.3

LABEL maintainer="soloman1124@gmail.com"

# See tinyproxy.conf for better explanation of these values.
# Insert any value (preferably "yes") to disable the Via-header:
ENV DISABLE_VIA_HEADER ""
ENV STAT_HOST ""
ENV MAX_CLIENTS ""
ENV ALLOWED_NETWORKS ""
ENV USER ""
ENV PASSWORD ""

ENV TINYPROXY_UID 48765
ENV TINYPROXY_GID 48765

# Curl is for healthchecks.
RUN apk add --no-cache tinyproxy curl

RUN mv /etc/tinyproxy/tinyproxy.conf /etc/tinyproxy/tinyproxy.default.conf && \
    chown -R ${TINYPROXY_UID}:${TINYPROXY_GID} /etc/tinyproxy /var/log/tinyproxy

EXPOSE 8888

# Tinyproxy seems to be OK for getting privileges dropped beforehand
USER ${TINYPROXY_UID}:${TINYPROXY_GID}
CMD set -eu; \
    CONFIG='/etc/tinyproxy/tinyproxy.conf'; \
    if [ ! -f "$CONFIG"  ]; then \
        cp /etc/tinyproxy/tinyproxy.default.conf "$CONFIG"; \
        ([ -z "$DISABLE_VIA_HEADER" ]     || sed -i "s|^#DisableViaHeader .*|DisableViaHeader Yes|" "$CONFIG"); \
        ([ -z "$STAT_HOST" ]              || sed -i "s|^#StatHost .*|StatHost \"${STAT_HOST}\"|" "$CONFIG"); \
        ([ -z "$MAX_CLIENTS" ]            || sed -i "s|^MaxClients .*|MaxClients $MAX_CLIENTS|" "$CONFIG"); \
        ([ -z "$ALLOWED_NETWORKS" ]       || for network in $ALLOWED_NETWORKS; do echo "Allow $network" >> "$CONFIG"; done); \
        ([ -z "$USER" && -z "$PASSWORD" ] || sed -i "s|^#BasicAuth .*|BasicAuth $USER $PASSWORD|" "$CONFIG"); \
        sed -i 's|^LogFile |# LogFile |' "$CONFIG"; \
        sed -i 's|^Syslog |# Syslog |' "$CONFIG"; \
    fi; \
    exec /usr/bin/tinyproxy -d;