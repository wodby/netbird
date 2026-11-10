# Build inputs shared by local builds and CI. Updated by wodby/images.
# Each digest identifies the complete multi-platform image index.
BASE_IMAGE_REPOSITORY := debian
BASE_IMAGE_VERSION_SUFFIX :=

BASE_IMAGE_DIGEST_trixie-slim := sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2

# NetBird's own images, which the build copies the binaries and the dashboard from. The server and relay tags match
# NETBIRD_VER and the dashboard tag NETBIRD_DASHBOARD_VER.
BUILD_IMAGE_NETBIRD_SERVER := netbirdio/netbird-server:0.82.1@sha256:7cf0268831221d2d4cc8ca89ca3d8d9419f890f0abb72c1fa9d00aae07e0b788
BUILD_IMAGE_NETBIRD_RELAY := netbirdio/relay:0.82.1@sha256:9f917fb289872b3f15f139ed061ba6543a2b843aa41f41d9fb5c9df0c755ec7d
BUILD_IMAGE_NETBIRD_DASHBOARD := netbirdio/dashboard:v2.96.1@sha256:dbbec81fff42f6eb42ce0594033eafc1ae1c69b25a2595cc90e8097f0bcd468d

BASE_IMAGE = $(BASE_IMAGE_REPOSITORY):trixie-slim@$(BASE_IMAGE_DIGEST_trixie-slim)
