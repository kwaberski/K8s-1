#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace

MITMPROXY_PATH="/home/mitm/.mitmproxy"

if [[ "$1" = "mitmdump" || "$1" = "mitmproxy" || "$1" = "mitmweb" ]]; then
  mkdir -p "$MITMPROXY_PATH"
  chown -R mitm:mitm "$MITMPROXY_PATH"
  su-exec mitm "$@"
else
  exec "$@"
fi