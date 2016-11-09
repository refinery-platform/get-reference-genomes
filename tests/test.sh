#!/bin/bash
set -o errexit
set -o nounset
#set -o verbose
set -o xtrace

err_report() {
    echo "FAIL: Error on line $1"
}
trap 'err_report $LINENO' ERR

# Expect usage message if no args
./genome-to-s3.sh 2>&1 | grep 'USAGE'

# Install dependencies
which faidx || pip install pyfaidx
which twoBitToFa ||  ( wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/twoBitToFa \
                       && chmod a+x twoBitToFa && mv twoBitToFa /usr/local/bin )
which bedToBigBed || ( wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bedToBigBed \
                       && chmod a+x bedToBigBed && mv bedToBigBed /usr/local/bin ) 

# Expect error message if invalid genome
./genome-to-s3.sh no-such-genome 2>&1 | grep 'some error message'

echo 'PASS'

