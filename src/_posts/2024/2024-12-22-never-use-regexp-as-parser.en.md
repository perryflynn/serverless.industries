---
author: christian
title: Never use RegExp as a parser
locale: en
tags: [ python, software development ]
---

While working with a large log file I got annoyed by the Python script which is used to parse 
the file. It took over 15 minutes to parse around ten million log lines.

The biggest performance issue was a regular expression which was used to split a line into separate 
fields. Replacing this with a parser function which is just reading the line character by character 
and using separator and qualifier characters to identify the fields **increased the performance by 60%**!

The following example is parsing a default NGINX access log:

```py
import sys
from datetime import datetime

LOG_TIME_FORMAT = '%d/%b/%Y:%H:%M:%S %z'

fields = [
    { 'name': 'ip', 'type': 'str', 'keep': True },
    { 'name': 'dash', 'type': 'str', 'keep': False },
    { 'name': 'user', 'type': 'str', 'keep': False },
    { 'name': 'timestamp', 'type': 'datetime', 'keep': True },
    { 'name': 'request', 'type': 'str', 'keep': True },
    { 'name': 'status', 'type': 'int', 'keep': True },
    { 'name': 'bytes_sent', 'type': 'int', 'keep': False },
    { 'name': 'referer', 'type': 'str', 'keep': False },
    { 'name': 'user_agent', 'type': 'str', 'keep': True },
]

def parse_logitem(logline: str) -> dict:
    """ Parse single log line """

    field_index = 0
    field_buffer = ''
    qualifier_active = ''
    qualifier_end = ''
    eol = False

    result = {}

    for c in logline:
        if qualifier_active == '' and (c == '[' or c == '"'):
            # start parsing inside of a qualifier
            qualifier_active = c
            qualifier_end = c
            if c == '[':
                qualifier_end = ']'

        elif qualifier_active != '' and c == qualifier_end:
            # end of qualifier reached
            qualifier_active = ''
            qualifier_end = ''

        elif qualifier_active == '' and (c == ' ' or c == '\n'):
            # handle field change
            if fields[field_index]['keep']:

                if fields[field_index]['type'] == 'int':
                    field_buffer = int(field_buffer)
                elif fields[field_index]['type'] == 'str' and field_buffer == '-':
                    field_buffer = None
                elif fields[field_index]['type'] == 'datetime':
                    field_buffer = datetime.strptime(field_buffer, LOG_TIME_FORMAT)

                result[fields[field_index]['name']] = field_buffer

            field_index += 1
            field_buffer = ''

            if c == '\n':
                eol = True

        else:
            # capture in field buffer
            field_buffer += c

    # final error checks
    if field_buffer != '':
        raise Exception('Field buffer was not properly processed')

    if qualifier_active != '' or qualifier_end != '':
        raise Exception('Field qualifier parsing was not finished')

    if (field_index + 1) < len(fields):
        raise Exception('Not all fields got processed')

    if not eol:
        raise Exception('There was never an LF at the end of the line')

    return result

def fileload(file: str):
    """ Open file and parse lines """

    with open(file, 'r') as f:
        for line in f:
            yield parse_logitem(line)

if __name__ == '__main__':
    LOG_FILE = sys.argv[1]
    items = list(fileload(LOG_FILE))
```

The `fields` list is defining the order and data type of the field in a log line. A space is 
used as a separator, `"` and `[` are used as qualifier characters. Inside of a qualifier block, 
spaces can be part of a fields content. The `keep` flag is used to control if a field is added 
to the result dictionary or not.

A hand full of checks at the end improving the detection of syntax errors, but error detection is 
of course not perfect.

A parsed line looks like so:

```py
item = {
    'ip': '127.0.0.1',
    'timestamp': datetime,
    'request': 'GET / HTTP/1.1', 
    'status': 200, 
    'user_agent': 'the user agent'
}
```

Also the memory consumption was a problem in the old version. Only a subset of the log lines was 
required but the whole file was read into memory and filtered afterwards in Pandas. By using 
generator functions, filtering can be done while parsing/loading.

Again an example based on NGINX access logs:

```py
items = fileload('access.log')
items = filter(lambda l: l['status'] != 200, items)
items = list(items)
```

Since `fileload()` is using the `yield` statement, the logic is not processed until the enumerator 
is consumed by a loop or a `list()` statement. In the example above only log lines with status 
code not equals 200 are loaded into memory.

Anyway, for processing large amounts of data, python is the wrong language. It is possible to 
achieve much better performance results by using a compiled language like C#, Java, Go or Rust.

[PyPy](https://realpython.com/pypy-faster-python/) may be interesting, if a language change is no 
option. The [billion row challenge](https://1brc.dev/) also may contain some very interesting 
implementation examples.
