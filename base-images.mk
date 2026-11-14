# Build inputs shared by local builds and CI. Updated by wodby/images.
# Each digest identifies the complete multi-platform image index.
BASE_IMAGE_REPOSITORY := debian
BASE_IMAGE_VERSION_SUFFIX :=

BASE_IMAGE_DIGEST_trixie-slim := sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2

# NetBird's own images, which the build copies the binaries and the dashboard from. The server and relay tags match
# NETBIRD_VER and the dashboard tag NETBIRD_DASHBOARD_VER.
BUILD_IMAGE_NETBIRD_SERVER := netbirdio/netbird-server:0.83.1@sha256:f6acc1a6dcb48d10b867ec7e6916c62ef5c8dc2bb198aec9cc637b2dd26c06c9
BUILD_IMAGE_NETBIRD_RELAY := netbirdio/relay:0.83.1@sha256:7b52c1077c964ea01535c311a5e57d7c1c9b7ff4c974ff42995772e4c3546d1a
BUILD_IMAGE_NETBIRD_DASHBOARD := netbirdio/dashboard:v2.97.0@sha256:203b2dc90dc20d3fd45729caac7c922deb399586a68202e0a35be099720bac7d

BASE_IMAGE = $(BASE_IMAGE_REPOSITORY):trixie-slim@$(BASE_IMAGE_DIGEST_trixie-slim)
