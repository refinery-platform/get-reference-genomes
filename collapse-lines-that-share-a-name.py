import fileinput

# Given a BED file, collapses sequential lines which match on the "name" field.

def merge_fields(a, b):
    if not b:
        b = a
    if not a:
        a = b
    earliest_start = min(a[1], b[1])
    latest_end = max(a[2], b[2])
    earliest_think_start = min(a[6], b[6]) # I don't really understand thinkStart/End.
    latest_think_end = min(a[7], b[7])
    a_other = [a[0], a[3], a[4], a[8]]
    b_other = [b[0], b[3], b[4], b[8]]
    # TODO: They can differ on strand. Just choosing one arbitrarily for now.
    if a_other != b_other:
        raise Exception('Expected fields to match, but instead: %s != %s' % (a_other, b_other))
    merged = [a[0], earliest_start, latest_end] + \
             a[3:6] + \
             [
                 earliest_think_start, latest_think_end, a[8],
                 '1', str(int(latest_end) - int(earliest_start)), '0']
    return merged

last_name = None
merged_fields = []
for line in fileinput.input():
    # BED columns: (https://genome.ucsc.edu/FAQ/FAQformat#format1)
    #   chrom / chromStart / chromEnd / name /
    #   score / strand / thinkStart / thinkEnd / itemRgb
    #   blockCount / blockSizes / blockStarts
    fields = line.rstrip().split("\t")
    name = fields[3]
    if name == last_name or not last_name:
        merged_fields = merge_fields(merged_fields, fields)
    else:
        print "\t".join(merged_fields)
        merged_fields = fields
    last_name = name

print "\t".join(merged_fields)