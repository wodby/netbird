# NetBird Docker Container Image

[![Build Status](https://github.com/wodby/netbird/workflows/Build%20docker%20image/badge.svg)](https://github.com/wodby/netbird/actions)
[![Docker Pulls](https://img.shields.io/docker/pulls/wodby/netbird.svg)](https://hub.docker.com/r/wodby/netbird)

Runs a self-hosted [NetBird](https://github.com/netbirdio/netbird) server in one container: the management and
signal server with its built-in sign-in (`netbird-server`), the relay (`netbird-relay`) and the
[dashboard](https://github.com/netbirdio/dashboard), behind nginx.

The image is made for a proxy that terminates TLS, such as a Kubernetes gateway, and needs no UDP ports:

- Port `8080` serves the dashboard, the management API, sign-in (`/oauth2`) and the gRPC services of management and
  signal on one address. It accepts HTTP/1.1 and cleartext HTTP/2 (h2c); the proxy must use HTTP/2 to reach it, or
  clients can't use gRPC.
- Port `8082` serves the relay over WebSocket (`/relay`) on a second address. The proxy must use HTTP/1.1 to reach
  it.
- Peers find their public address with a public STUN server (Cloudflare's by default) and connect directly when
  their networks allow it; otherwise their traffic goes through the relay.

## Docker Images

❗For better reliability we release images with stability tags (`wodby/netbird:0-rN`) which correspond to
[git tags](https://github.com/wodby/netbird/releases). We strongly recommend using images only with stability tags.

- Based on Debian (`debian:trixie-slim`), with the binaries and the dashboard from NetBird's official images
- Every build input is pinned by digest in `base-images.mk`, which the [update automation](https://github.com/wodby/images) refreshes: a new NetBird or dashboard release, or a rebuilt Debian or NetBird image, releases a new image revision
- [GitHub actions builds](https://github.com/wodby/netbird/actions)
- [Docker Hub](https://hub.docker.com/r/wodby/netbird)

Supported tags:

- `0.82`, `0`, `latest`

All images are built for `linux/amd64` and `linux/arm64`.

## Environment Variables

| Variable                                 | Default                        | Description                                                                                                 |
|------------------------------------------|--------------------------------|-------------------------------------------------------------------------------------------------------------|
| `NETBIRD_URL`                            |                                | Required. Public address of the dashboard, API and gRPC, such as `https://netbird.example.com`             |
| `NETBIRD_RELAY_URL`                      |                                | Required. Public address of the relay, such as `https://relay.netbird.example.com`                         |
| `NETBIRD_AUTH_SECRET`                    |                                | Required. Secret the server and the relay share                                                            |
| `NETBIRD_STORE_ENCRYPTION_KEY`           |                                | Required. Encrypts sensitive data in the database; never change it once set                                |
| `NETBIRD_SESSION_COOKIE_ENCRYPTION_KEY`  |                                | Keeps sign-in sessions valid across restarts                                                               |
| `NETBIRD_ADMIN_EMAIL`                    |                                | Email of the first administrator, created on the first start                                               |
| `NETBIRD_ADMIN_PASSWORD`                 |                                | Password of the first administrator                                                                        |
| `NETBIRD_STUN_URIS`                      | `stun:stun.cloudflare.com:3478` | STUN servers given to peers, separated by spaces or commas; empty for none                                |
| `NETBIRD_TRUSTED_PROXIES`                | private networks               | Addresses of the proxies in front of the container, separated by spaces, whose `X-Forwarded-For` is trusted |
| `NETBIRD_LOG_LEVEL`                      | `info`                         |                                                                                                             |
| `NETBIRD_DISABLE_ANONYMOUS_METRICS`      | `true`                         | Whether to stop sending anonymous usage metrics to NetBird                                                 |
| `NETBIRD_DISABLE_GEOLITE_UPDATE`         | `false`                        | Whether to stop updating the GeoLite databases used by location posture checks                            |

The two keys may be any string: values that aren't already base64-encoded 32-byte keys are turned into one with
SHA-256.

The administrator is created only together with the sign-in database, on the first start; changing the variables
later has no effect. Without them, the first person to open the dashboard creates the administrator account.

## Data

`/var/lib/netbird` holds the SQLite databases (accounts and peers, sign-in, activity) and the GeoLite databases. Run
one container per volume.

## Run it

```shell
docker run -d --name netbird -p 8080:8080 -p 8082:8082 \
  -e NETBIRD_URL=http://localhost:8080 \
  -e NETBIRD_RELAY_URL=http://localhost:8082 \
  -e NETBIRD_AUTH_SECRET=change-me \
  -e NETBIRD_STORE_ENCRYPTION_KEY=change-me-too \
  -e NETBIRD_ADMIN_EMAIL=admin@example.com \
  -e NETBIRD_ADMIN_PASSWORD=change-me-as-well \
  -v netbird:/var/lib/netbird \
  wodby/netbird:0
```

The first start takes a minute or two while the server downloads the GeoLite databases.

## Health checks

`GET /healthz` on port `8080` checks nginx. `GET /oauth2/.well-known/openid-configuration` on port `8080` also
checks the server behind it. The server and the relay exit on failure, and the container exits with them.
