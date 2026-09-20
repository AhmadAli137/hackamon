--[==[badge-app
slug=hackamon
name=Hackamon
icon=PKM
api=2
heap_kb=96
wake_lock=1
home_button=1
]==]
-- HACKAMON. Start with PIKACHU. Scan stickers PKM01 (Charmander), PKM02 (Squirtle),
-- PKM03 (Bulbasaur) to battle wild Pokemon; win to add them to your team. If one of
-- yours faints you lose the whole team. UP/DOWN cursor, A select / next line, B back / run.
-- HOME returns to the home screen from anywhere; EXIT on the home menu leaves the game.
-- (Exiting leaves the badge heap fragmented until reboot, so the app stays resident.)
-- The badge only has RAM for the code a screen needs, so one-shot code is loaded, used
-- and dropped: ui.lua (widgets), title.lua (parade + wipe), gen.lua + sprites.lua (first
-- launch render). data.lua (stats) and fx.lua (battle lights, motion) stay resident.
local P,FX
local BIT,SUP,TP={1,2,4,8},{3,1,2,2},{"fire","water","grass","elec"}
local TN={"FIRE","WATER","GRASS","ELECTRIC"}
local S,cur,act,owned,seen,nfc,nxt,job=0,1,1,1,1,false,0,0
local me,en,team={},{},{}
local q,qi,after={},0,nil
local R,EN,EB,EH,PN,PB,PH,MSG,MENU,BG,PI
-- W (widgets), EI (enemy image), UI_ROOT and TITLE are globals shared with the one-shot modules.

