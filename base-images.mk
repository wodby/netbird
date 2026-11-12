# Build inputs shared by local builds and CI. Updated by wodby/images.
# Each digest identifies the complete multi-platform image index.
BASE_IMAGE_REPOSITORY := debian
BASE_IMAGE_VERSION_SUFFIX :=

BASE_IMAGE_DIGEST_trixie-slim := sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2

# NetBird's own images, which the build copies the binaries and the dashboard from. The server and relay tags match
# NETBIRD_VER and the dashboard tag NETBIRD_DASHBOARD_VER.
BUILD_IMAGE_NETBIRD_SERVER := netbirdio/netbird-server:0.83.0@sha256:c353ffadb8a12de0c453ed5d3d074f15e7003b6231346fcfd86f206dd02bd5be
BUILD_IMAGE_NETBIRD_RELAY := netbirdio/relay:0.83.0@sha256:e42eb6426c4115b2f51c33e613e30f76308c00ce4c81c5d727af57b73295e62e
BUILD_IMAGE_NETBIRD_DASHBOARD := netbirdio/dashboard:v2.97.0@sha256:203b2dc90dc20d3fd45729caac7c922deb399586a68202e0a35be099720bac7d

BASE_IMAGE = $(BASE_IMAGE_REPOSITORY):trixie-slim@$(BASE_IMAGE_DIGEST_trixie-slim)
