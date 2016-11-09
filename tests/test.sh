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
PATH=$PATH:`pwd`

which faidx || pip install --user pyfaidx
which twoBitToFa ||  ( wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/twoBitToFa \
                       && chmod a+x twoBitToFa )
which bedToBigBed || ( wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bedToBigBed \
                       && chmod a+x bedToBigBed )

# In the tests below, we want to see the entire output, and grep for particular strings.
# "tee /dev/tty" does this for us: STDOUT is duplicated,
# with one going to the screen, and the other going to grep.

# Expect usage message if no args
./genome-to-local.sh 2>&1 | tee /dev/tty | grep 'USAGE'

# Expect error message if invalid genome
./genome-to-local.sh no-such-genome 2>&1 | tee /dev/tty | grep 'no-such-genome is not available at'

# Expect successful download
./genome-to-local.sh hg19 2>&1 | tee /dev/tty | grep 'Disk space used'

echo 'PASS'

