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

G=hg19

# Expect successful download and unzip
./genome-to-local.sh $G 2>&1 | tee /tmp/log.txt

grep '/tmp/genomes/$G/cytoBand.txt' /tmp/log.txt
grep '/tmp/genomes/$G/hg19.fa' /tmp/log.txt
grep '/tmp/genomes/$G/hg19.fa.fai' /tmp/log.txt
grep '/tmp/genomes/$G/refGene.bed' /tmp/log.txt
grep '/tmp/genomes/$G/refGene.bed.index' /tmp/log.txt

for FILE in `ls /tmp/genomes/$G | grep -v 2bit`; do 
  diff <(head /tmp/genomes/$G/$FILE) tests/$FILE.head
done

echo 'PASS'

