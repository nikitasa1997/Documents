import csv
import re

def startmode_to_dword(mode):
    if not isinstance(mode, str):
        raise TypeError(type(mode))
    if (mode == 'Auto'):
        return 2
    elif (mode == 'Manual'):
        return 3
    elif (mode == 'Disabled'):
        return 4
    raise ValueError(mode)

def csv_get_session_key(header, records):
    if not isinstance(records, list):
        raise TypeError(type(records))
    if not len(records):
        raise ValueError(len(records))

    count = dict()
    for record in records:
        findall = re.findall('_[a-fA-F0-9]+$', record[header['Name']])
        for match in findall:
            count[match] = count.get(match, 0) + 1
    if not len(count):
        return None
    return max(count, key = count.get)

default_session_key = '_00000000'

cmd_encoding = 'utf-16'

csv_header = 1
csv_record = 2

def csv_to_dict(csv_file):
    with open(csv_file, 'r', encoding = cmd_encoding) as file:
        reader = csv.reader(file)
        lines = [tuple(line) for line in reader]
        header = lines[csv_header]
        header = { header[i] : i for i in range(len(header)) }
        records = lines[csv_record : ]

        session_key = csv_get_session_key(header, records)
        name_startmode = dict()
        for record in records:
            name = record[header['Name']]
            startmode = startmode_to_dword(record[header['StartMode']])
            if session_key and session_key in name:
                name = name.replace(session_key, default_session_key, 1)
                name_not_with_key = name[ : -len(default_session_key)]
                name_startmode[name_not_with_key] = startmode
            name_startmode[name] = startmode
    return name_startmode, session_key

title = 'Windows Registry Editor Version 5.00\r\n'
line_0 = '[HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\{}]\r\n'
line_1 = '\"Start\"=dword:0000000{}\r\n'

default_encoding = 'utf-8'

def dict_to_reg(name_startmode, reg_file):
    with open(reg_file, 'w', encoding = default_encoding) as file:
        file.write(title + '\r\n')
        key = lambda s: s[0].casefold()
        for name, startmode in sorted(name_startmode.items(), key = key):
            file.write(line_0.format(name) + line_1.format(startmode) + '\r\n')

reg_title = 2

start = 0
end = 1

offset_0 = {
    start : len('[HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\'),
    end : -len(']\n')
}

offset_1 = {
    start : len('\"Start\"=dword:0000000'),
    end : -len('\n')
}

def reg_to_dict(reg_file):
    name_startmode = dict()
    with open(reg_file, 'r', encoding = default_encoding) as file:
        lines = file.readlines()[reg_title : ]
        for i in range(0, len(lines), 3):
            name = lines[i][offset_0[start] : offset_0[end]]
            startmode = int(lines[i + 1][offset_1[start] : offset_1[end]])
            name_startmode[name] = startmode
    return name_startmode

def dict_operation(dict_a, dict_b, operation):
    keys_a = set(dict_a.keys())
    keys_b = set(dict_b.keys())
    keys_operation = operation(keys_a, keys_b)
    intersection = { key : dict_a[key] if key in dict_a else dict_b[key] for key in keys_operation }
    return intersection

if __name__ == "__main__":
    """
    wmic service get name,startmode /FORMAT:CSV > test.csv

    name_startmode_csv, session_key = csv_to_dict('test.csv')
    dict_to_reg(name_startmode_csv, 'test.reg')
    name_startmode_reg = reg_to_dict('test.reg')
    print(name_startmode_csv == name_startmode_reg)
    """
    pass
