# get-reference-genomes
Gets reference genomes from UCSC and prepares them for use by IGV.js.

The [gh-pages site](https://refinery-platform.github.io/get-reference-genomes)
for this repo demonstrates how these reference genomes can be used.

## Setup

Install pip dependencies, and make sure `twoBitToFa` and `bedToBigBed` are on your `PATH`:

```
pip install -r requirements.txt
wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/twoBitToFa && chmod a+x twoBitToFa
wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bedToBigBed && chmod a+x bedToBigBed
```

## Usage

```
./tools/genome-to-local.sh GENOME1 [ GENOME2 ... ]
# or, if you have AWS credentials in place:
./tools/genome-to-s3.sh GENOME1 [ GENOME2 ... ]
```

## Development

During development, 
- Run `tests/test.sh` to confirm that the scripts perform the expected transformations.
- Load `index.html` to see how the test fixtures would be rendered.
