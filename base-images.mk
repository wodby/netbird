# Build inputs shared by local builds and CI. Updated by wodby/images.
# Each digest identifies the complete multi-platform image index.
BASE_IMAGE_REPOSITORY := debian
BASE_IMAGE_VERSION_SUFFIX :=

BASE_IMAGE_DIGEST_trixie-slim := sha256:f6b08b09a05725f9431502d3b5714f5c4576e82c1a84fa1debe0c24a7e0c3ec4

# NetBird's own images, which the build copies the binaries and the dashboard from. The server and relay tags match
# NETBIRD_VER and the dashboard tag NETBIRD_DASHBOARD_VER.
BUILD_IMAGE_NETBIRD_SERVER := netbirdio/netbird-server:0.82.0@sha256:7b5b53b2dc8bc25639f791cf72d47cf86911894ff3f8a97cb79bab9be958109c
BUILD_IMAGE_NETBIRD_RELAY := netbirdio/relay:0.82.0@sha256:8f6b9e4193653ede89e83dd4aa4e2cf2562579b3e2481dcf259a7ab28bcd5fa1
BUILD_IMAGE_NETBIRD_DASHBOARD := netbirdio/dashboard:v2.96.0@sha256:340b13c00b84349572a2acc5605e907cb09250a9e6461c757097eabdb8e02f2c

BASE_IMAGE = $(BASE_IMAGE_REPOSITORY):trixie-slim@$(BASE_IMAGE_DIGEST_trixie-slim)
