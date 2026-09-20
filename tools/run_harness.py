"""Run tools/harness.lua against the repo's Lua files under Lua 5.5 via lupa.
Usage: python tools/run_harness.py [repo_dir]"""
import os, sys
from lupa import lua55
root = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), '..'))
rt = lua55.LuaRuntime(unpack_returned_tuples=True)
src = open(os.path.join(root, 'tools', 'harness.lua'), encoding='utf-8').read()
fn = rt.eval('function(src, dir) local f = assert(load(src, "=harness")) return f(dir) end')
try:
    fn(src, root.replace('\\', '/'))
except Exception as e:
    print('HARNESS FAILED:', e)
    sys.exit(1)
