import fileinput

for line in fileinput.input():
    cols = line.split("\t")

    # refGene columns: (ftp://hgdownload.cse.ucsc.edu/goldenPath/hg19/database/refGene.sql)
    #   bin / name / chrom / strand / txStart / txEnd / cdsStart / cdsEnd /
    #   exonCount / exonStarts / exonEnds / score / name2 / cdsStartStat / cdsEndStat / exonFrames

    chrom = cols[2]
    txStart = cols[4]
    txEnd = cols[5]
    name = cols[12]
    strand = cols[3]
    exonCount = cols[8]

    cdsStart = cols[9].split(',')[0:-1] # Ignore null after trailing comma
    cdsEnd = cols[10].split(',')[0:-1]
    startEndPairs = zip(cdsStart, cdsEnd)
    sizes =  ','.join(map(lambda pair: str(int(pair[1])-int(pair[0])), startEndPairs))
    deltas = ','.join(map(lambda offset: str(int(offset)-int(txStart)), cdsStart))

    # BED columns: (https://genome.ucsc.edu/FAQ/FAQformat#format1)
    #   chrom / chromStart / chromEnd / name /
    #   score / strand / thinkStart / thinkEnd / itemRgb
    #   blockCount / blockSizes / blockStarts

    # Basing the target output on https://s3.amazonaws.com/igv.broadinstitute.org/annotations/hg19/genes/refGene.hg19.bed.gz

    output = [chrom, txStart, txEnd, name, '1000', strand,
              txEnd, txEnd, # TODO: Is this right?
              '.', exonCount,
              sizes, deltas]
    print "\t".join(output)
