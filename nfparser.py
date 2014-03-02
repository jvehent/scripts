#!/usr/bin/env python

import re
import sys
import getopt
import time
import hashlib
from collections import defaultdict

import platform
from dns import resolver,reversename

# define globally, with a proper timeout
dns_resolver = resolver.Resolver()
dns_resolver.lifetime = 2

def ptr_lookup(ip):
    # reverse DNS lookup
    rev_ip = reversename.from_address(ip)
    try:
        return str(dns_resolver.query(rev_ip,"PTR")[0])
    except (resolver.NXDOMAIN,
            resolver.Timeout,
            resolver.NoAnswer,
            IndexError):
        return "<no ptr>"

def get_ptr(key, item):
    if DO_DNS:
        splitted_key = key.split(" ")
        for log_item in splitted_key:
            if item in log_item:
                ip = log_item.split("=")
                return ptr_lookup(ip[1])
    return '-'

def usage():
    print '''
nfparser.py: parse Netfilter logs
    <-i>    input file (default to /var/log/kern.log) 
    <-f>    filter regex
    <-o>    output format (comma separated, no space)
    <-l>    lower limit, display only result that have >= `-l` counts
    <-L>    upper limit, display only result that has <= `-L` counts
    <-v>    verbose

    example: nfparse -i kern.log -f "DROP.+PROTO=TCP.+DPT=80" -o "SRC,DST,DPT"
'''
    sys.exit()

INPUT_FILE = '/var/log/kern.log'
FILTER = ''
OUTPUT_FORMAT = []
STATS = defaultdict(int) 
KEYS = {}
LOWER_LIMIT = 0
UPPER_LIMIT = 1000000000000000000
DO_DNS = False
counter = 0

# command line arguments
args_list, remainder = getopt.getopt(sys.argv[1:], 'i:f:o:vhrl:L:')

for argument, value in args_list:
    if argument in ('-i'):
        INPUT_FILE = str(value)
    elif argument in ('-f'):
        FILTER = str(value)
    elif argument in ('-o'):
        output = str(value).split(',')
        for o in output:
            OUTPUT_FORMAT.append(o)
    elif argument in ('-r'):
        DO_DNS = True
    elif argument in ('-l'):
        LOWER_LIMIT = int(value)
    elif argument in ('-L'):
        UPPER_LIMIT = int(value)
    else:
        print("Unknown option %s" % argument)
        usage()

if not FILTER or not OUTPUT_FORMAT:
    print("missing argument")
    usage()

logfile = ""
try:
    logfile = open(INPUT_FILE,"r")
except IOError:
    print("Can't open %s" % INPUT_FILE)

for logline in logfile:
    if re.search(FILTER, logline):
        logtuple = ""
        splitted_log = logline.split(' ')
        for log_item in splitted_log:
            for output_item in OUTPUT_FORMAT:
                if output_item in log_item:
                    logtuple += log_item + " "
        key = hashlib.sha224(logtuple).hexdigest()
        STATS[key] += 1
        KEYS[key] = logtuple
for key in sorted(STATS, key=STATS.get, reverse=True):
    if STATS[key] >= LOWER_LIMIT and STATS[key] <= UPPER_LIMIT:
        print("%s hits for %s [SRC=%s  DST=%s]" % (STATS[key],
                                            KEYS[key],
                                            get_ptr(KEYS[key], 'SRC'),
                                            get_ptr(KEYS[key], 'DST')))

