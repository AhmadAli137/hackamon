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

local N,CELL=20,4
-- name, hp, type(1 fire 2 water 3 grass 4 electric), attack, effect move, palette, 20x20 sprite as one string
local P={
 {"PIKACHU",35,4,{"QUICK ATTACK",7},{"THUNDER WAVE",0,"par"},
  {k=0x202020,a=0xf8d030,b=0xc89820,r=0xe04040,w=0xffffff},
  ".kk..............kk..kkk............kkk..kkak..........kakk...kaak........kaak....kaaak......kaaak.....kaakkkkkkkkaak......kaaaaaaaaaaaak.....kaaaaaaaaaaaaaak....kaakwaaaaaakwaak....kaakkaaaaaakkaak....kaaaaaakkaaaaaak...krraaaakaaaakaaarrk.krraaaaakaakaaaarrk..kaaaaaaakkaaaaakkk..kaaaaaaaaaaaaakaak.kaaakaaaaaaaakaaaak.kaaaakaaaaaakaaaak..kbbaaaaaaaaaaaabbk...kkbaaakaakaaabkk......kkkkkkkkkkkkk..."},
 {"CHARMANDER",39,1,{"SCRATCH",7},{"EMBER",4,"burn"},
  {k=0x202020,a=0xf08838,b=0xc05820,c=0xf8e0a0,f=0xf8d838,g=0xf05028,w=0xffffff},
  "......kkkkk..............kaaaaak............kaaaaaaak...........kawkaawkk...........kakkaakkk...........kaaaaaaak............kaakaak..............kkkkk..............kaaaaak..kk........kaakcckaak.kk......kaaakccckaak.kf.....kaaakccckaak.kgk....kaaakccckaaakkfgk...kaakkccckbaaakffk....kakccckbbaaaakk.....kaakkkbbaaaaak.....kbaaaaaabkkkkk.....kbbkaaaaakbbk.......kbkkkaaakkkbk.......kkk.kkkkk..kk....."},
 {"SQUIRTLE",44,2,{"TACKLE",7},{"WITHDRAW",0,"def"},
  {k=0x202020,a=0x70b0e8,b=0x3878b8,c=0xd09848,d=0x886030,e=0xf0d8a0,w=0xffffff},
  ".....kkkkkk.............kaaaaaak...........kaaaaaaaak..........kaawkaaawk..........kaakkaaakk..........kaaaaaaaak...........kaakaaak............kkaaaaakkkk........kbbkkkkkcccdk......kbbbkeeekccccdk.....kbbbkeeeekccccdk....kbbbkeeeekcccdck.....kbkkeeeekccddk.......kkeeeeekdddk.......kbbkeeekkkkk.......kbbbkkkkkbbbk.......kbbbk...kbbbk.......kbbbk...kbbbk........kkk.....kkk.........................."},
 {"BULBASAUR",45,3,{"TACKLE",7},{"LEECH SEED",0,"seed"},
  {k=0x202020,a=0x60c8a8,b=0x309878,c=0x80d860,d=0x40a040,r=0xd03030,w=0xffffff},
  "..........kkkkkk............kkcccccdk..........kcccddcccdk........kccdccccdcck.......kkcdccccccddk......kaakkcddccddk......kaaaaakkkkkkk......kaaaaaaaaaaaak.....kaarkaaaaaakraak....kaakkaaaaaakkaak....kaaaaaaaaaaaaaaak...kakaaaakbbaaakaak...kaakkkkaaaaaaaaak...kbaaaaaabaaaabaak....kaaaakkaaaaakbbk....kaaaak.kaaaak.kk....kbbbk..kbbbbk.......kbbbk..kbbbbk........kkk....kkkk.........................."},
}
local BIT={1,2,4,8}
local SUP={3,1,2,2}   -- type index -> the type it is strong against

local S,cur,act,owned,nfc,nxt=0,1,1,1,false,0
local me,en,team={},{},{}
local q,qi,after={},0,nil
local flash_pool,flash_end=nil,0
local EN,EB,EH,PN,PB,PH,MSG,MENU
local epool,ppool={c={}},{c={}}

local function eff(a,d)
  if SUP[a]==d then return 3 elseif SUP[d]==a or (a==4 and d==3) then return 1 end return 2
end

