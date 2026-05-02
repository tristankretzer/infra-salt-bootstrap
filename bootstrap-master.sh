#!/bin/bash

set -euo pipefail

curl -fsSL https://github.com/saltstack/salt-bootstrap/releases/latest/download/bootstrap-salt.sh | sh -s -- -X stable 3006

git clone https://github.com/tristankretzer/infra-salt-bootstrap.git /tmp/salt-bootstrap

salt-call --local --file-root=/tmp/salt-bootstrap/master state.sls bootstrap
