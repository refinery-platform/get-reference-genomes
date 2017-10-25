import fileinput
from bed import Record

# Given a BED file, collapses sequential lines which match on the "name" field.

merged_record = None
for line in fileinput.input():
    record = Record(line)
    if not merged_record:
        merged_record = record
    elif record.name == merged_record.name:
        merged_record.merge(record)
    else:
        print merged_record
        merged_record = record

print merged_record