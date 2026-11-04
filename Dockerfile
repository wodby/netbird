ARG NETBIRD_VER=0.82.0
ARG NETBIRD_DASHBOARD_VER=v2.96.0
# The Makefile passes digest-pinned references from base-images.mk; these defaults are for plain docker builds.
ARG BASE_IMAGE=debian:trixie-slim
ARG NETBIRD_SERVER_IMAGE=netbirdio/netbird-server:${NETBIRD_VER}
ARG NETBIRD_RELAY_IMAGE=netbirdio/relay:${NETBIRD_VER}
ARG NETBIRD_DASHBOARD_IMAGE=netbirdio/dashboard:${NETBIRD_DASHBOARD_VER}

# The NetBird binaries and the dashboard's static build come from NetBird's own images. netbird-server is linked
# against glibc, so this image is based on Debian rather than Alpine.
FROM ${NETBIRD_SERVER_IMAGE} AS server
FROM ${NETBIRD_RELAY_IMAGE} AS relay
FROM ${NETBIRD_DASHBOARD_IMAGE} AS dashboard

FROM ${BASE_IMAGE}

ARG NETBIRD_VER=0.82.0
ARG NETBIRD_DASHBOARD_VER=v2.96.0

ENV NETBIRD_VER="${NETBIRD_VER}" \
    NETBIRD_DASHBOARD_VER="${NETBIRD_DASHBOARD_VER}"

RUN set -eux; \
    if [ -z "${NETBIRD_VER}" ] || [ -z "${NETBIRD_DASHBOARD_VER}" ]; then \
      echo "NETBIRD_VER and NETBIRD_DASHBOARD_VER are required (example: 0.82.0 and v2.96.0)"; \
      exit 1; \
    fi; \
    apt-get update; \
    apt-get upgrade -y; \
    apt-get install -y --no-install-recommends \
      apache2-utils \
      ca-certificates \
      curl \
      gettext-base \
      nginx \
      tini; \
    rm -rf /var/lib/apt/lists/*; \
    rm -f /etc/nginx/sites-enabled/default /etc/nginx/conf.d/*; \
    useradd -u 1000 -U -d /var/lib/netbird -s /bin/bash netbird; \
    mkdir -p /var/lib/netbird /etc/nginx/http.d /run/netbird /tmp/nginx /usr/share/nginx/html; \
    chown netbird:netbird /var/lib/netbird /etc/nginx/http.d /run/netbird /tmp/nginx /usr/share/nginx/html

COPY --from=server /go/bin/netbird-server /usr/local/bin/netbird-server
COPY --from=relay /go/bin/netbird-relay /usr/local/bin/netbird-relay
COPY --from=dashboard /usr/share/nginx/html /usr/share/netbird-dashboard
COPY --from=dashboard /usr/local/init_react_envs.sh /usr/local/bin/netbird-dashboard-init

COPY nginx.conf /etc/nginx/nginx.conf
COPY --chown=netbird:netbird default.conf /etc/nginx/http.d/default.conf
COPY docker-entrypoint.sh /
COPY bin /usr/local/bin

USER netbird

WORKDIR /var/lib/netbird

VOLUME /var/lib/netbird

# 8080: dashboard, management API, sign-in and gRPC (management and signal); serves HTTP/1.1 and cleartext HTTP/2.
# 8082: relay over WebSocket.
EXPOSE 8080 8082

STOPSIGNAL SIGTERM

# tini reaps the server processes and forwards signals to them.
ENTRYPOINT ["/usr/bin/tini", "--", "/docker-entrypoint.sh"]

CMD ["netbird"]
