#!/usr/bin/env python3
"""Signs in to NetBird's built-in identity provider as the administrator, the way the dashboard does (authorization
code with PKCE through the email and password form), and prints a new reusable setup key.

Usage: setup_key.py <base URL to send requests to> <public URL the server is configured with> <email> <password>
"""

import base64
import hashlib
import html
import http.cookiejar
import json
import re
import secrets
import sys
import urllib.error
import urllib.parse
import urllib.request


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def main():
    base, public, email, password = sys.argv[1:5]
    jar = http.cookiejar.CookieJar()
    # The server is local; proxies from the environment must not be used.
    opener = urllib.request.build_opener(
        urllib.request.ProxyHandler({}), urllib.request.HTTPCookieProcessor(jar), NoRedirect()
    )

    def request(url, data=None, headers=None):
        # Redirects point at the public address; send them to the address this script can reach.
        if url.startswith(public):
            url = base + url[len(public):]
        elif url.startswith("/"):
            url = base + url
        req = urllib.request.Request(url, data=data, headers=headers or {})
        try:
            with opener.open(req, timeout=30) as resp:
                return resp.status, resp.headers, resp.read().decode()
        except urllib.error.HTTPError as err:
            return err.code, err.headers, err.read().decode()

    verifier = secrets.token_urlsafe(48)
    challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).rstrip(b"=").decode()
    redirect_uri = public + "/nb-auth"
    query = urllib.parse.urlencode({
        "client_id": "netbird-dashboard",
        "redirect_uri": redirect_uri,
        "response_type": "code",
        "scope": "openid profile email groups",
        "state": "test",
        "code_challenge": challenge,
        "code_challenge_method": "S256",
    })

    url = "/oauth2/auth?" + query
    form_action = None
    for _ in range(10):
        status, headers, body = request(url)
        if status in (301, 302, 303):
            url = headers["Location"]
            continue
        match = re.search(r'<form method="post" action="([^"]+)"', body)
        if not match:
            sys.exit(f"no sign-in form at {url} (HTTP {status})")
        form_action = html.unescape(match.group(1))
        break
    if not form_action:
        sys.exit("too many redirects before the sign-in form")

    data = urllib.parse.urlencode({"login": email, "password": password}).encode()
    status, headers, body = request(form_action, data=data)
    code = None
    for _ in range(10):
        if status not in (301, 302, 303):
            sys.exit(f"sign-in failed (HTTP {status})")
        location = headers["Location"]
        if location.startswith(redirect_uri):
            code = urllib.parse.parse_qs(urllib.parse.urlparse(location).query)["code"][0]
            break
        status, headers, body = request(location)
    if not code:
        sys.exit("no authorization code")

    data = urllib.parse.urlencode({
        "grant_type": "authorization_code",
        "code": code,
        "redirect_uri": redirect_uri,
        "client_id": "netbird-dashboard",
        "code_verifier": verifier,
    }).encode()
    status, _, body = request("/oauth2/token", data=data)
    if status != 200:
        sys.exit(f"token request failed (HTTP {status}): {body}")
    token = json.loads(body)["access_token"]

    auth = {"Authorization": "Bearer " + token, "Content-Type": "application/json"}
    status, _, body = request("/api/users/current", headers=auth)
    if status != 200:
        sys.exit(f"current user request failed (HTTP {status}): {body}")
    user = json.loads(body)
    if user.get("role") != "owner":
        sys.exit(f"expected the owner role, got {user.get('role')}")

    data = json.dumps({"name": "test", "type": "reusable", "expires_in": 3600, "auto_groups": []}).encode()
    status, _, body = request("/api/setup-keys", data=data, headers=auth)
    if status != 200:
        sys.exit(f"setup key request failed (HTTP {status}): {body}")
    print(json.loads(body)["key"])


if __name__ == "__main__":
    main()
