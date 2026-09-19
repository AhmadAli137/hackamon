--[==[badge-app
slug=hackamon
name=Hackamon
icon=PKM
api=2
heap_kb=96
wake_lock=1
]==]
-- HACKAMON. You start with PIKACHU. Scan NFC stickers PKM01 (Charmander),
-- PKM02 (Squirtle) or PKM03 (Bulbasaur) to battle wild Pokemon. Win to add
-- them to your team. If one of yours faints, you lose the whole team.
-- UP/DOWN move the cursor. A selects / advances text. B goes back / runs.
-- Needs data.lua (Pokemon stats and sprites) in the same app folder.
-- On first launch each sprite is rendered once into an image file (s1.bin
-- enemy view, m1.bin mirrored player view) so a sprite costs one widget.

local N,BG=20,0xf8f8f0
local P
local BIT={1,2,4,8}
local SUP={3,1,2,2}
local S,cur,act,owned,nfc,nxt=0,1,1,1,false,0
local me,en,team={},{},{}
local q,qi,after={},0,nil
local fov,fend=nil,0
local EN,EB,EH,EI,EO,PN,PB,PH,PI,PO,MSG,MENU

local function own(id) return (owned//BIT[id])%2==1 end

-- 0xRRGGBB -> little-endian RGB565 pair
local function px16(c)
  local v=(c//65536//8)*2048+((c//256)%256//4)*32+(c%256//8)
  return string.char(v%256,v//256)
end

-- Stream an LVGL v9 RGB565 image of the sprite to flash, five rows at a time,
-- so no large string is ever held in RAM.
local function build(id,scale,mirror,name)
  local pal,spr=P[id][6],P[id][7]
  local W=N*scale
  badge.fs.write(name,string.char(0x19,0x12,0,0,W%256,W//256,W%256,W//256,(W*2)%256,(W*2)//256,0,0))
  local cache,chunk={},{}
  for y=1,N do
    local o,parts=(y-1)*N,{}
    for x=1,N do
      local xx=mirror and (N+1-x) or x
      local ch=string.sub(spr,o+xx,o+xx)
      local px=cache[ch]
      if not px then px=string.rep(px16(ch=="." and BG or pal[ch]),scale) cache[ch]=px end
      parts[x]=px
    end
    chunk[#chunk+1]=string.rep(table.concat(parts),scale)
    if #chunk==5 then badge.fs.append(name,table.concat(chunk)) chunk={} end
  end
end

local function sprite(id,mirror) return (mirror and "m" or "s")..id..".bin" end

local function gc() if collectgarbage then collectgarbage("collect") else for _=1,20 do badge.sys.gc_step() end end end

local function bar(b,hp,max)
  b:set_range(0,max) b:set_value(hp)
  b:style({bg_color=(hp*4<=max) and 0xe03030 or ((hp*2<=max) and 0xe8b020 or 0x30c030)},"indicator")
end

local function setbars(name,mh,mm,eh)
  PN:set_text(name) PH:set_text(mh.."/ "..mm) bar(PB,mh,mm)
  if en.id then EN:set_text(P[en.id][1]) EH:set_text(eh.."/ "..en.max) bar(EB,eh,en.max) end
end

local function menu(items)
  local t=""
  for i=1,#items do t=t..(i==cur and "> " or "  ")..items[i].."\n" end
  MENU:set_text(t)
end

local function side(id,enemy)
  return {id=id,hp=P[id][2],max=P[id][2],burn=0,seed=0,def=0,par=0,name=(enemy and "Enemy " or "")..P[id][1]}
end

local function save() badge.store.set_int("act",act) badge.store.set_int("owned",owned) end

-- Each line carries an HP snapshot so bars move in step with the text. f = side to flash.
local function push(m,f) q[#q+1]={m,P[me.id][1],me.hp,me.max,en.id and en.hp or 0,f} end

local function advance()
  if qi<#q then
    qi=qi+1 local e=q[qi]
    MSG:set_text(e[1]) setbars(e[2],e[3],e[4],e[5])
    if e[6] then fov=(e[6]=="me") and PO or EO fov:hidden(false) fend=badge.sys.ms()+220 end
    return
  end
  q,qi={},0
  local f=after after=nil
  if f then f() end
end

local function say(fn) after=fn S=4 MENU:set_text("") advance() end

local function home()
  S=0 cur=1 en={} me=side(act)
  EN:set_text("") EH:set_text("") EB:hidden(true) EI:hidden(true)
  PI:set_src(sprite(act,true)) setbars(P[act][1],me.hp,me.max,0)
  MSG:set_text("What will you\ndo?") menu({"SCAN","SWITCH LEAD"})
  local c=P[act][6].a badge.led.set_all(c//65536,(c//256)%256,c%256) badge.led.show()
end

local function items()
  local t={P[me.id][4][1],P[me.id][5][1]}
  if owned~=BIT[me.id] then t[3]="SWITCH" end
  return t
end

local function bmenu()
  S=3 cur=1 MSG:set_text("What will\n"..P[me.id][1].." do?") menu(items())
end

local function others()
  local o,t={},{}
  for i=1,4 do if own(i) and i~=me.id and (team[i] or 0)>0 then o[#o+1]=i t[#t+1]=P[i][1] end end
  return o,t
end

local function use(u,t,mv,who)
  if mv[2]>0 then
    local a,d=P[u.id][3],P[t.id][3]
    local e=(SUP[a]==d) and 3 or ((SUP[d]==a or (a==4 and d==3)) and 1 or 2)
    local dmg=math.max(1,math.floor((mv[2]+badge.sys.random(3))*e/2))
    if t.def>0 then dmg=math.max(1,math.floor(dmg/2)) end
    t.hp=math.max(0,t.hp-dmg)
    push(u.name.." used\n"..mv[1].."!",who)
    if e==3 then push("It's super\neffective!") elseif e==1 then push("It's not very\neffective...") end
  else
    push(u.name.." used\n"..mv[1].."!")
  end
  local fx=mv[3]
  if fx=="burn" and t.burn==0 then t.burn=3 push(t.name.."\nwas burned!")
  elseif fx=="def" then u.def=3 push(u.name.."\nwithdrew into\nits shell!")
  elseif fx=="seed" and t.seed==0 then t.seed=3 push(t.name.."\nwas seeded!")
  elseif fx=="par" and t.par==0 then t.par=3 push(t.name.."\nis paralyzed!") end
end

local function fx_tick(s,o,who)
  if s.hp==0 then return end
  if s.burn>0 then s.hp=math.max(0,s.hp-2) s.burn=s.burn-1 push(s.name.."\nis hurt by\nits burn!",who) end
  if s.seed>0 and s.hp>0 then
    s.hp=math.max(0,s.hp-3) o.hp=math.min(o.max,o.hp+3) s.seed=s.seed-1
    push("LEECH SEED saps\n"..s.name.."!",who)
  end
  if s.def>0 then s.def=s.def-1 end
end

-- Enemy acts, end-of-turn effects tick, then win / loss / next menu.
local function finish_turn()
  if en.hp>0 then
    local skip=false
    if en.par>0 then
      en.par=en.par-1
      if badge.sys.random(2)==0 then push(en.name.." is\nparalyzed! It\ncan't move!") skip=true end
    end
    if not skip then
      local mv,fx=P[en.id][4],P[en.id][5][3]
      if badge.sys.random(10)>=6 and ((fx=="burn" and me.burn==0) or (fx=="seed" and me.seed==0)
         or (fx=="par" and me.par==0) or (fx=="def" and en.def==0)) then mv=P[en.id][5] end
      use(en,me,mv,"me")
    end
  end
  fx_tick(me,en,"me") fx_tick(en,me,"en")
  local fn=bmenu
  if en.hp==0 then
    push(en.name.."\nfainted!")
    if own(en.id) then push("You won!")
    else owned=owned+BIT[en.id] push("You caught\n"..P[en.id][1].."!") save() end
    fn=home badge.led.set_all(40,160,40) badge.led.show()
  elseif me.hp==0 then
    push(P[me.id][1].."\nfainted!") push("You lost all\nyour Pokemon...") push("Starting over\nwith PIKACHU.")
    fn=function() owned=1 act=1 save() home() end
    badge.led.set_all(160,30,30) badge.led.show()
  end
  say(fn)
end

local function encounter(id)
  en=side(id,true) team={}
  for i=1,4 do if own(i) then team[i]=P[i][2] end end
  me=side(act)
  EB:hidden(false) EI:set_src(sprite(id,false)) EI:hidden(false)
  badge.led.set_all(200,60,0) badge.led.show()
  push("Wild "..P[id][1].."\nappeared!") push("Go! "..P[me.id][1].."!")
  say(bmenu)
end

local function scan(on)
  if on then
    nfc=badge.nfc.enable()
    if nfc then badge.nfc.clear() S=2 MSG:set_text("Scanning...\nHold a sticker\nto the badge.") MENU:set_text("B stop")
    else MSG:set_text("NFC reader\nunavailable.") end
  elseif nfc then badge.nfc.disable() nfc=false end
end

function on_enter(root)
  P=require("data")
  act=badge.store.get_int("act",1) owned=badge.store.get_int("owned",1)
  if not own(act) then act=1 end
  -- Render sprite images once; bump the version number whenever data.lua sprites change.
  if badge.store.get_int("imgs",0)~=2 then
    for i=1,4 do build(i,3,false,sprite(i,false)) gc() build(i,2,true,sprite(i,true)) gc() end
    badge.store.set_int("imgs",2)
  end
  local function lbl(font,al,x,y)
    local l=badge.ui.label(root,"") l:style({text_font=font,text_color=0x101010}) l:align(al,x,y) return l
  end
  local function hbar(al,x,y)
    local b=badge.ui.bar(root,0,100,100) b:set_size(110,8) b:align(al,x,y) b:style({bg_color=0xc8c8c0},"main") return b
  end
  local function shade(w,al,x,y)
    local b=badge.ui.box(root,w,w) b:style({bg_color=0x000000,bg_opa=150,border_width=0,radius=0}) b:align(al,x,y) b:hidden(true) return b
  end
  local bg=badge.ui.box(root,320,240) bg:style({bg_color=BG,border_width=0,radius=0}) bg:align("center",0,0)
  EN=lbl(16,"top_left",8,6) EB=hbar("top_left",8,28) EH=lbl(14,"top_left",8,40)
  EI=badge.ui.image(root,sprite(1,false)) EI:align("top_right",-10,6)
  PI=badge.ui.image(root,sprite(act,true)) PI:align("bottom_left",14,-70)
  EO=shade(60,"top_right",-10,6) PO=shade(40,"bottom_left",14,-70)
  PN=lbl(16,"bottom_right",-8,-112) PB=hbar("bottom_right",-8,-98) PH=lbl(16,"bottom_right",-8,-76)
  local dlg=badge.ui.box(root,288,60)
  dlg:style({bg_color=0xffffff,border_color=0x101010,border_width=2,radius=4,pad_all=0}) dlg:align("bottom_mid",0,-2)
  MSG=badge.ui.label(dlg,"") MSG:style({text_font=16,text_color=0x101010}) MSG:set_pos(8,3)
  MENU=badge.ui.label(dlg,"") MENU:style({text_font=16,text_color=0x101010}) MENU:set_pos(150,3)
  home()
end

function on_tick()
  local now=badge.sys.ms()
  if fov and now>=fend then fov:hidden(true) fov=nil end
  if S~=2 or not nfc or now<nxt then return end
  nxt=now+300
  if not badge.nfc.card() then return end
  local t=badge.nfc.read_text() badge.nfc.clear()
  local m=string.match(t or "","^PKM(%d+)$")
  local id=m and tonumber(m)+1
  if id and id>=2 and id<=4 then scan(false) encounter(id)
  else MSG:set_text("That is not a\nPokemon sticker.") end
end

function on_button(b,k)
  if k~=badge.input.KIND.PRESSED then return end
  local I=badge.input.BUTTON
  if S==0 then
    if b==I.UP or b==I.DOWN then cur=3-cur menu({"SCAN","SWITCH LEAD"})
    elseif b==I.A and cur==1 then scan(true)
    elseif b==I.A then for _=1,4 do act=act%4+1 if own(act) then break end end save() home() end
  elseif S==2 then
    if b==I.B then scan(false) home() end
  elseif S==3 then
    local it=items() local n=#it
    if b==I.UP then cur=(cur+n-2)%n+1 menu(it)
    elseif b==I.DOWN then cur=cur%n+1 menu(it)
    elseif b==I.A and cur==3 then
      local o,names=others()
      if #o==0 then MSG:set_text("No other Pokemon\ncan fight!") return end
      S=5 cur=1 menu(names) MSG:set_text("Switch to\nwhich Pokemon?")
    elseif b==I.A then use(me,en,P[me.id][3+cur],"en") finish_turn()
    elseif b==I.B then push("Got away safely!") say(home) end
  elseif S==5 then
    local o,names=others()
    if b==I.UP then cur=(cur+#o-2)%#o+1 menu(names)
    elseif b==I.DOWN then cur=cur%#o+1 menu(names)
    elseif b==I.B then bmenu()
    elseif b==I.A then
      local id=o[cur]
      push("Come back,\n"..P[me.id][1].."!") team[me.id]=me.hp
      me=side(id) me.hp=team[id] PI:set_src(sprite(id,true))
      push("Go! "..P[id][1].."!") finish_turn()
    end
  elseif S==4 and b==I.A then advance()
  end
end

function on_exit()
  save()
  badge.led.clear() badge.led.show()
  if nfc then badge.nfc.disable() end
end
