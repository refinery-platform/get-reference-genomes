import fileinput
from bed import Record

# Given a BED file, collapses lines which differ only on the "name" field.

prev_record = None
names = []
for line in fileinput.input():
    record = Record(line)
    if prev_record and not prev_record.match_except_name(record):
        print prev_record.merge_names(names)
        names = []
    names.append(record.name)
    prev_record = record

print prev_record.merge_names(names)
