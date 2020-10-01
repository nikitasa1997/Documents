import re

print(re.findall('am\\Z', 'spaaam\nspaz'))
print(re.findall('am$', 'spaaam\nspaz'))
print(re.findall('az\\Z', 'spaaam\nspaz'))
print(re.findall('az$', 'spaaam\nspaz'))

print(re.findall('am\\Z', 'spaaam\nspaz', re.MULTILINE))
print(re.findall('am$', 'spaaam\nspaz', re.MULTILINE))
print(re.findall('az\\Z', 'spaaam\nspaz', re.MULTILINE))
print(re.findall('az$', 'spaaam\nspaz', re.MULTILINE))
