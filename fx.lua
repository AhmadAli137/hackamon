-- Light shows, sprite motion, elemental particles, title parade, wipe transition, home idle.
-- LED colours are tuned for the badge's LEDs, whose green channel is far brighter than red:
-- keep green low or orange turns yellow and yellow turns white.
-- Left LED column {1,6,5} is your side, right {2,3,4} the enemy's.
local M={}
local L,R={1,6,5},{2,3,4}
local ROOT,EI,PI,EN,WIPE,pat,long,side,t0,dur
local idle,mode,mt=0,nil,0
local ex,ey=0,0            -- current offset of the enemy image, so particles follow it
local wt,wcb,wdone         -- wipe transition state
local pk=0                 -- which Pokemon the parade is showing
local C={fire=0xff1800,water=0x0030ff,grass=0x08d020,elec=0xffa000,burn=0xff0800,seed=0x08c018,par=0xffa000,def=0x1060ff,win=0x00ff30,lose=0xff0000,appear=0xffffff}
local TYPE={"fire","water","grass","elec"}
local MOVE={fire=1,water=1,grass=1,elec=1}
local RB={0xff0000,0xff6000,0xffc000,0x00ff20,0x0040ff,0x8000ff}
local PC={fire={0xff4000,0xffc000},water={0x40a0ff,0xd0f0ff},grass={0x20c040,0x90e060},elec={0xffe000,0xffffff}}
local PS={fire={8,8,4},water={9,9,4},grass={11,5,2},elec={4,12,1}}
local PB={}

