 #!/bin/bash
set -o errexit
set -o nounset

warn() { echo "$@" >&2; }

BASE_URL=s3://data.cloud.refinery-platform.org/data/igv-reference
for ASSEMBLY in `aws s3 ls $BASE_URL/ | fgrep PRE | perl -pne 's{\s+PRE (.+)/}{\1}'`; do
    FILES=`aws s3 ls $BASE_URL/$ASSEMBLY/ | perl -pne 's/^\S+\s+\S+\s+\S+\s+//'`
    CYTOBAND=`echo "$FILES" | fgrep 'cytoBand.txt' || true`
    FA=`echo "$FILES" | fgrep $ASSEMBLY'.fa' | fgrep -v .fai || true`
    FAI=`echo "$FILES" | fgrep $ASSEMBLY'.fa.fai' || true`
    warn "debug: $ASSEMBLY -> $CYTOBAND / $FA / $FAI"
    if [ ! -z "$CYTOBAND" ] && [ ! -z "$FA" ] && [ ! -z "$FAI" ]; then
        echo $ASSEMBLY
    fi
done