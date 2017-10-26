 #!/bin/bash
set -o errexit
set -o nounset

warn() { echo "$@" >&2; }

json () {
  python -c 'from sys import argv; from json import dumps; print dumps( dict([ (k, {}) for k in argv[1:] ]) )' $@
}

DIR=`dirname $0`
JSON=`json $($DIR/ls-s3.sh)`
warn "json: $JSON"
echo "$JSON" > /tmp/index.json

# Tried the <( ) syntax, but s3 cp couldn't handle it.

aws s3 cp --region us-east-1 \
    /tmp/index.json s3://data.cloud.refinery-platform.org/data/igv-reference/index.json