local function own(id) return (owned//BIT[id])%2==1 end

local function blit(pool,id,mirror)
  local pal,spr,n=P[id][6],P[id][7],0
  for y=1,N do
    local o,x=(y-1)*N,1
    while x<=N do
      local ch=string.sub(spr,o+x,o+x)
      if ch=="." then x=x+1
      else
        local x2=x
        while x2<N and string.sub(spr,o+x2+1,o+x2+1)==ch do x2=x2+1 end
        n=n+1
        local b=pool[n]
        if not b then b=badge.ui.box(pool.par,CELL,CELL) b:style({border_width=0,radius=0,pad_all=0}) pool[n]=b end
        local px=mirror and (N-x2) or (x-1)
        b:set_size((x2-x+1)*CELL,CELL) b:set_pos(px*CELL,(y-1)*CELL)
        pool.c[n]=pal[ch] b:style({bg_color=pal[ch]}) b:hidden(false)
        x=x2+1
      end
    end
  end
  for i=n+1,#pool do pool[i]:hidden(true) end
  pool.n=n
end

local function tint(pool,dark)
  for i=1,pool.n or 0 do
    local c=pool.c[i]
    if dark then c=(c//65536//3)*65536+((c//256)%256//3)*256+(c%256)//3 end
    pool[i]:style({bg_color=c})
  end
end

local function flash(who)
  flash_pool=(who=="me") and ppool or epool
  tint(flash_pool,true) flash_end=badge.sys.ms()+220
end

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

local function leds(r,g,b) badge.led.set_all(r,g,b) badge.led.show() end

local function side(id,enemy)
  return {id=id,hp=P[id][2],max=P[id][2],burn=0,seed=0,def=0,par=0,name=(enemy and "Enemy " or "")..P[id][1]}
end

local function save() badge.store.set_int("act",act) badge.store.set_int("owned",owned) end

-- Each message carries a snapshot of HP so bars move in step with the text.
local function push(m,f) q[#q+1]={m,P[me.id][1],me.hp,me.max,en.id and en.hp or 0,f} end

local function advance()
  if qi<#q then
    qi=qi+1 local e=q[qi]
    MSG:set_text(e[1]) setbars(e[2],e[3],e[4],e[5])
    if e[6] then flash(e[6]) end
    return
  end
  q,qi={},0
  local f=after after=nil
  if f then f() end
end

local function say(fn) after=fn S=4 MENU:set_text("") advance() end

local function home()
  S=0 cur=1 en={} me=side(act)
  EN:set_text("") EH:set_text("") EB:hidden(true)
  for i=1,epool.n or 0 do epool[i]:hidden(true) end
  blit(ppool,act,true) setbars(P[act][1],me.hp,me.max,0)
  MSG:set_text("What will you\ndo?") menu({"SCAN","SWITCH LEAD"})
  local c=P[act][6].a leds(c//65536,(c//256)%256,c%256)
end

local function battle_items()
  local t={P[me.id][4][1],P[me.id][5][1]}
  if owned~=BIT[me.id] then t[3]="SWITCH" end
  return t
end

local function battle_menu()
  S=3 cur=1
  MSG:set_text("What will\n"..P[me.id][1].." do?")
  menu(battle_items())
end

local function others()
  local t={}
  for i=1,4 do if own(i) and i~=me.id and (team[i] or 0)>0 then t[#t+1]=i end end
  return t
end

local function other_names()
  local o,t=others(),{}
  for i=1,#o do t[i]=P[o[i]][1] end
  return o,t
end

local function use(u,t,mv,who)
  if mv[2]>0 then
    local e=eff(P[u.id][3],P[t.id][3])
    local d=math.max(1,math.floor((mv[2]+badge.sys.random(3))*e/2))
    if t.def>0 then d=math.max(1,math.floor(d/2)) end
    t.hp=math.max(0,t.hp-d)
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

local function tick_fx(s,o,who)
  if s.hp==0 then return end
  if s.burn>0 then s.hp=math.max(0,s.hp-2) s.burn=s.burn-1 push(s.name.."\nis hurt by\nits burn!",who) end
  if s.seed>0 and s.hp>0 then
    s.hp=math.max(0,s.hp-3) o.hp=math.min(o.max,o.hp+3) s.seed=s.seed-1
    push("LEECH SEED saps\n"..s.name.."!",who)
  end
  if s.def>0 then s.def=s.def-1 end
end

local function enemy_turn()
  if en.hp==0 then return end
  if en.par>0 then
    en.par=en.par-1
    if badge.sys.random(2)==0 then push(en.name.." is\nparalyzed! It\ncan't move!") return end
  end
  local mv=P[en.id][4]
  if badge.sys.random(10)>=6 then
    local fx=P[en.id][5][3]
    if (fx=="burn" and me.burn==0) or (fx=="seed" and me.seed==0)
       or (fx=="par" and me.par==0) or (fx=="def" and en.def==0) then mv=P[en.id][5] end
  end
  use(en,me,mv,"me")
end

local function end_turn()
  tick_fx(me,en,"me") tick_fx(en,me,"en")
  local fn=battle_menu
  if en.hp==0 then
    push(en.name.."\nfainted!")
    if own(en.id) then push("You won!")
    else owned=owned+BIT[en.id] push("You caught\n"..P[en.id][1].."!") save() end
    fn=home leds(40,160,40)
  elseif me.hp==0 then
    push(P[me.id][1].."\nfainted!") push("You lost all\nyour Pokemon...") push("Starting over\nwith PIKACHU.")
    fn=function() owned=1 act=1 save() home() end
    leds(160,30,30)
  end
  say(fn)
end

local function player_turn(mv)
  use(me,en,mv,"en")
  enemy_turn()
  end_turn()
end

local function switch_to(id)
  push("Come back,\n"..P[me.id][1].."!")
  team[me.id]=me.hp
  me=side(id) me.hp=team[id]
  blit(ppool,id,true)
  push("Go! "..P[id][1].."!")
  enemy_turn()
  end_turn()
end

local function encounter(id)
  en=side(id,true) team={}
  for i=1,4 do if own(i) then team[i]=P[i][2] end end
  me=side(act)
  EB:hidden(false) blit(epool,id,false)
  leds(200,60,0)
  push("Wild "..P[id][1].."\nappeared!") push("Go! "..P[me.id][1].."!")
  say(battle_menu)
end

local function scan(on)
  if on then
    nfc=badge.nfc.enable()
    if nfc then badge.nfc.clear() S=2 MSG:set_text("Scanning...\nHold a sticker\nto the badge.") MENU:set_text("B stop")
    else MSG:set_text("NFC reader\nunavailable.") end
  elseif nfc then badge.nfc.disable() nfc=false end
end

function on_enter(root)
  act=badge.store.get_int("act",1) owned=badge.store.get_int("owned",1)
  if not own(act) then act=1 end
  -- Everything is aligned to screen edges so the layout survives any root padding.
  local bg=badge.ui.box(root,320,240) bg:style({bg_color=0xf8f8f0,border_width=0,radius=0}) bg:align("center",0,0)
  EN=badge.ui.label(root,"") EN:style({text_font=16,text_color=0x101010}) EN:align("top_left",8,6)
  EB=badge.ui.bar(root,0,100,100) EB:set_size(110,8) EB:align("top_left",8,28) EB:style({bg_color=0xc8c8c0},"main")
  EH=badge.ui.label(root,"") EH:style({text_font=14,text_color=0x101010}) EH:align("top_left",8,40)
  local esp=badge.ui.box(root,N*CELL,N*CELL) esp:style({bg_opa=0,border_width=0,pad_all=0}) esp:align("top_right",-8,4)
  local psp=badge.ui.box(root,N*CELL,N*CELL) psp:style({bg_opa=0,border_width=0,pad_all=0}) psp:align("bottom_left",8,-66)
  epool.par,ppool.par=esp,psp
  PN=badge.ui.label(root,"") PN:style({text_font=16,text_color=0x101010}) PN:align("bottom_right",-8,-112)
  PB=badge.ui.bar(root,0,100,100) PB:set_size(110,8) PB:align("bottom_right",-8,-98) PB:style({bg_color=0xc8c8c0},"main")
  PH=badge.ui.label(root,"") PH:style({text_font=16,text_color=0x101010}) PH:align("bottom_right",-8,-76)
  local dlg=badge.ui.box(root,288,60)
  dlg:style({bg_color=0xffffff,border_color=0x101010,border_width=2,radius=4,pad_all=0}) dlg:align("bottom_mid",0,-2)
  MSG=badge.ui.label(dlg,"") MSG:style({text_font=16,text_color=0x101010}) MSG:set_pos(8,3)
  MENU=badge.ui.label(dlg,"") MENU:style({text_font=16,text_color=0x101010}) MENU:set_pos(150,3)
  home()
end

function on_tick()
  local now=badge.sys.ms()
  if flash_pool and now>=flash_end then tint(flash_pool,false) flash_pool=nil end
  if S~=2 or not nfc or now<nxt then return end
  nxt=now+300
  local c=badge.nfc.card()
  if not c then return end
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
    elseif b==I.A then
      if cur==1 then scan(true)
      else for _=1,4 do act=act%4+1 if own(act) then break end end save() home() end
    end
  elseif S==2 then
    if b==I.B then scan(false) home() end
  elseif S==3 then
    local items=battle_items() local n=#items
    if b==I.UP then cur=(cur+n-2)%n+1 menu(items)
    elseif b==I.DOWN then cur=cur%n+1 menu(items)
    elseif b==I.A then
      if cur==3 then
        local o,names=other_names()
        if #o==0 then MSG:set_text("No other Pokemon\ncan fight!") return end
        S=5 cur=1 menu(names) MSG:set_text("Switch to\nwhich Pokemon?")
      else player_turn(P[me.id][3+cur]) end
    elseif b==I.B then push("Got away safely!") say(home) end
  elseif S==5 then
    local o,names=other_names()
    if b==I.UP then cur=(cur+#o-2)%#o+1 menu(names)
    elseif b==I.DOWN then cur=cur%#o+1 menu(names)
    elseif b==I.A then switch_to(o[cur])
    elseif b==I.B then battle_menu() end
  elseif S==4 then
    if b==I.A then advance() end
  end
end

function on_exit()
  save()
  badge.led.clear() badge.led.show()
  if nfc then badge.nfc.disable() end
end
