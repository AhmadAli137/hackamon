"""Write deploy copies of the Lua files to dist/ with comment-only and blank lines removed,
then check the Share bundle: every file the badge will hold, at most 16 files and 48 KiB.
Comments cost nothing in RAM but count toward Share's size cap. Paste the dist/ files
into the badge IDE. Usage: python tools/build.py"""
import os, re, sys
root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
dist = os.path.join(root, 'dist')
os.makedirs(dist, exist_ok=True)
LUA = ['hackamon.lua', 'battle.lua', 'fx.lua', 'gen.lua', 'screens.lua']
sizes = {}
for name in LUA:
    src = open(os.path.join(root, name), encoding='utf-8').read().replace('\r\n', '\n')
    out = []
    in_header = False
    for line in src.split('\n'):
        s = line.strip()
        if s.startswith('--[==[badge-app'):
            in_header = True
        if in_header:
            out.append(line)
            if s == ']==]':
                in_header = False
            continue
        if s == '' or s.startswith('--'):
            continue
        out.append(line)
    text = '\n'.join(out) + '\n'
    with open(os.path.join(dist, name), 'w', encoding='utf-8', newline='\n') as f:
        f.write(text)
    sizes['main.lua' if name == 'hackamon.lua' else name] = len(text.encode('utf-8'))
# the shipped main.lua is the code after the header; the manifest is separate
main_src = open(os.path.join(dist, 'hackamon.lua'), encoding='utf-8').read()
body = main_src.split(']==]\n', 1)[1]
sizes['main.lua'] = len(body.encode('utf-8'))
sizes['manifest.cfg'] = 70
sizes['icon.bin'] = 5304
for i in range(1, 5):
    sizes[f's{i}.bin'] = 1132
    sizes[f'm{i}.bin'] = 3884
total = sum(sizes.values())
for k, v in sorted(sizes.items()):
    print(f'{v:6d}  {k}')
print(f'{total:6d}  total in {len(sizes)} files  (Share cap 49152 bytes, 16 files)')
if total > 49152 or len(sizes) > 16:
    print('OVER THE SHARE LIMIT')
    sys.exit(1)
print(f'margin {49152 - total} bytes')
