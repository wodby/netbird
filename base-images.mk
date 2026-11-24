# Build inputs shared by local builds and CI. Updated by wodby/images.
# Each digest identifies the complete multi-platform image index.
BASE_IMAGE_REPOSITORY := debian
BASE_IMAGE_VERSION_SUFFIX :=

BASE_IMAGE_DIGEST_trixie-slim := sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0

# NetBird's own images, which the build copies the binaries and the dashboard from. The server and relay tags match
# NETBIRD_VER and the dashboard tag NETBIRD_DASHBOARD_VER.
BUILD_IMAGE_NETBIRD_SERVER := netbirdio/netbird-server:0.83.2@sha256:47e43b1b9e6343eb99d99a612513579111439dd016805912b0fae95ce802b908
BUILD_IMAGE_NETBIRD_RELAY := netbirdio/relay:0.83.2@sha256:1b27bbadef5ae7632c46c086c91a872dad7a024aaeb2e0ee7a99faeba23c859f
BUILD_IMAGE_NETBIRD_DASHBOARD := netbirdio/dashboard:v2.98.0@sha256:3e8a714e2966f96201b817657cf5b6e4304b947b88341fe99639214fb440ea9c

BASE_IMAGE = $(BASE_IMAGE_REPOSITORY):trixie-slim@$(BASE_IMAGE_DIGEST_trixie-slim)
