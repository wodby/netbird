#!/usr/bin/env bash

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

network="${NAME}-net"
volume="${NAME}-data"
client_image="netbirdio/netbird:${NETBIRD_VER}"
server="${NAME}"
url="http://netbird:8080"
admin_email="admin@example.com"
admin_password='Te$t pass"word'
cids=()

cleanup() {
    if [[ ${#cids[@]} -gt 0 ]]; then
        docker rm -vf "${cids[@]}" > /dev/null 2>&1 || true
    fi
    docker volume rm -f "${volume}" > /dev/null 2>&1 || true
    docker network rm "${network}" > /dev/null 2>&1 || true
}
trap cleanup EXIT

fail() {
    echo "FAILED: $*"
    for cid in "${cids[@]}"; do
        echo "--- logs of ${cid}"
        docker logs --tail 60 "${cid}" 2>&1 || true
    done
    exit 1
}

run() {
    docker exec "${server}" "${@}"
}

start_server() {
    cids+=("$(docker run -d --name "${server}" --network "${network}" --network-alias netbird \
        -p 127.0.0.1::8080 \
        -e NETBIRD_URL="${url}" \
        -e NETBIRD_RELAY_URL=http://netbird:8082 \
        -e NETBIRD_AUTH_SECRET=relay-secret \
        -e NETBIRD_STORE_ENCRYPTION_KEY=store-secret \
        -e NETBIRD_SESSION_COOKIE_ENCRYPTION_KEY=cookie-secret \
        -e NETBIRD_ADMIN_EMAIL="${admin_email}" \
        -e NETBIRD_ADMIN_PASSWORD="${admin_password}" \
        -e NETBIRD_DISABLE_GEOLITE_UPDATE=true \
        -v "${volume}:/var/lib/netbird" \
        "${IMAGE}")")
}

# The first start downloads GeoLite databases, which can take a minute or two.
wait_ready() {
    for _ in $(seq 1 240); do
        if run curl -fsS -o /dev/null http://localhost:8080/oauth2/.well-known/openid-configuration 2>/dev/null; then
            return
        fi
        sleep 1
    done
    fail "the server didn't become ready"
}

docker network create "${network}" > /dev/null
docker volume create "${volume}" > /dev/null

start_server
echo -n "Waiting for the server... "
wait_ready
echo "OK"

echo -n "Checking the versions... "
# The binaries have no version command; the server logs its version at start. The relay comes from the same release.
docker logs "${server}" 2>&1 | grep -q "management server version ${NETBIRD_VER}\$" || fail "the server is not ${NETBIRD_VER}"
echo "OK"

echo -n "Checking the server runs as a regular user... "
[[ "$(run id -u)" == 1000 ]] || fail "not uid 1000"
echo "OK"

echo -n "Checking the dashboard... "
run curl -fsS http://localhost:8080/ | grep -q "<html" || fail "no dashboard page"
run curl -fsS http://localhost:8080/peers | grep -q "<html" || fail "no dashboard page for /peers"
run cat /usr/share/nginx/html/OidcTrustedDomains.js | grep -q "${url}" || fail "dashboard isn't configured"
run curl -fsS -D - -o /dev/null http://localhost:8080/ | grep -q "connect-src 'self'" || fail "no Content-Security-Policy"
echo "OK"

echo -n "Checking the API, sign-in and gRPC over cleartext HTTP/2... "
[[ "$(run curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/api/users)" == 401 ]] || fail "the API answers without a token"
run curl -fsS http://localhost:8080/oauth2/.well-known/openid-configuration | grep -q "\"issuer\": *\"${url}/oauth2\"" \
    || fail "wrong issuer"
[[ "$(run curl -s -o /dev/null -w '%{http_version}' --http2-prior-knowledge http://localhost:8080/api/users)" == 2 ]] \
    || fail "no cleartext HTTP/2"
# An empty request is invalid, but any gRPC status shows the request reached the gRPC server over HTTP/2.
for _ in $(seq 1 30); do
    grpc_status="$(run curl -s -v -o /dev/null --http2-prior-knowledge -X POST -H 'Content-Type: application/grpc' \
        -H 'TE: trailers' --data-binary '' http://localhost:8080/management.ManagementService/GetServerKey 2>&1 \
        | tr -d '\r' | sed -n 's/^< grpc-status: //Ip')"
    [[ -z "${grpc_status}" ]] || break
    sleep 1
done
[[ -n "${grpc_status}" ]] || fail "management gRPC didn't answer"
echo "OK"

echo -n "Checking the relay answers WebSocket... "
status_line="$(run curl -sS -i --http1.1 --max-time 2 -H 'Connection: Upgrade' -H 'Upgrade: websocket' \
    -H 'Sec-WebSocket-Version: 13' -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' \
    http://localhost:8082/relay 2>/dev/null | head -n 1 || true)"
[[ "${status_line}" == *101* ]] || fail "relay handshake: ${status_line}"
echo "OK"

echo -n "Checking the secrets are kept from the logs and the config... "
! docker logs "${server}" 2>&1 | grep -q -e relay-secret -e store-secret -e "${admin_password}" || fail "a secret is in the logs"
! run grep -q -e "${admin_password}" -e store-secret /run/netbird/config.yaml || fail "a plain secret is in the config"
[[ "$(run stat -c %a /run/netbird/config.yaml)" == 600 ]] || fail "the config is readable by others"
echo "OK"

echo -n "Signing in as the administrator and creating a setup key... "
host_port="$(docker port "${server}" 8080/tcp | head -n 1)"
setup_key="$(python3 ./setup_key.py "http://${host_port}" "${url}" "${admin_email}" "${admin_password}" 2>/tmp/setup_key.err)" \
    || fail "couldn't sign in or create a setup key: $(cat /tmp/setup_key.err)"
echo "OK"

start_client() {
    cids+=("$(docker run -d --name "${NAME}-${1}" --hostname "${1}" --network "${network}" \
        --cap-add NET_ADMIN --cap-add SYS_ADMIN --cap-add SYS_RESOURCE --device /dev/net/tun \
        -e NB_SETUP_KEY="${setup_key}" \
        -e NB_MANAGEMENT_URL="${url}" \
        -e NB_FORCE_RELAY=true \
        "${client_image}")")
}

client_ip() {
    docker exec "${NAME}-${1}" netbird status --json 2>/dev/null \
        | python3 -c 'import json,sys; print(json.load(sys.stdin)["netbirdIp"].split("/")[0])' 2>/dev/null || true
}

echo -n "Connecting two peers through the relay... "
start_client peer-a
start_client peer-b
for _ in $(seq 1 60); do
    ip_b="$(client_ip peer-b)"
    if [[ -n "${ip_b}" ]] && docker exec "${NAME}-peer-a" ping -c 1 -W 2 "${ip_b}" > /dev/null 2>&1; then
        break
    fi
    ip_b=""
    sleep 2
done
[[ -n "${ip_b}" ]] || fail "peer-a can't reach peer-b"
docker exec "${NAME}-peer-a" netbird status --detail | grep -q "Connection type: Relayed" || fail "the peers aren't relayed"
echo "OK"

echo -n "Checking the account survives a restart... "
docker restart "${server}" > /dev/null
wait_ready
python3 ./setup_key.py "http://$(docker port "${server}" 8080/tcp | head -n 1)" "${url}" "${admin_email}" "${admin_password}" \
    > /dev/null || fail "couldn't sign in after a restart"
for _ in $(seq 1 60); do
    if docker exec "${NAME}-peer-a" ping -c 1 -W 2 "${ip_b}" > /dev/null 2>&1; then
        echo "OK"
        exit 0
    fi
    sleep 2
done
fail "the peers didn't reconnect after a restart"
