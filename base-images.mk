# Build inputs shared by local builds and CI. Updated by wodby/images.
# Each digest identifies the complete multi-platform image index.
BASE_IMAGE_REPOSITORY := debian
BASE_IMAGE_VERSION_SUFFIX :=

BASE_IMAGE_DIGEST_trixie-slim := sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2

# NetBird's own images, which the build copies the binaries and the dashboard from. The server and relay tags match
# NETBIRD_VER and the dashboard tag NETBIRD_DASHBOARD_VER.
BUILD_IMAGE_NETBIRD_SERVER := netbirdio/netbird-server:0.82.0@sha256:7b5b53b2dc8bc25639f791cf72d47cf86911894ff3f8a97cb79bab9be958109c
BUILD_IMAGE_NETBIRD_RELAY := netbirdio/relay:0.82.0@sha256:8f6b9e4193653ede89e83dd4aa4e2cf2562579b3e2481dcf259a7ab28bcd5fa1
BUILD_IMAGE_NETBIRD_DASHBOARD := netbirdio/dashboard:v2.96.0@sha256:340b13c00b84349572a2acc5605e907cb09250a9e6461c757097eabdb8e02f2c

BASE_IMAGE = $(BASE_IMAGE_REPOSITORY):trixie-slim@$(BASE_IMAGE_DIGEST_trixie-slim)
