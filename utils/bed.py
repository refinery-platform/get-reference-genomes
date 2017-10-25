from os.path import commonprefix

class Record(object):
    def __init__(self, line):
        """Given a tab-delimited string, construct a BED record."""
        fields = line.rstrip().split("\t")
        [
            # BED format: https://genome.ucsc.edu/FAQ/FAQformat#format1
            self.chrom,
            self.chrom_start,
            self.chrom_end,
            self.name,
            self.score,
            self.strand,
            self.think_start,
            self.think_end,
            self.item_rgb,
            self.block_count,
            self.block_sizes,
            self.block_starts
        ] = fields

    def __str__(self):
        return "\t".join([
            self.chrom,
            self.chrom_start,
            self.chrom_end,
            self.name,
            self.score,
            self.strand,
            self.think_start,
            self.think_end,
            self.item_rgb,
            self.block_count,
            self.block_sizes,
            self.block_starts
        ])

    def merge_names(self, names):
        """Replace this object's name with a merge of names."""
        prefix = commonprefix(names)
        if prefix != self.name:
            if len(prefix) > 4:
                self.name = prefix + '*'
            else:
                names.sort()
                self.name = '/'.join(names)
        return self

    @staticmethod
    def as_int(method, a, b):
        return str(method(int(a), int(b)))

    def merge(self, other):
        """Merge this record and another one."""
        if not other:
            return self
        earliest_chrom_start = self.as_int(min, self.chrom_start, other.chrom_start)
        latest_chrom_end = self.as_int(max, self.chrom_end, other.chrom_end)
        # I don't really understand thinkStart/End.
        earliest_think_start = self.as_int(min, self.think_start, other.think_start)
        latest_think_end = self.as_int(max, self.think_end, other.think_end)
        # TODO: They can differ on strand, but we aren't checking that.
        self_core = [self.chrom, self.name, self.score, self.item_rgb]
        other_core = [other.chrom, other.name, other.score, other.item_rgb]
        if self_core != other_core:
            raise Exception('Expected match, but instead: %s != %s' % (self_core, other_core))
        self.chrom_start = earliest_chrom_start
        self.chrom_end = latest_chrom_end
        self.think_start = earliest_think_start
        self.think_end = latest_think_end
        self.block_count = '1'
        self.block_sizes = str(int(latest_chrom_end) - int(earliest_chrom_start))
        self.block_starts = '0'
        return self

    def match_except_name(self, other):
        """Compare on Record to another, and return true if they match on all fields except name."""
        if type(other) != type(self):
            return False
        other_dict = other.__dict__.copy()
        self_dict = self.__dict__.copy()
        other_dict['name'] = None
        self_dict['name'] = None
        return other_dict == self_dict

