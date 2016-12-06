import fileinput
from os.path import commonprefix

# Given a BED file, collapses lines which differ only on the "name" field.

def print_combined(names, except_name):
    if len(names) == 1:
        combo_name = names[0]
    else:
        prefix = commonprefix(names)
        if len(prefix) > 4:
            combo_name = prefix + '*'
        else:
            names.sort()
            combo_name = '/'.join(names)
    print "\t".join(except_name[:3] + [combo_name] + except_name[3:])

last_except_name = []
last_names = []
for line in fileinput.input():
    # BED columns: (https://genome.ucsc.edu/FAQ/FAQformat#format1)
    #   chrom / chromStart / chromEnd / name /
    #   score / strand / thinkStart / thinkEnd / itemRgb
    #   blockCount / blockSizes / blockStarts
    fields = line.rstrip().split("\t")
    name = fields[3]
    except_name = fields[:3] + fields[4:]
    if except_name == last_except_name or not last_names:
        last_names.append(name)
    else:
        print_combined(last_names, last_except_name)
        last_names = [name]
    last_except_name = except_name

print_combined(last_names, last_except_name)
