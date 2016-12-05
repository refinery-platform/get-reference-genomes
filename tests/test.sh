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

python --version
which faidx || pip install --user pyfaidx==0.4.8.1 && which faidx && faidx --version
which twoBitToFa ||  ( wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/twoBitToFa \
                       && chmod a+x twoBitToFa )
which bedToBigBed || ( wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bedToBigBed \
                       && chmod a+x bedToBigBed )

# In the tests below, we want to see the entire output, and grep for particular strings.
# "tee /dev/tty" does this for us: STDOUT is duplicated,
# with one going to the screen, and the other going to grep.

PORT=8000
nc -z 127.0.0.1 $PORT && echo "Port $PORT is in use" && exit 1
(cd tests/input/ && python -m SimpleHTTPServer $PORT) &
sleep 1
ps # Is it running?

# Expect usage message if no args
export TEST_DEST=/tmp/genomes-test/`date +"%Y-%m-%d_%H-%M-%S_no_args"`
bash -x genome-to-local.sh 2>&1 | tee /dev/tty | grep 'USAGE'


# Expect error message if invalid genome
#TESTING='true' ./genome-to-local.sh no-such-genome 2>&1 | tee /dev/tty | grep 'no-such-genome is not available at'


# Expect successful download and unzip
G=hg19
export TEST_DEST=/tmp/genomes-test/`date +"%Y-%m-%d_%H-%M-%S_good"`
bash -x genome-to-local.sh $G 2>&1 | tee /tmp/log.txt
# Directory for tee must already exist, so just replacing /tmp with $TEST_DEST won't work.

grep $TEST_DEST/$G/cytoBand.txt      /tmp/log.txt
grep $TEST_DEST/$G/hg19.fa           /tmp/log.txt
grep $TEST_DEST/$G/hg19.fa.fai       /tmp/log.txt
grep $TEST_DEST/$G/refGene.bed       /tmp/log.txt
grep $TEST_DEST/$G/refGene.bed.tbi   /tmp/log.txt

# Compare the files we've produced to the 10-line fixtures;
# "grep -v" to ignore intermediate files in /tmp/genomes.
# TODO: The bed.index file ideally would match, too.
for FILE in `ls $TEST_DEST/$G | grep -v 2bit | grep -v refGene.txt | grep -v bed.tbi`; do
  diff <(head $TEST_DEST/$G/$FILE) tests/output/$FILE.head
done

echo 'PASS'

