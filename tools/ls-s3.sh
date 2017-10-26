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

    # TODO: These are not being generated correctly right now, but when they are...

    BED=`echo "$FILES" | fgrep 'refGene.bed.head' || true`
    BED_TBI=`echo "$FILES" | fgrep 'refGene.bed.tbi.head' || true`

    COLLAPSED_BED=`echo "$FILES" | fgrep 'refGene.collapsed.bed.head' || true`
    COLLAPSED_BED_TBI=`echo "$FILES" | fgrep 'refGene.collapsed.bed.tbi.head' || true`

    warn "debug: $ASSEMBLY -> $CYTOBAND / $FA / $FAI / $BED / $BED_TBI / $COLLAPSED_BED / $COLLAPSED_BED_TBI"
    if [ ! -z "$CYTOBAND" ] && [ ! -z "$FA" ] && [ ! -z "$FAI" ]; then
        echo $ASSEMBLY
    fi
done