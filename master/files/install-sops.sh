#!/bin/sh

set -eu

SOPS_VERSION=$(curl -fsSLI -o /dev/null -w '%{url_effective}\n' \
  https://github.com/getsops/sops/releases/latest | sed 's|.*/||')
BASE_URL="https://github.com/getsops/sops/releases/download/${SOPS_VERSION}"

case "$(uname -m)" in
  x86_64)  ARCH=amd64 ;;
  aarch64) ARCH=arm64 ;;
  armv7l)  ARCH=arm ;;
  *)       echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT
cd "$WORK_DIR"

BINARY="sops-${SOPS_VERSION}.linux.${ARCH}"
CHECKSUMS_BASE="sops-${SOPS_VERSION}.checksums"

curl -fsSLO "${BASE_URL}/${CHECKSUMS_BASE}.txt"
curl -fsSLO "${BASE_URL}/${CHECKSUMS_BASE}.sigstore.json"
curl -fsSLO "${BASE_URL}/${BINARY}"

cosign verify-blob "${CHECKSUMS_BASE}.txt" \
  --bundle "${CHECKSUMS_BASE}.sigstore.json" \
  --certificate-identity-regexp=https://github.com/getsops \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com

sha256sum -c "${CHECKSUMS_BASE}.txt" --ignore-missing

install -m 0755 "${BINARY}" /usr/local/bin/sops
