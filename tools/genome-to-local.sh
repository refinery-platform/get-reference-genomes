#!/bin/bash
set -o errexit
set -o nounset
#set -o verbose
#set -o xtrace
set -o pipefail

### Helper functions

die() { echo "$@" 1>&2; exit 1; }
warn() { echo "$@" 1>&2; }


download_and_unzip() {
  # $1 will include one parent directory.
  BASE=`basename $1`
  if [ -e $BASE.gz ] || [ -e $BASE ]
    then warn "$BASE.gz or $BASE already exists: skip download"
    else curl -O --fail $BASE_URL$1.gz \
      || curl -O --fail $BASE_URL$1 \
      || warn "neither $1.gz nor $1 is available" 
  fi

  if [ -e $BASE.gz ]; then
    if [ -e $BASE ]
      then warn "$BASE already exists: skip unzip"
      else gunzip $BASE.gz
    fi
  fi
}


### Check for dependencies

which faidx > /dev/null || die 'Install faidx:
- "pip install pyfaidx" makes "faidx" available on command line.
- or:
  - download source from http://www.htslib.org/download/
  - make and install
  - make alias for "samtools faidx"'

which twoBitToFa > /dev/null || die 'Install twoBitToFa:
Choose the directory of your OS on http://hgdownload.soe.ucsc.edu/admin/exe/,
download "twoBitToFa", and "chmod a+x". (Or build from source.)'

which bedToBigBed > /dev/null || die 'Install bedToBigBed:
Choose the directory of your OS on http://hgdownload.soe.ucsc.edu/admin/exe/,
download "bedToBigBed", and "chmod a+x". (Or build from source.)'


### Main

# We cd before calling the python script, so we need an absolute path
pushd `dirname $BASH_SOURCE` > /dev/null
UTILS_DIR=$PWD/../utils
popd > /dev/null

if [ -z "${GENOME_TEST_TMP:=}" ] # Assign null string if not already set.
  then LOCAL=/tmp/genomes
  else LOCAL=/tmp/genome/$GENOME_TEST_TMP
fi

mkdir -p $LOCAL

if [ $# -eq 0 ]; then
  die "USAGE:
$BASH_SOURCE GENOME1 [ GENOME2 ... ]
Fetches reference genomes from UCSC, unzips, and indexes."
fi

for GENOME in $@; do
  echo # Blank line for readability
  echo "Starting $GENOME..."

  if [ -z "${GENOME_CACHE_URL:=}" ]
    # For development, you can set up a local cache, rather than downloading from UCSC each time.
    then BASE_URL=ftp://hgdownload.cse.ucsc.edu/goldenPath/$GENOME/
    else BASE_URL=$GENOME_CACHE_URL/$GENOME/
  fi
  curl --fail $BASE_URL || die "$GENOME is not available at $BASE_URL"

  cd $LOCAL
  mkdir -p $GENOME
  cd $GENOME
  
  download_and_unzip bigZips/$GENOME.2bit
  if [ -e $GENOME.2bit ]; then
    if [ -e $GENOME.fa ]
      then warn "$GENOME.fa already exists: will not regenerate"
      else twoBitToFa $GENOME.2bit $GENOME.fa
    fi
  fi

  download_and_unzip bigZips/$GENOME.fa
  # Replace $GENOME.fa with upstream1000.fa to get a smaller file for testing.

  if [ -e $GENOME.fa.fai ]
    then warn "$GENOME.fa.fai already exists: will not regenerate"
    else faidx $GENOME.fa > /dev/null || warn 'FAI creation failed'
  fi

  download_and_unzip database/cytoBand.txt  
  if [ ! -e cytoBand.txt ]; then
    # "Ideo" seems to be more detailed?
    download_and_unzip database/cytoBandIdeo.txt \
      && mv cytoBandIdeo.txt cytoBand.txt \
      || warn "No cytoBand.txt for $GENOME"
    # TODO: Make a mock cytoBand, rather than tracking which are not available?
  fi

  download_and_unzip database/refGene.txt
  if [ -e refGene.bed ]
    then warn "refGene.bed already exists: will not regenerate"
    else python $UTILS_DIR/refgene-ucsc-to-bed.py refGene.txt | \
         sort -k1,1 -k2,2n > refGene.bed
  fi
  if [ -e refGene.collapsed.bed ]
    then warn "refGene.collapsed.bed already exists: will not regenerate"
    # Sort by the name column to bring name-duplicates together,
    # and then re-sort by address, as required by bedToBigBed.
    else python $UTILS_DIR/collapse-lines-that-differ-only-in-name.py refGene.bed | \
         sort -k4 | \
         python $UTILS_DIR/collapse-lines-that-share-a-name.py | \
         sort -k1,1 -k2,2n > refGene.collapsed.bed
  fi

  CHROM_URL=$BASE_URL/bigZips/$GENOME.chrom.sizes
  if [ -e refGene.bed.tbi ]
    then warn "refGene.bed.tbi already exists: will not regenerate"
    else bedToBigBed -type=bed4+8 refGene.bed $CHROM_URL refGene.bed.tbi
  fi
  if [ -e refGene.collapsed.bed.tbi ]
    then warn "refGene.collapsed.bed.tbi already exists: will not regenerate"
    else bedToBigBed -type=bed4+8 refGene.collapsed.bed $CHROM_URL refGene.collapsed.bed.tbi
  fi

done

echo 'Disk space used:'
du -ah $LOCAL
