# Build inputs shared by local builds and CI. Updated by wodby/images.
# Each digest identifies the complete multi-platform image index.
BASE_IMAGE_REPOSITORY := debian
BASE_IMAGE_VERSION_SUFFIX :=

BASE_IMAGE_DIGEST_trixie-slim := sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0

# NetBird's own images, which the build copies the binaries and the dashboard from. The server and relay tags match
# NETBIRD_VER and the dashboard tag NETBIRD_DASHBOARD_VER.
BUILD_IMAGE_NETBIRD_SERVER := netbirdio/netbird-server:0.84.0@sha256:e439e43e8db328656baeafe124939cfdac3a71cc38fcad9b44deefe0e84a5ede
BUILD_IMAGE_NETBIRD_RELAY := netbirdio/relay:0.84.0@sha256:a6f26047934d0a9cf03e644e91f37c4816366ccd0e755347c8b00b2619e86a3f
BUILD_IMAGE_NETBIRD_DASHBOARD := netbirdio/dashboard:v2.100.0@sha256:0b06599c1ce9b91448faf3fae682fe66603c67034b2bd093dc66165283d031cd

BASE_IMAGE = $(BASE_IMAGE_REPOSITORY):trixie-slim@$(BASE_IMAGE_DIGEST_trixie-slim)
