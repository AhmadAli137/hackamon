-- Light shows and sprite motion. Left LED column {1,6,5} is your side, right {2,3,4} the enemy's.
-- Attack moves are quick: triple flash, instant hit. Special moves are long: two laps
-- around the ring, then all six hold while the hit lands. A is blocked while one plays.
local M={}
local L,R={1,6,5},{2,3,4}
local EI,PI,EO,PO,pat,long,side,t0,dur
local idle=0
local C={fire=0xff5000,water=0x0060ff,grass=0x20e040,elec=0xffe000,burn=0xff6000,seed=0x20c020,par=0xffe000,def=0x40a0ff,win=0x00ff40,lose=0xff0000,appear=0xffffff}
local MOVE={fire=1,water=1,grass=1,elec=1}

local function set(i,c,k) badge.led.set(i,(c//65536)*k//255,((c//256)%256)*k//255,(c%256)*k//255) end
local function place(w,en,dx,dy) if en then w:align("top_right",-10+dx,6+dy) else w:align("bottom_left",14+dx,-70+dy) end end

function M.init(ei,pi,eo,po) EI,PI,EO,PO=ei,pi,eo,po end
function M.busy() return pat~=nil end
function M.shade(root,al,x,y)
  local b=badge.ui.box(root,50,50) b:style({bg_color=0,bg_opa=150,border_width=0,radius=0}) b:align(al,x,y) b:hidden(true) return b
end
function M.idle(c) idle=c if not pat then for i=1,6 do set(i,c,255) end badge.led.show() end end

-- p is a pattern name, with a trailing "L" for a long move. s is the side the effect lands on.
function M.start(p,s)
  long=string.sub(p,-1)=="L"
  if long then p=string.sub(p,1,-2) end
  pat,side,t0=p,s,badge.sys.ms()
  if MOVE[p] then dur=long and 1700 or 420
  elseif p=="win" or p=="lose" then dur=1500
  elseif p=="appear" then dur=700 else dur=550 end
end

function M.tick(now)
  if not pat then return end
  local t=now-t0
  if t>=dur then
    pat=nil M.idle(idle) place(EI,true,0,0) place(PI,false,0,0) EO:hidden(true) PO:hidden(true) return
  end
  local c,tg=C[pat],(side=="en") and R or L
  local to=(side=="en") and EO or PO
  badge.led.clear()
  if MOVE[pat] and long then
    if t<1000 then local i=(t//80)%6+1 set(i,c,255) set((i+4)%6+1,c,70)
    else for i=1,6 do set(i,c,255) end end
  elseif MOVE[pat] then
    if (t//70)%2==0 then for i=1,6 do set(i,c,255) end end
  elseif pat=="win" or pat=="appear" then
    local i=(t//100)%6+1 set(i,c,255) set(i%6+1,c,90)
  elseif pat=="lose" then
    for i=1,6 do set(i,c,255-255*t//dur) end
  else
    local k=math.floor(150+100*math.sin(t/80))
    for i=1,3 do set(tg[i],c,k) end
  end
  badge.led.show()
  if MOVE[pat] then
    -- Impact is immediate for quick moves and at 1000 ms for long ones.
    local h=t-(long and 1000 or 0)
    local lunge=(h>=-100 and h<100) and 12 or 0
    local shake=(h>=60 and h<400) and (((t//50)%2==0) and 5 or -5) or 0
    if side=="en" then place(PI,false,lunge,-(lunge//2)) place(EI,true,shake,0)
    else place(EI,true,-lunge,lunge//2) place(PI,false,shake,0) end
    to:hidden(not (h>=0 and h<260))
  elseif pat=="burn" or pat=="seed" then
    to:hidden(t>=220)
  end
end

return M
