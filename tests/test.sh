#!/bin/bash
set -o errexit
set -o nounset
#set -o verbose
set -o xtrace

err_report() {
    echo "FAIL: Error on line $1"
}
trap 'err_report $LINENO' ERR

chmod a+x ./genome-to-s3.sh

# Install dependencies
mkdir -p vendor
PATH=$PATH:vendor

which faidx || pip install --user pyfaidx
which twoBitToFa ||  ( wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/twoBitToFa \
                       && chmod a+x twoBitToFa && mv twoBitToFa vendor )
which bedToBigBed || ( wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bedToBigBed \
                       && chmod a+x bedToBigBed && mv bedToBigBed vendor )

# Expect usage message if no args
./genome-to-local.sh 2>&1 | grep 'USAGE'

# Expect error message if invalid genome
./genome-to-local.sh no-such-genome 2>&1 | grep 'some error message'

echo 'PASS'

