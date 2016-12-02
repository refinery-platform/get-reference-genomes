#!/bin/bash
set -o errexit
set -o nounset
#set -o verbose
set -o xtrace

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

if [ -z "$TEST_DEST" ]
  then LOCAL=/tmp/genomes
  else LOCAL="$TEST_DEST"
fi

mkdir -p $LOCAL

if [[ $# -eq 0 ]]; then
  die "USAGE:
$0 GENOME1 [ GENOME2 ... ]
Fetches reference genomes from UCSC, unzips, indexes, and uploads to S3."
fi

for GENOME in $@; do
  echo # Blank line for readability
  echo "Starting $GENOME..."

  if [ -z "$TEST_DEST" ]
    then BASE_URL=ftp://hgdownload.cse.ucsc.edu/goldenPath/$GENOME/
    else BASE_URL=http://localhost:8000/
  fi
  curl --fail $BASE_URL || die "$GENOME is not available at $BASE_URL"

  cd $LOCAL
  mkdir -p $GENOME
  cd $GENOME
  
  download_and_unzip bigZips/$GENOME.2bit
  if [[ -e $GENOME.2bit ]]; then
    if [[ -e $GENOME.fa ]]
      then warn "$GENOME.fa already exists: will not regenerate"
      else twoBitToFa $GENOME.2bit $GENOME.fa
    fi
  fi

  download_and_unzip bigZips/$GENOME.fa
  # Replace $GENOME.fa with upstream1000.fa to get a smaller file for testing.

  if [[ -e $GENOME.fa.fai ]]
    then warn "$GENOME.fa.fai already exists: will not regenerate"
    else faidx $GENOME.fa > /dev/null || warn 'FAI creation failed'
  fi

  download_and_unzip database/cytoBand.txt  
  if [[ ! -e cytoBand.txt ]]; then
    # "Ideo" seems to be more detailed?
    download_and_unzip database/cytoBandIdeo.txt \
      && mv cytoBandIdeo.txt cytoBand.txt \
      || warn "No cytoBand.txt for $GENOME"
    # TODO: Make a mock cytoBand, rather than tracking which are not available?
  fi

  download_and_unzip database/refGene.txt
  # refGene columns: (ftp://hgdownload.cse.ucsc.edu/goldenPath/hg19/database/refGene.sql)
  #   bin / name / chrom / strand / txStart / txEnd / cdsStart / cdsEnd /
  #   exonCount / exonStarts / exonEnds / score / name2 / cdsStartStat / cdsEndStat / exonFrames
  # BED columns: (https://genome.ucsc.edu/FAQ/FAQformat#format1)
  #   chrom / chromStart / chromEnd / name / ...
  if [[ -e refGene.bed ]]
    then warn "refGene.bed already exists: will not regenerate"
    else paste <(cut -f 3,5,6,13 refGene.txt) | sort -k1,1 -k2,2n > refGene.bed
  fi

  CHROM_URL=$BASE_URL/bigZips/$GENOME.chrom.sizes
  if [[ -e refGene.bed.tbi ]]
    then warn "refGene.bed.tbi already exists: will not regenerate"
    else bedToBigBed refGene.bed $CHROM_URL refGene.bed.tbi
  fi
done

echo 'Disk space used:'
du -ah $LOCAL
