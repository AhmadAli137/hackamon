-- Title parade and wipe transition. Loaded once at launch, then dropped.
-- Reads globals: W (widgets), EI (enemy image widget). Installs global TITLE.
-- Each Pokemon walks in from the right, poses centre stage with its element's LED
-- colour and bobs, then walks off left. Pressing A runs a black wipe that reveals home.
local W,EI=W,EI
local C={0xffa000,0xff1800,0x0030ff,0x08d020}   -- LED colour by Pokemon 1..4
local RB={0xff0000,0xff6000,0xffc000,0x00ff20,0x0040ff,0x8000ff}
local t0,pk,wt,wcb,wdone=badge.sys.ms(),0,nil,nil,false
local WIPE=badge.ui.box(UI_ROOT,320,240)
WIPE:style({bg_color=0x000000,border_width=0,radius=0}) WIPE:align("right_mid",0,0) WIPE:hidden(true)

local function set(i,c,k) badge.led.set(i,(c//65536)*k//255,((c//256)%256)*k//255,(c%256)*k//255) end

W.BG:style({bg_color=0x101838}) W.EB:hidden(true) W.PB:hidden(true)
W.PN:set_text("") W.PH:set_text("")
W.EN:style({text_font=24,text_color=0xffd000}) W.EN:set_text("HACKAMON")
W.EH:style({text_color=0x80c0ff}) W.EH:set_text("Scan. Battle. Catch.")
W.MSG:set_text("Press A\nto start") W.MENU:set_text("")

TITLE={}
function TITLE.go(fn) wt,wcb=badge.sys.ms(),fn WIPE:hidden(false) WIPE:set_size(1,240) end
-- Returns true once the wipe has fully cleared and this module can be dropped.
function TITLE.tick(now)
  if wt then
    local u=now-wt
    if u<300 then WIPE:set_size(1+319*u//300,240)
    elseif not wdone then wdone=true EI:hidden(true) W.EN:align("top_left",8,6) wcb()
    elseif u<620 then WIPE:set_size(math.max(1,320-320*(u-300)//300),240)
    else WIPE:delete() return true end
    if wdone then return false end
  end
  local t=now-t0
  W.EN:align("top_left",8,6-math.floor(3+3*math.sin(t/250)))
  local u,k=t%1900,(t//1900)%4+1
  if k~=pk then pk=k EI:set_src((k==2 and "m" or "s")..k..".bin") EI:hidden(false) end
  local dx
  if u<500 then dx=70-205*u//500 elseif u<1400 then dx=-135 else dx=-135-200*(u-1400)//500 end
  local dy=(u>=500 and u<1400) and -math.floor(6*math.abs(math.sin((u-500)/150))) or 0
  EI:align("top_right",-10+dx,66+dy)
  if u>=500 and u<1400 then for i=1,6 do set(i,C[k],120+badge.sys.random(136)) end
  else for i=1,6 do set(i,RB[((t//150)+i)%6+1],120) end end
  badge.led.show()
  return false
end