local function set(i,c,k) badge.led.set(i,(c//65536)*k//255,((c//256)%256)*k//255,(c%256)*k//255) end
local function place(w,en,dx,dy)
  if en then ex,ey=dx,dy w:align("top_right",-10+dx,6+dy) else w:align("bottom_left",14+dx,-70+dy) end
end
local function put(b,en,x,y,w,h)
  if en then b:align("top_right",-60+x+w+ex,6+y+ey) else b:align("bottom_left",14+x,-120+y+h) end
end
local function pbox(i)
  local b=PB[i]
  if not b then b=badge.ui.box(ROOT,8,8) b:style({border_width=0}) b:hidden(true) PB[i]=b end
  return b
end
local function hidep() for i=1,#PB do PB[i]:hidden(true) end end

local function particles(en,h,kind)
  local pc,ps=PC[kind],PS[kind]
  for i=1,6 do
    local b=pbox(i)
    local w,hh=ps[1],ps[2]
    local x,y
    if kind=="fire" or kind=="water" then x=4+((i*13+h//60)%40) y=46-((h//7+i*9)%46)
    elseif kind=="grass" then x=2+((i*11+h//40)%40) y=((h//8+i*9)%46)
    else x=badge.sys.random(40) y=badge.sys.random(40) if (i+h//50)%3==0 then w,hh=12,4 end end
    b:set_size(w,hh) b:style({bg_color=pc[(i+h//90)%2+1],radius=ps[3]})
    put(b,en,x,y,w,hh)
    b:hidden(kind=="elec" and badge.sys.random(3)==0)
  end
end

function M.init(root,ei,pi,en)
  ROOT,EI,PI,EN=root,ei,pi,en
  WIPE=badge.ui.box(root,320,240) WIPE:style({bg_color=0x000000,border_width=0,radius=0}) WIPE:align("right_mid",0,0) WIPE:hidden(true)
end
function M.busy() return pat~=nil end
function M.idle(t) idle=C[TYPE[t]] or idle if not pat then for i=1,6 do set(i,idle,200) end badge.led.show() end end
-- "title" = parade, "home" = breathing glow and bobbing lead sprite, nil = still
function M.mode(m)
  mode,mt,pk=m,badge.sys.ms(),0
  if m~="title" then place(EI,true,0,0) place(PI,false,0,0) EN:align("top_left",8,6) hidep() end
end
-- Black wipe: grows over the screen, calls fn, then shrinks away.
function M.wipe(fn) wt,wcb,wdone=badge.sys.ms(),fn,false WIPE:hidden(false) WIPE:set_size(1,240) end

function M.start(p,s)
  long=string.sub(p,-1)=="L"
  if long then p=string.sub(p,1,-2) end
  pat,side,t0=p,s,badge.sys.ms()
  if MOVE[p] then dur=long and 3200 or 450
  elseif p=="win" or p=="lose" then dur=1500
  elseif p=="appear" then dur=700 else dur=550 end
end

-- Title parade: each Pokemon walks in from the right, poses centre stage with its
-- element's particles and LED colour, then walks off left. Loops forever.
local function parade(t)
  EN:align("top_left",8,6-math.floor(3+3*math.sin(t/250)))
  local u=t%1900
  local k=(t//1900)%4+1
  if k~=pk then pk=k EI:set_src((pk==2 and "m" or "s")..pk..".bin") EI:hidden(false) end
  local dx
  if u<500 then dx=70-205*u//500
  elseif u<1400 then dx=-135
  else dx=-135-200*(u-1400)//500 end
  local dy=(u>=500 and u<1400) and -math.floor(6*math.abs(math.sin((u-500)/150))) or 0
  place(EI,true,dx,dy+60)
  local kind=TYPE[({4,1,2,3})[k]]
  if u>=600 and u<1300 then particles(true,u-600,kind) else hidep() end
  local c=C[kind]
  if u>=500 and u<1400 then
    for i=1,6 do set(i,c,120+badge.sys.random(136)) end
  else
    for i=1,6 do set(i,RB[((t//150)+i)%6+1],120) end
  end
  badge.led.show()
end

function M.tick(now)
  if wt then
    local u=now-wt
    if u<300 then WIPE:set_size(1+319*u//300,240)
    elseif not wdone then wdone=true if wcb then wcb() end
    elseif u<620 then WIPE:set_size(math.max(1,320-320*(u-300)//300),240)
    else wt=nil WIPE:hidden(true) end
  end
  if not pat then
    local t=now-mt
    if mode=="title" then parade(t)
    elseif mode=="home" then
      local k=math.floor(120+80*math.sin(t/500))
      for i=1,6 do set(i,idle,k) end badge.led.show()
      place(PI,false,0,-math.floor(2+2*math.sin(t/300)))
    end
    return
  end
  local t=now-t0
  if t>=dur then
    pat=nil M.idle(0) place(EI,true,0,0) place(PI,false,0,0) EI:hidden(false) PI:hidden(false) hidep() mt=now return
  end
  local c,tg=C[pat],(side=="en") and R or L
  local tw=(side=="en") and EI or PI
  badge.led.clear()
  if MOVE[pat] and long then
    if t<1500 then local i=(t//80)%6+1 set(i,c,255) set((i+4)%6+1,c,60)
    else for i=1,6 do set(i,c,255) end end
  elseif MOVE[pat] then
    if (t//70)%2==0 then for i=1,6 do set(i,c,255) end end
  elseif pat=="win" or pat=="appear" then
    local i=(t//100)%6+1 set(i,c,255) set(i%6+1,c,80)
  elseif pat=="lose" then
    for i=1,6 do set(i,c,255-255*t//dur) end
  else
    local k=math.floor(150+100*math.sin(t/80))
    for i=1,3 do set(tg[i],c,k) end
  end
  badge.led.show()
  if MOVE[pat] then
    -- Impact is immediate for quick moves; long moves circle three times then hit at 1500 ms.
    local h=t-(long and 1500 or 0)
    local lunge=(h>=-100 and h<100) and 12 or 0
    local shake=(h>=60 and h<400) and (((t//50)%2==0) and 5 or -5) or 0
    if side=="en" then place(PI,false,lunge,-(lunge//2)) place(EI,true,shake,0)
    else place(EI,true,-lunge,lunge//2) place(PI,false,shake,0) end
    tw:hidden(h>=0 and h<360 and (h//60)%2==1)
    if h>=0 and h<450 then particles(side=="en",h,pat) else hidep() end
  elseif pat=="burn" or pat=="seed" then
    tw:hidden(t<240 and (t//60)%2==1)
  end
end

return M