local function own(i) return (owned//BIT[i])%2==1 end
local function met(i) return (seen//BIT[i])%2==1 end
local function gc() collectgarbage("collect") end
local function gcset(p)
  if _VERSION=="Lua 5.5" then collectgarbage("param","pause",p) collectgarbage("param","stepmul",400)
  else collectgarbage("incremental",p,400) end
end
-- Sprite images live in appdata, which is per badge and never included in a Share bundle.
local function spr(i,m) return "appdata/"..(m and "m" or "s")..i..".bin" end
local function log(t) badge.sys.log(t.." free "..badge.sys.stats().free_heap) end
local function fx()
  if not FX then FX=require("fx") FX.init(R,EI,PI) gc() end
  return FX
end

local function bar(b,h,m)
  b:set_range(0,m) b:set_value(h)
  b:style({bg_color=h*4<=m and 0xe03030 or (h*2<=m and 0xe8b020 or 0x30c030)},"indicator")
end
local function bars(n,mh,mm,eh)
  PN:set_text(n) PH:set_text(mh.."/ "..mm) bar(PB,mh,mm)
  if en.id then EN:set_text(P[en.id][1]) EH:set_text(eh.."/ "..en.max) bar(EB,eh,en.max) end
end
local function menu(t)
  local s=""
  for i=1,#t do s=s..(i==cur and "> " or "  ")..t[i].."\n" end
  MENU:set_text(s)
end
local function side(i,e)
  return {id=i,hp=P[i][2],max=P[i][2],burn=0,seed=0,def=0,par=0,name=(e and "Enemy " or "")..P[i][1]}
end
local function save() badge.store.set_int("act",act) badge.store.set_int("owned",owned) badge.store.set_int("seen",seen) end

-- Dialogue queue. Each line snapshots HP so bars move with the text; f = side hit, p = fx pattern.
local function push(m,f,p) q[#q+1]={m,P[me.id][1],me.hp,me.max,en.id and en.hp or 0,f,p} end
local function advance()
  if qi<#q then
    qi=qi+1 local e=q[qi]
    MSG:set_text(e[1]) bars(e[2],e[3],e[4],e[5])
    if e[7] then FX.start(e[7],e[6]) end
    return
  end
  q,qi={},0 local f=after after=nil if f then f() end
end
local function say(f) after=f S=4 MENU:set_text("") advance() end

local function home()
  S=0 cur=1 en={} me=side(act) gc() fx()
  local n=0 for i=1,4 do if own(i) then n=n+1 end end
  BG:style({bg_color=0xf8f8f0}) PI:hidden(false) EB:hidden(true) EI:hidden(true) PB:hidden(false)
  EN:style({text_font=16,text_color=0x101010}) EN:set_text("Team "..n.."/4")
  EH:style({text_color=0x101010}) EH:set_text("")
  PI:set_src(spr(act,true)) bars(P[act][1],me.hp,me.max,0)
  MSG:set_text("What will you\ndo?") menu({"SCAN","SWITCH LEAD","HACKADEX","EXIT"})
  FX.idle(P[act][3]) FX.mode("home") log("home")
end
-- Hackadex: reuses the enemy panel and image widget, so it costs no extra widgets.
local function dex()
  S=6 FX.mode(nil)
  local i,s=cur,met(cur)
  EI:hidden(not s) if s then EI:set_src(spr(i,false)) end
  EN:set_text(s and P[i][1] or "???") EH:set_text(s and ("HP "..P[i][2].."  "..TN[P[i][3]]) or "")
  MSG:set_text("HACKADEX "..i.."/4\n"..(own(i) and "Caught!" or (s and "Seen" or "Not found yet")))
  local t={}
  for j=1,4 do t[j]=(met(j) and P[j][1] or "???")..(own(j) and " *" or "") end
  menu(t)
end
local function items()
  local t={P[me.id][4][1],P[me.id][5][1]}
  if owned~=BIT[me.id] then t[3]="SWITCH" end
  return t
end
local function bmenu() S=3 cur=1 MSG:set_text("What will\n"..P[me.id][1].." do?") menu(items()) end
local function others()
  local o,t={},{}
  for i=1,4 do if own(i) and i~=me.id and (team[i] or 0)>0 then o[#o+1]=i t[#t+1]=P[i][1] end end
  return o,t
end

local function use(u,t,mv,who)
  local a,d=P[u.id][3],P[t.id][3]
  if mv[2]>0 then
    local e=SUP[a]==d and 3 or ((SUP[d]==a or (a==4 and d==3)) and 1 or 2)
    local dmg=math.max(1,(mv[2]+badge.sys.random(3))*e//2)
    if t.def>0 then dmg=math.max(1,dmg//2) end
    t.hp=math.max(0,t.hp-dmg)
    push(u.name.." used\n"..mv[1].."!",who,TP[a]..(mv[3] and "L" or ""))
    if e==3 then push("It's super\neffective!") elseif e==1 then push("It's not very\neffective...") end
  else push(u.name.." used\n"..mv[1].."!",who,TP[a].."L") end
  local fx,self=mv[3],who=="me" and "en" or "me"
  if fx=="burn" and t.burn==0 then t.burn=3 push(t.name.."\nwas burned!",who,"burn")
  elseif fx=="def" then u.def=3 push(u.name.."\nwithdrew into\nits shell!",self,"def")
  elseif fx=="seed" and t.seed==0 then t.seed=3 push(t.name.."\nwas seeded!",who,"grass")
  elseif fx=="par" and t.par==0 then t.par=3 push(t.name.."\nis paralyzed!",who,"par") end
end
local function tick(s,o,who)
  if s.hp==0 then return end
  if s.burn>0 then s.hp=math.max(0,s.hp-2) s.burn=s.burn-1 push(s.name.."\nis hurt by\nits burn!",who,"burn") end
  if s.seed>0 and s.hp>0 then
    s.hp=math.max(0,s.hp-3) o.hp=math.min(o.max,o.hp+3) s.seed=s.seed-1
    push("LEECH SEED saps\n"..s.name.."!",who,"seed")
  end
  if s.def>0 then s.def=s.def-1 end
end
-- Enemy acts, effects tick, then win / loss / back to the menu.
local function turn()
  if en.hp>0 then
    local go=true
    if en.par>0 then
      en.par=en.par-1
      if badge.sys.random(2)==0 then push(en.name.." is\nparalyzed! It\ncan't move!") go=false end
    end
    if go then
      local mv,fx=P[en.id][4],P[en.id][5][3]
      if badge.sys.random(10)>=6 and ((fx=="burn" and me.burn==0) or (fx=="seed" and me.seed==0)
         or (fx=="par" and me.par==0) or (fx=="def" and en.def==0)) then mv=P[en.id][5] end
      use(en,me,mv,"me")
    end
  end
  tick(me,en,"me") tick(en,me,"en")
  local f=bmenu
  if en.hp==0 then
    push(en.name.."\nfainted!")
    if own(en.id) then push("You won!",nil,"win")
    else owned=owned+BIT[en.id] push("You caught\n"..P[en.id][1].."!",nil,"win") save() end
    f=home
  elseif me.hp==0 then
    push(P[me.id][1].."\nfainted!",nil,"lose") push("You lost all\nyour Pokemon...") push("Starting over\nwith PIKACHU.")
    f=function() owned=1 act=1 seen=1 save() home() end
  end
  say(f)
end
local function encounter(i)
  en=side(i,true) team={} FX.mode(nil)
  if not met(i) then seen=seen+BIT[i] save() end
  for j=1,4 do if own(j) then team[j]=P[j][2] end end
  me=side(act)
  EB:hidden(false) EI:set_src(spr(i,false)) EI:hidden(false) log("wild "..i)
  push("Wild "..P[i][1].."\nappeared!",nil,"appear") push("Go! "..P[me.id][1].."!")
  say(bmenu)
end
local function scan(on)
  if on then
    nfc=badge.nfc.enable()
    if nfc then badge.nfc.clear() S=2 MSG:set_text("Scanning...\nHold a sticker\nto the badge.") MENU:set_text("B stop")
    else MSG:set_text("NFC reader\nunavailable.") end
  elseif nfc then badge.nfc.disable() nfc=false end
end
-- Sprite widgets need the image files, so they are created here; then the title runs.
local function start()
  EI=badge.ui.image(R,spr(1,false)) EI:align("top_right",-10,6)
  PI=badge.ui.image(R,spr(act,true)) PI:align("bottom_left",14,-70) PI:hidden(true)
  S=7 require("title") gc()
end

function on_enter(root)
  R=root gc()
  -- Default GC waits for memory to double before finishing a cycle; with this much live
  -- code and this little spare RAM that never happens. Collect continuously instead.
  gcset(100)
  P=require("data")
  act=badge.store.get_int("act",1) owned=badge.store.get_int("owned",1) seen=badge.store.get_int("seen",1)
  if not own(act) then act=1 end
  UI_ROOT=root W=require("ui") gc()
  EN,EB,EH,PN,PB,PH,MSG,MENU,BG=W.EN,W.EB,W.EH,W.PN,W.PB,W.PH,W.MSG,W.MENU,W.BG
  log(_VERSION.." ui lua "..badge.sys.heap())
  -- Render sprite images once, a few rows per tick. Bump the number when sprites change.
  if badge.store.get_int("imgs",0)~=5 then
    S=9 job=1 EB:hidden(true) PB:hidden(true) MSG:set_text("First launch:\npreparing\nsprites...") gcset(200)
  else start() end
end

function on_tick()
  local now=badge.sys.ms()
  if S==9 then
    -- 8 images x 10 parts. The continuous GC is relaxed here or the loop misses the tick deadline.
    local k=(job-1)//10+1
    -- Pikachu (id 1) is rendered 4-bit indexed as the transparency / RAM experiment.
    local id=(k+1)//2
    require("gen")(require("sprites"),id,k%2==0,spr(id,k%2==0),(job-1)%10+1,id==1 and "i4" or "rgb")
    job=job+1
    if job>80 then badge.store.set_int("imgs",5) gcset(100) gc() start() end
    return
  end
  if TITLE and TITLE.tick(now) then TITLE=nil gc() log("title dropped") end
  if FX then FX.tick(now) end
  if S~=2 or not nfc or now<nxt then return end
  nxt=now+300
  if not badge.nfc.card() then return end
  local t=badge.nfc.read_text() badge.nfc.clear()
  local m=string.match(t or "","^PKM(%d+)$")
  local i=m and tonumber(m)+1
  if i and i>=2 and i<=4 then scan(false) encounter(i) else MSG:set_text("That is not a\nPokemon sticker.") end
end

function on_button(b,k)
  local I=badge.input.BUTTON
  -- HOME is delivered to us (home_button=1); its Released is the reliable edge.
  if b==I.HOME then
    if k==badge.input.KIND.RELEASED and S~=8 and S~=9 then
      if S==7 then badge.app.exit() else scan(false) home() end
    end
    return
  end
  if k~=badge.input.KIND.PRESSED then return end
  gc()
  local up,dn,A,B=b==I.UP,b==I.DOWN,b==I.A,b==I.B
  if S==0 then
    local hm={"SCAN","SWITCH LEAD","HACKADEX","EXIT"}
    if up then cur=(cur+2)%4+1 menu(hm)
    elseif dn then cur=cur%4+1 menu(hm)
    elseif A and cur==1 then scan(true)
    elseif A and cur==3 then cur=act dex()
    elseif A and cur==4 then badge.app.exit()
    elseif A then for _=1,4 do act=act%4+1 if own(act) then break end end save() home() end
  elseif S==2 then
    if B then scan(false) home() end
  elseif S==3 then
    local it=items() local n=#it
    if up then cur=(cur+n-2)%n+1 menu(it)
    elseif dn then cur=cur%n+1 menu(it)
    elseif A and cur==3 then
      local o,t=others()
      if #o==0 then MSG:set_text("No other Pokemon\ncan fight!") return end
      S=5 cur=1 menu(t) MSG:set_text("Switch to\nwhich Pokemon?")
    elseif A then use(me,en,P[me.id][3+cur],"en") turn()
    elseif B then push("Got away safely!") say(home) end
  elseif S==5 then
    local o,t=others()
    if up then cur=(cur+#o-2)%#o+1 menu(t)
    elseif dn then cur=cur%#o+1 menu(t)
    elseif B then bmenu()
    elseif A then
      local i=o[cur]
      push("Come back,\n"..P[me.id][1].."!") team[me.id]=me.hp
      me=side(i) me.hp=team[i] PI:set_src(spr(i,true))
      push("Go! "..P[i][1].."!") turn()
    end
  elseif S==6 then
    if up then cur=(cur+2)%4+1 dex() elseif dn then cur=cur%4+1 dex() elseif B or A then home() end
  elseif S==7 then
    if A then S=8 TITLE.go(home) end
  elseif S==4 and A and not FX.busy() then advance() end
end

function on_exit()
  save() badge.led.clear() badge.led.show()
  if nfc then badge.nfc.disable() end
  if EI then EI:delete() PI:delete() end
end
