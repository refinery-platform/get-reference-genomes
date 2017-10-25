import unittest
import subprocess
from os import environ, listdir
from datetime import datetime
import requests
from time import sleep
from requests.exceptions import RequestException


class ReferenceGenomesTest(unittest.TestCase):

    def test_usage_message_if_no_args(self):
        cmd = 'tools/genome-to-local.sh'
        pipes = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        std_out, std_err = pipes.communicate()
        self.assertNotEqual(pipes.returncode, 0)
        self.assertIn('USAGE', std_err)


    def test_hg19(self):
        timestamp = datetime.now().isoformat()
        cmd = 'tools/genome-to-local.sh hg19'.split(' ')
        first_run = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            env=dict(environ, GENOME_TEST_TMP=timestamp)
        )
        std_out, std_err = first_run.communicate()
        self.assertEqual(first_run.returncode, 0)
        self.assertIn('Disk space used', std_out)
        self.assertIn('hg19/cytoBand.txt', std_out)

        second_run = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            env=dict(environ, GENOME_TEST_TMP=timestamp)
        )
        std_out, std_err = second_run.communicate()
        self.assertEqual(second_run.returncode, 0)
        self.assertIn('Disk space used', std_out)
        self.assertIn('hg19/cytoBand.txt', std_out)
        for message in [
            'hg19.2bit.gz or hg19.2bit already exists: skip download',
            'hg19.fa already exists: will not regenerate',
            'hg19.fa.gz or hg19.fa already exists: skip download',
            'hg19.fa.fai already exists: will not regenerate',
            'cytoBand.txt.gz or cytoBand.txt already exists: skip download',
            'refGene.txt.gz or refGene.txt already exists: skip download',
            'refGene.bed already exists: will not regenerate',
            'refGene.collapsed.bed already exists: will not regenerate',
            'refGene.bed.tbi already exists: will not regenerate',
            'refGene.collapsed.bed.tbi already exists: will not regenerate'
        ]:
            self.assertIn(message, std_err)

        tmp_dir = '/tmp/genome/' + timestamp + '/hg19/'
        fixture_dir = 'tests/fixtures/output/'
        for filename in listdir(fixture_dir):
            with open(fixture_dir + filename, 'r') as f:
                head = f.read()
            with open(tmp_dir + filename.replace('.head', ''), 'r') as f:
                whole = f.read()
            self.assert_head(head, whole, filename)

    def assert_head(self, head, whole, filename):
        if not whole.startswith(head):
            self.fail('Head of output {} does not match fixture:\n{}\n... but expected:\n{}'.format(
                filename,
                '\n'.join(whole.split('\n')[0:9]),
                head
            ))


if __name__ == '__main__':
    # TODO: Find a better way to start the cache server
    port = 8000
    cmd = '( cd tests/fixtures/input/ && python -m SimpleHTTPServer {} > /dev/null ) &'.format(port)
    subprocess.call(cmd, shell=True)
    # If a server is already running, we'll assume it's the right one, rather than failing.
    url = 'http://localhost:{}'.format(port)
    server_up = False
    while not server_up:
        print('{} not up yet'.format(url))
        try:
            server_up = requests.get(url).status_code == 200
        except RequestException:
            pass
        sleep(1)
    environ['GENOME_CACHE_URL'] = url

    suite = unittest.TestLoader().loadTestsFromTestCase(ReferenceGenomesTest)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if result.wasSuccessful():
        print('PASS!')
    else:
        print('FAIL!')
        exit(1)