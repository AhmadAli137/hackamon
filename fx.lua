-- Light shows and sprite motion. Left LED column {1,6,5} is your side, right {2,3,4} the enemy's.
local M={}
local L,R={1,6,5},{2,3,4}
local EI,PI,pat,side,t0,dur
local idle=0
local C={fire=0xff5000,water=0x0060ff,grass=0x20e040,elec=0xffe000,burn=0xff6000,seed=0x20c020,par=0xffe000,def=0x40a0ff,win=0x00ff40,lose=0xff0000,appear=0xffffff}
local D={fire=650,water=700,grass=700,elec=500,win=1500,lose=1500,appear=700}
local HIT={fire=1,water=1,grass=1,elec=1,burn=1,seed=1}
local MOVE={fire=1,water=1,grass=1,elec=1}

local function set(i,c,k) badge.led.set(i,(c//65536)*k//255,((c//256)%256)*k//255,(c%256)*k//255) end
local function place(w,en,dx,dy) if en then w:align("top_right",-10+dx,6+dy) else w:align("bottom_left",14+dx,-70+dy) end end

function M.init(ei,pi) EI,PI=ei,pi end
function M.hit(p) return HIT[p] end
function M.shade(root,al,x,y)
  local b=badge.ui.box(root,50,50) b:style({bg_color=0,bg_opa=150,border_width=0,radius=0}) b:align(al,x,y) b:hidden(true) return b
end
function M.idle(c) idle=c if not pat then for i=1,6 do set(i,c,255) end badge.led.show() end end
function M.start(p,s) pat,side,t0,dur=p,s,badge.sys.ms(),D[p] or 550 end

function M.tick(now)
  if not pat then return end
  local t=now-t0
  if t>=dur then pat=nil M.idle(idle) place(EI,true,0,0) place(PI,false,0,0) return end
  local c,tg=C[pat],(side=="en") and R or L
  badge.led.clear()
  if MOVE[pat] then
    for i=1,6 do set(i,c,80+badge.sys.random(176)) end
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
    local lunge=(t<160) and 12 or 0
    local shake=(t>=120 and t<420) and (((t//50)%2==0) and 5 or -5) or 0
    if side=="en" then place(PI,false,lunge,-(lunge//2)) place(EI,true,shake,0)
    else place(EI,true,-lunge,lunge//2) place(PI,false,shake,0) end
  end
end

return M
