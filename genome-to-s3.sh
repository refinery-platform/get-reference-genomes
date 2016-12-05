 #!/bin/bash
set -o errexit
set -o nounset


### Helper functions

die() { echo "$@" 1>&2; exit 1; }
warn() { echo "$@" 1>&2; }


### Check for dependencies

which aws > /dev/null || die 'Install aws-cli'

aws s3 ls > /dev/null || die 'Check aws-cli credentials'


### Main

LOCAL=/tmp/genomes

mkdir -p $LOCAL

if [[ $# -eq 0 ]]; then
  die "USAGE:
$0 GENOME1 [ GENOME2 ... ]
Fetches reference genomes from UCSC, unzips, indexes, and uploads to S3."
fi

`dirname $BASH_SOURCE`/genome-to-local.sh $@

aws s3 sync --exclude "*.gz" --exclude "*.2bit" --region us-east-1 \
    $LOCAL s3://data.cloud.refinery-platform.org/data/igv-reference

echo 'Delete the cache to free up some disk.'
du -h $LOCAL
