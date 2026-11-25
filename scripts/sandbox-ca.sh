#!/bin/sh
# sandbox-ca.sh — trust/remove the sandbox egress CA inside a build container.
# Usage (inside the container): sh /tmp/sandbox-ca.sh trust|remove
# The CA cert is bind-mounted at /tmp/hatch-egress-ca.crt by the build.
# - On the sandbox VM the mounted cert is real and non-empty: trust it so
#   dnf can reach the Fedora mirrors through the MITM egress proxy.
# - On a normal host / CI the mount source is an empty placeholder file:
#   skip trusting (there is no proxy) and do nothing. dnf just works.
# Never leaves the CA trusted after the install: the Containerfile calls
# `remove` in the same RUN that called `trust`.
set -eu
CERT=/tmp/hatch-egress-ca.crt
ANCHOR=/etc/pki/ca-trust/source/anchors/hatch-egress-ca.crt
case "${1:-}" in
  trust)
    if [ -s "$CERT" ]; then
      cp "$CERT" "$ANCHOR"
      update-ca-trust
      echo "sandbox-ca: trusted egress CA"
    else
      echo "sandbox-ca: no CA mounted (normal host/CI), skipping trust"
    fi
    ;;
  remove)
    rm -f "$ANCHOR"
    update-ca-trust
    echo "sandbox-ca: removed egress CA (if any)"
    ;;
  *)
    echo "usage: $0 trust|remove" >&2
    exit 2
    ;;
esac
