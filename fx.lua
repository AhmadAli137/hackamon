-- Attack light shows and sprite motion. Loaded by main.lua.
-- LEDs seen from the front: left column {1,6,5} top to bottom, right column {2,3,4}.
-- Left column belongs to your Pokemon, right column to the enemy.
local M={}
local L,R={1,6,5},{2,3,4}
local EI,PI
local pat,side,t0,dur=nil,nil,0,0
local ir,ig,ib=0,0,0
local DUR={fire=650,water=700,grass=700,elec=500,burn=500,seed=600,par=500,def=600,win=1500,lose=1500,appear=700}
local rnd=badge.sys.random

local function all(r,g,b) badge.led.set_all(r,g,b) end
local function grp(g,r,gg,b) for i=1,3 do badge.led.set(g[i],r,gg,b) end end
local function place(w,en,dx,dy)
  if en then w:align("top_right",-10+dx,6+dy) else w:align("bottom_left",14+dx,-70+dy) end
end

function M.init(ei,pi) EI,PI=ei,pi end

function M.idle(r,g,b)
  ir,ig,ib=r,g,b
  if not pat then all(r,g,b) badge.led.show() end
end

-- p = pattern name, s = the side the effect lands on ("me" or "en"), or nil for whole-badge shows.
function M.start(p,s) pat,side,t0,dur=p,s,badge.sys.ms(),DUR[p] or 500 end

function M.tick(now)
  if not pat then return end
  local t=now-t0
  if t>=dur then
    pat=nil all(ir,ig,ib) badge.led.show()
    place(EI,true,0,0) place(PI,false,0,0)
    return
  end
  local tgt=(side=="en") and R or L
  local oth=(side=="en") and L or R
  badge.led.clear()
  if pat=="fire" then
    for i=1,6 do badge.led.set(i,220,30+rnd(4)*35,0) end
  elseif pat=="water" then
    local s=(t//110)%3+1
    badge.led.set(L[s],0,90,230) badge.led.set(R[s],0,90,230)
    badge.led.set(L[s%3+1],0,20,80) badge.led.set(R[s%3+1],0,20,80)
  elseif pat=="grass" then
    local i=(t//100)%6+1
    badge.led.set(i,30,220,50) badge.led.set(i%6+1,0,90,15)
  elseif pat=="elec" then
    if (t//60)%2==0 then all(255,230,0) else all(90,90,110) end
  elseif pat=="burn" then
    local v=math.floor(130+100*math.sin(t/70)) grp(tgt,v,v//5,0)
  elseif pat=="seed" then
    local a=(t//150)%2==0
    grp(tgt,0,a and 170 or 40,0) grp(oth,0,a and 40 or 170,0)
  elseif pat=="par" then
    if rnd(3)==0 then grp(tgt,255,220,0) end
  elseif pat=="def" then
    local v=math.floor(90+70*math.sin(t/90)) grp(tgt,v//3,v,220)
  elseif pat=="win" then
    local i=(t//90)%6+1
    badge.led.set(i,0,230,70) badge.led.set(i%6+1,0,120,35) badge.led.set((i+1)%6+1,0,40,10)
  elseif pat=="lose" then
    local v=math.floor(220*(1-t/dur)) all(v,0,0)
  elseif pat=="appear" then
    local s=(t//120)%3+1
    badge.led.set(L[s],220,220,220) badge.led.set(R[s],220,220,220)
  end
  badge.led.show()
  -- Damaging moves: attacker lunges toward the target, target shakes.
  if pat=="fire" or pat=="water" or pat=="grass" or pat=="elec" then
    local lunge=(t<160) and 12 or 0
    local shake=(t>=120 and t<420) and (((t//50)%2==0) and 5 or -5) or 0
    if side=="en" then place(PI,false,lunge,-(lunge//2)) place(EI,true,shake,0)
    else place(EI,true,-lunge,lunge//2) place(PI,false,shake,0) end
  end
end

return M
