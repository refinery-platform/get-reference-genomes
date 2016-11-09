 #!/bin/bash
set -o errexit
set -o nounset


### Helper functions

die() { echo "$@" 1>&2; exit 1; }
warn() { echo "$@" 1>&2; }

download_and_unzip() {
  # $1 will include one parent directory.
  BASE=`basename $1`
  if [ -e $BASE.gz ] || [ -e $BASE ]
    then warn "$BASE.gz or $BASE already exists: skip download"
    else ftp ftp://hgdownload.cse.ucsc.edu/goldenPath/$GENOME/$1.gz \
      || ftp ftp://hgdownload.cse.ucsc.edu/goldenPath/$GENOME/$1 \
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

#which aws > /dev/null || die 'Install aws-cli'
#
#aws s3 ls > /dev/null || die 'Check aws-cli credentials'


### Main

LOCAL=/tmp/genomes

mkdir -p $LOCAL

if [[ $# -eq 0 ]]; then
  die "USAGE:
$0 GENOME1 [ GENOME2 ... ]
Fetches reference genomes from UCSC, unzips, indexes, and uploads to S3."
fi

for GENOME in $@; do
  echo # Blank line for readability
  echo "Starting $GENOME..."
  cd $LOCAL
  mkdir -p $GENOME  
  cd $GENOME
  
  download_and_unzip bigZips/$GENOME.2bit
  if [[ -e $GENOME.2bit ]]; then
    twoBitToFa $GENOME.2bit $GENOME.fa
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
  paste <(cut -f 3,5,6 refGene.txt) <(cut -f 2 refGene.txt) | sort -k1,1 -k2,2n > refGene.bed
  rm refGene.txt

  CHROM_URL=http://hgdownload.cse.ucsc.edu/goldenPath/$GENOME/bigZips/$GENOME.chrom.sizes
  bedToBigBed refGene.bed $CHROM_URL refGene.bed.index
done

#aws s3 sync --exclude "*.gz" --exclude "*.2bit" --region us-east-1 \
#    $LOCAL s3://data.cloud.refinery-platform.org/data/igv-reference

echo 'Delete the cache to free up some disk.'
du -h $LOCAL
