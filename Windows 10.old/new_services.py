import csv
import re

def callable_or_raise(obj):
    if not callable(obj):
        raise TypeError(type(obj))
        raise TypeError(F"'{type(obj)}' object is not callable")

def isinstance_or_raise(obj, obj_type):
    if not isinstance(obj, obj_type):
        raise TypeError(F"value {obj} has type '{type(obj)}'")

def len_or_raise(s):
    if not len(s):
        raise ValueError('zero len')

def startmode_to_dword(mode):
    isinstance_or_raise(mode, str)

    if (mode == 'Auto'):
        return 2
    elif (mode == 'Manual'):
        return 3
    elif (mode == 'Disabled'):
        return 4
    raise ValueError(mode)

def get_session_key(records, get_name):
    len_or_raise(records)
    callable_or_raise(get_name)

    count = dict()
    for record in records:
        findall = re.findall('_[a-fA-F0-9]{4,8}$', get_name(record))
        if findall:
            count[findall[0]] = count.get(findall[0], 0) + 1
    if not len(count):
        return
    return max(count, key = count.get)

def replace(compile_key, pattern, repl, string):
    isinstance_or_raise(pattern, str)
    len_or_raise(pattern)
    isinstance_or_raise(repl, str)
    len_or_raise(repl)
    isinstance_or_raise(string, str)
    len_or_raise(string)

    if compile_key.match(string):
        return string[ : -len(pattern)] + repl
    return string

DEFAULT_SESSION_KEY = '_00000000'

CMD_ENCODING = 'utf-16'

CSV_HEADER = 1
CSV_RECORD = 2

def csv_to_dict(csv_file):
    with open(csv_file, 'r', encoding=CMD_ENCODING) as file:
        reader = csv.reader(file)
        lines = [tuple(line) for line in reader]
        header_line = lines[CSV_HEADER]
        header = { header_line[i] : i for i in range(len(header_line)) }
        records = lines[CSV_RECORD : ]

        session_key = get_session_key(records, lambda record: record[header['Name']])
        name_startmode = dict()
        compile_key = re.compile(session_key + '$') if session_key else None
        for record in records:
            name = record[header['Name']]
            startmode = startmode_to_dword(record[header['StartMode']])
            if session_key and compile_key.match(name):
                name = name[ : -len(session_key)]
                name_startmode[name] = startmode
                name += DEFAULT_SESSION_KEY
            name_startmode[name] = startmode
    return name_startmode, session_key

TITLE = 'Windows Registry Editor Version 5.00\r\n'
line_0 = '[HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\{}]\r\n'
line_1 = '"Start"=dword:0000000{}\r\n'

DEFAULT_ENCODING = 'utf-8'

def dict_to_reg(name_startmode, session_key, reg_file):
    with open(reg_file, 'w', encoding = DEFAULT_ENCODING) as file:
        file.write(TITLE + '\r\n')
        key = lambda s: s[0].casefold()
        compile_key = re.compile(DEFAULT_SESSION_KEY + '$')
        for name, startmode in sorted(name_startmode.items(), key = key):
            if compile_key.match(name):
                name = name[ : -len(DEFAULT_SESSION_KEY)] + session_key
            file.write(line_0.format(name) + line_1.format(startmode) + '\r\n')

REG_TITLE = 2

start = 0
end = 1

OFFSET_0 = {
    start : len('[HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\'),
    end : -len(']\n')
}

OFFSET_1 = {
    start : len('"Start"=dword:0000000'),
    end : -len('\n')
}

def reg_to_dict(reg_file):
    name_startmode = dict()
    with open(reg_file, 'r', encoding=DEFAULT_ENCODING) as file:
        lines = file.readlines()[REG_TITLE : ]
        for i in range(0, len(lines), 3):
            name = lines[i][OFFSET_0[start] : OFFSET_0[end]]
            startmode = int(lines[i + 1][OFFSET_1[start] : OFFSET_1[end]])
            name_startmode[name] = startmode
    session_key = get_session_key(name_startmode, lambda name: name)
    compile_key = re.compile(session_key + '$') if session_key else None
    def replace(compile_key, pattern, repl, string):
    if session_key:
        name_startmode = { replace(compile_key, session_key, DEFAULT_SESSION_KEY, name) :
            name_startmode[name] for name in name_startmode }
    return name_startmode

def dict_operation(dict_a, dict_b, operation):
    keys_a = set(dict_a)
    keys_b = set(dict_b)
    keys_operation = operation(keys_a, keys_b)
    intersection = { key : dict_a[key] if key in dict_a else dict_b[key] for key in keys_operation }
    return intersection

if __name__ == "__main__":
"""
    name_startmode_csv, session_key = csv_to_dict('test.csv')
    dict_to_reg(name_startmode_csv, 'test.reg')
    name_startmode_reg = reg_to_dict('test.reg')
    print(name_startmode_csv == name_startmode_reg)
"""
    if DEFAULT_SESSION_KEY in name:
        name = re.sub(DEFAULT_SESSION_KEY + '$', session_key, name, count = 1)

    count = 1 ?????????
    Нужно ли проверять DEFAULT_SESSION_KEY in name. Или можно применить name = ... для всех?
    pass
