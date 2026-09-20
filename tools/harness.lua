-- Off-badge test harness for Hackamon. Run with tools/run_harness.py (needs lupa).
-- Provides a mock badge API, then drives the game through a scripted session and
-- fails loudly on any Lua error. It does not check pixels, only that the code runs.
local DIR=...
local now=0
local store={}
local files={}
local widgets=0
local log={}
local errors={}
local exited=false

local function W(kind)
  widgets=widgets+1
  local w={kind=kind,text="",hidden_=false}
  function w:style(t,sel) assert(type(t)=="table") return self end
  function w:align(a,x,y) assert(type(a)=="string") assert(math.type(x)=="integer" and math.type(y)=="integer","non-integer align "..tostring(x)..","..tostring(y)) return self end
  function w:set_pos(x,y) assert(math.type(x)=="integer" and math.type(y)=="integer","non-integer pos") return self end
  function w:set_size(x,y) assert(math.type(x)=="integer" and math.type(y)=="integer","non-integer size") return self end
  function w:set_text(s) assert(type(s)=="string","set_text needs a string, got "..type(s)) self.text=s return self end
  function w:hidden(b) self.hidden_=b return self end
  function w:set_src(p) assert(type(p)=="string") assert(files[p],"set_src of missing file "..p) self.src=p return self end
  function w:set_range(a,b) return self end
  function w:set_value(v) assert(math.type(v)=="integer","bar value not integer") return self end
  function w:delete() self.deleted=true end
  return w
end

badge={
  ui={
    screen_width=320,screen_height=240,
    label=function(p,t) local w=W("label") w.text=t return w end,
    box=function(p,x,y) return W("box") end,
    bar=function(p,a,b,c) return W("bar") end,
    image=function(p,src) local w=W("image") assert(files[src],"image of missing file "..src) w.src=src return w end,
  },
  led={
    set=function(i,r,g,b)
      assert(i>=1 and i<=6,"led index "..i)
      for _,v in ipairs{r,g,b} do assert(math.type(v)=="integer" and v>=0 and v<=255,"led channel "..tostring(v)) end
    end,
    set_all=function(r,g,b) badge.led.set(1,r,g,b) end,
    clear=function() end, show=function() end, count=function() return 6 end,
  },
  sys={
    ms=function() return now end,
    log=function(s) log[#log+1]=s end,
    random=function(n) if n then return math.random(0,n-1) end return math.random(0,2^31) end,
    stats=function() return {free_heap=30000,lua_used=collectgarbage("count")*1024} end,
    heap=function() return math.floor(collectgarbage("count")*1024) end,
    gc_step=function() collectgarbage("step") end,
  },
  store={
    get_int=function(k,d) return store[k] or d end,
    set_int=function(k,v) assert(math.type(v)=="integer") store[k]=v end,
  },
  nfc={
    enabled=false, text=nil,
    enable=function() badge.nfc.enabled=true return true end,
    disable=function() badge.nfc.enabled=false end,
    clear=function() badge.nfc.text=nil end,
    card=function() if badge.nfc.text then return {uid="04AA"} end return nil end,
    read_text=function() return badge.nfc.text end,
  },
  fs={
    write=function(n,d) files[n]=d end,
    append=function(n,d) files[n]=(files[n] or "")..d end,
    remove=function(n) files[n]=nil return true end,
    exists=function(n) return files[n]~=nil end,
  },
  input={BUTTON={A=1,B=2,HOME=3,DOWN=4,LEFT=5,RIGHT=6,UP=7,AUX1=8,START=9},KIND={PRESSED=1,RELEASED=2}},
  app={exit=function() exited=true end},
}

package.path=DIR.."/?.lua"
-- badge modules never return values through package.loaded the normal way; mimic that
local real_require=require
require=function(name)
  local f=assert(loadfile(DIR.."/"..name..".lua"))
  return f()
end

local function ticks(n,step) for _=1,n do now=now+(step or 20) on_tick() end end
local function press(b) on_button(b,1) on_button(b,2) end
local B=badge.input.BUTTON

-- ---- run ----
store.owned=3 store.act=1              -- own Pikachu and Charmander so SWITCH appears
local chunk=assert(loadfile(DIR.."/hackamon.lua"))
chunk()
on_enter({})
ticks(120)                       -- first-launch render: 88 parts
assert(files["s1.bin"] and #files["s1.bin"]==1132,"s1.bin not rendered: "..tostring(files["s1.bin"] and #files["s1.bin"]))
assert(files["m4.bin"] and #files["m4.bin"]==3884,"m4.bin not rendered: "..tostring(files["m4.bin"] and #files["m4.bin"]))
assert(TITLE,"title not loaded")
ticks(150)                       -- parade
press(B.A) ticks(40)             -- wipe to home
assert(TITLE==nil,"title not dropped")
press(B.A)                       -- SCAN
assert(badge.nfc.enabled,"scan did not enable nfc")
badge.nfc.text="PKM03" ticks(20)
assert(not badge.nfc.enabled,"nfc still on after encounter")
press(B.A) ticks(60) press(B.A) ticks(60)        -- Wild appeared / Go!
-- round 1: first move, advance through the dialogue and animations
press(B.A) for _=1,12 do ticks(200,20) press(B.A) end
-- round 2: second move
press(B.DOWN) press(B.A) for _=1,12 do ticks(200,20) press(B.A) end
-- round 3: SWITCH to Charmander (third menu item), then advance
press(B.DOWN) press(B.DOWN) press(B.A) ticks(5) press(B.A) for _=1,12 do ticks(200,20) press(B.A) end
-- HOME from wherever we are, then SWITCH LEAD, then EXIT
on_button(B.HOME,2) ticks(5)
assert(not badge.nfc.enabled,"nfc on at home")
press(B.DOWN) press(B.A) ticks(5)
on_button(B.HOME,2) ticks(5)
press(B.DOWN) press(B.DOWN) press(B.A) ticks(200,20)
assert(exited,"EXIT did not exit")
on_exit()
print("HARNESS OK  widgets="..widgets.."  files="..(function() local n=0 for _ in pairs(files) do n=n+1 end return n end)())
for _,l in ipairs(log) do print("  log: "..l) end
