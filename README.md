# get-reference-genomes
Gets reference genomes from UCSC and prepares them for use by IGV.js:
[Sample output](https://refinery-platform.github.io/get-reference-genomes)


```
USAGE:
  ./genome-to-local.sh GENOME1 [ GENOME2 ... ]
or
  ./genome-to-s3.sh GENOME1 [ GENOME2 ... ]
```

During development, 
- Run `tests/test.sh` to confirm that the scripts perform the expected transformations.
- Load `index.html` to see how the test fixtures would be rendered.
