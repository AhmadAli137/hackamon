--[==[badge-app
slug=hackamon
name=Hackamon
icon=PKM
api=2
heap_kb=48
wake_lock=1
]==]
-- HACKAMON. Scan an NFC sticker holding the text PKM01, PKM02 or PKM03
-- to meet a wild Pokemon and battle it. Beat it to add it to your team.
-- Menus: UP/DOWN move the cursor, A selects, B goes back / runs.
-- In battle, A advances the dialogue.

local CELL=5
-- name, hp, type, attack move {name,power}, effect move {name,power,effect}, palette, 16x16 sprite
local P={
 {"CHARMANDER",39,1,{"SCRATCH",7},{"EMBER",4,"burn"},
  {k=0x202020,a=0xf08838,b=0xc05820,c=0xf8e090,f=0xf8d838,g=0xf06028,w=0xffffff},
  {"......kkk.......",
   ".....kaaak......",
   "....kaaaaak.....",
   "....kawkawk.....",
   "....kaaaaak.....",
   "....kkaaakk.....",
   "...kaakkkkaak...",
   "..kaaakccckaak..",
   "..kaaakccckaak.g",
   "..kkaakcccbaakgf",
   "...kaaakkkaaakff",
   "...kbaaaaaabkkgf",
   "..kbbkaaaakbbbk.",
   "..kbkkkaakkkbk..",
   "...k..kaak..k...",
   "......kkkk......"}},
 {"SQUIRTLE",44,2,{"TACKLE",7},{"WITHDRAW",0,"def"},
  {k=0x202020,a=0x70b0e8,b=0x3878b8,c=0xd09848,d=0x886030,e=0xf8e8c0,w=0xffffff},
  {"....kkkkk.......",
   "...kaaaaak......",
   "..kaaaaaaak.....",
   "..kawkaawak.....",
   "..kaaaaaaak.....",
   "..kkaaaaakk.....",
   "...kkaaakkkk....",
   "..kbbkaakcccdk..",
   ".kbbbkeekccccdk.",
   ".kbbbkeekcccdk..",
   ".kbbkkeeekdddk..",
   "..kkkeeeekkkk...",
   "...kbkeekbbk....",
   "..kbbkkkkbbk....",
   "..kkk...kkk.....",
   "................"}},
 {"BULBASAUR",45,3,{"TACKLE",7},{"LEECH SEED",0,"seed"},
  {k=0x202020,a=0x60c8a8,b=0x309878,c=0x80d860,d=0x40a040,w=0xffffff},
  {"........kkkkk...",
   ".......kcccdck..",
   "......kccdcccdk.",
   "....kkkcdcccdck.",
   "...kaaakkccddk..",
   "..kaaaaaakkkk...",
   ".kawkawaaabak...",
   ".kaaaaaaaaaak...",
   ".kakaaaakbaabk..",
   ".kaakkkaaaaabk..",
   ".kbaaaaabaaabk..",
   "..kaaakkaaakbk..",
   "..kaaak.kaaakk..",
   "..kbbk..kbbbk...",
   "..kkk...kkkk....",
   "................"}},
}

local S,cur,act,owned,nfc,nxt=0,1,0,0,false,0
local BIT={1,2,4}
local me,en={},{}
local q,qi,after={},0,nil
local root_,EN,EB,PN,PB,PH,MSG,MENU
local epool,ppool={},{}

-- type ring: fire(1) > grass(3) > water(2) > fire(1). Returns 3, 2 or 1 (x1.5, x1, x0.5).
local function eff(a,d)
  if (a-2)%3+1==d then return 3 elseif (d-2)%3+1==a then return 1 end return 2
end

local function blit(pool,id,ox,oy,mirror)
  local pal,spr,n=P[id][6],P[id][7],0
  for y=1,16 do
    local row,x=spr[y],1
    while x<=16 do
      local ch=string.sub(row,x,x)
      if ch=="." then x=x+1
      else
        local x2=x
        while x2<16 and string.sub(row,x2+1,x2+1)==ch do x2=x2+1 end
        n=n+1
        local b=pool[n]
        if not b then b=badge.ui.box(root_,CELL,CELL) b:style({border_width=0,radius=0}) pool[n]=b end
        local px=mirror and (16-x2) or (x-1)
        b:set_size((x2-x+1)*CELL,CELL) b:set_pos(ox+px*CELL,oy+(y-1)*CELL)
        b:style({bg_color=pal[ch]}) b:hidden(false)
        x=x2+1
      end
    end
  end
  for i=n+1,#pool do pool[i]:hidden(true) end
end

local function hide(pool) for i=1,#pool do pool[i]:hidden(true) end end

local function bar(b,hp,max)
  b:set_range(0,max) b:set_value(hp)
  b:style({bg_color=(hp*4<=max) and 0xe03030 or ((hp*2<=max) and 0xe8b020 or 0x30c030)},"indicator")
end

local function refresh()
  PN:set_text(P[me.id][1]) PH:set_text(me.hp.."/ "..me.max) bar(PB,me.hp,me.max)
  if en.id then EN:set_text(P[en.id][1]) bar(EB,en.hp,en.max) end
end

local function menu(items)
  local t=""
  for i=1,#items do t=t..(i==cur and "> " or "  ")..items[i].."\n" end
  MENU:set_text(t)
end

local function leds(r,g,b) badge.led.set_all(r,g,b) badge.led.show() end

local function side(id,enemy)
  return {id=id,hp=P[id][2],max=P[id][2],burn=0,seed=0,def=0,name=(enemy and "Enemy " or "")..P[id][1]}
end

local function save() badge.store.set_int("act",act) badge.store.set_int("owned",owned) end

local function home()
  S=1 cur=1 en.id=nil
  me=side(act,false)
  EN:set_text("") EB:hidden(true) hide(epool)
  blit(ppool,act,14,92,true) refresh()
  MSG:set_text("What will you\ndo?")
  menu({"SCAN","SWITCH"})
  local c=P[act][6] leds(c.a//65536,(c.a//256)%256,c.a%256)
end

local function push(m) q[#q+1]=m end

local function advance()
  if qi<#q then qi=qi+1 MSG:set_text(q[qi]) refresh() return end
  q,qi={},0
  local f=after after=nil
  if f then f() end
end

local function say(list,fn) q,qi,after=list,0,fn S=4 MENU:set_text("") advance() end

local function battle_menu()
  S=3 cur=1
  MSG:set_text("What will\n"..P[me.id][1].." do?")
  menu({P[me.id][4][1],P[me.id][5][1]})
end

local function use(u,t,mv)
  push(u.name.." used\n"..mv[1].."!")
  if mv[2]>0 then
    local e=eff(P[u.id][3],P[t.id][3])
    local d=math.max(1,math.floor((mv[2]+badge.sys.random(3))*e/2))
    if t.def>0 then d=math.max(1,math.floor(d/2)) end
    t.hp=math.max(0,t.hp-d)
    if e==3 then push("It's super\neffective!") elseif e==1 then push("It's not very\neffective...") end
  end
  local fx=mv[3]
  if fx=="burn" then
    if t.burn==0 then t.burn=3 push(t.name.."\nwas burned!") end
  elseif fx=="def" then
    u.def=3 push(u.name.."\nwithdrew into\nits shell!")
  elseif fx=="seed" then
    if t.seed==0 then t.seed=3 push(t.name.."\nwas seeded!") end
  end
end

local function tick_fx(s,o)
  if s.hp==0 then return end
  if s.burn>0 then s.hp=math.max(0,s.hp-2) s.burn=s.burn-1 push(s.name.."\nis hurt by\nits burn!") end
  if s.seed>0 and s.hp>0 then
    s.hp=math.max(0,s.hp-3) o.hp=math.min(o.max,o.hp+3) s.seed=s.seed-1
    push("LEECH SEED saps\n"..s.name.."!")
  end
  if s.def>0 then s.def=s.def-1 end
end

local function player_turn(mv)
  q,qi={},0
  use(me,en,mv)
  if en.hp>0 then
    local emv=(badge.sys.random(10)<6) and P[en.id][4] or P[en.id][5]
    use(en,me,emv)
    tick_fx(me,en) tick_fx(en,me)
  end
  local fn=battle_menu
  if en.hp==0 then
    push(en.name.."\nfainted!")
    local bitv=BIT[en.id]
    if (owned//bitv)%2==0 then owned=owned+bitv push("You caught\n"..P[en.id][1].."!") save()
    else push("You won!") end
    fn=home leds(40,160,40)
  elseif me.hp==0 then
    push(me.name.."\nfainted!") push("You blacked out!")
    fn=home leds(160,30,30)
  end
  say(q,fn)
end

local function encounter(id)
  S=3
  en=side(id,true) me.burn,me.seed,me.def=0,0,0
  EB:hidden(false) blit(epool,id,228,6,false) refresh()
  leds(200,60,0)
  say({"Wild "..P[id][1].."\nappeared!","Go! "..P[me.id][1].."!"},battle_menu)
end

local function scan(on)
  if on then
    nfc=badge.nfc.enable()
    if nfc then badge.nfc.clear() S=2 MSG:set_text("Scanning...\nHold a sticker\nto the badge.") MENU:set_text("B stop")
    else MSG:set_text("NFC reader\nunavailable.") end
  else
    if nfc then badge.nfc.disable() nfc=false end
  end
end

function on_enter(root)
  root_=root
  act=badge.store.get_int("act",0) owned=badge.store.get_int("owned",0)
  local bg=badge.ui.box(root,320,240) bg:style({bg_color=0xf8f8f0,border_width=0,radius=0}) bg:set_pos(0,0)
  EN=badge.ui.label(root,"") EN:style({text_font=18,text_color=0x101010}) EN:set_pos(12,10)
  EB=badge.ui.bar(root,0,100,100) EB:set_size(120,8) EB:set_pos(12,34) EB:style({bg_color=0xc8c8c0},"main")
  PN=badge.ui.label(root,"") PN:style({text_font=18,text_color=0x101010}) PN:set_pos(190,96)
  PB=badge.ui.bar(root,0,100,100) PB:set_size(120,8) PB:set_pos(190,120) PB:style({bg_color=0xc8c8c0},"main")
  PH=badge.ui.label(root,"") PH:style({text_font=16,text_color=0x101010}) PH:set_pos(236,132)
  local dlg=badge.ui.box(root,312,60)
  dlg:style({bg_color=0xffffff,border_color=0x101010,border_width=2,radius=4,pad_all=0}) dlg:set_pos(4,176)
  MSG=badge.ui.label(dlg,"") MSG:style({text_font=16,text_color=0x101010}) MSG:set_pos(8,4)
  MENU=badge.ui.label(dlg,"") MENU:style({text_font=16,text_color=0x101010}) MENU:set_pos(196,4)
  if act==0 then
    S=0 cur=1 EB:hidden(true)
    MSG:set_text("Choose your\nfirst Pokemon!")
    menu({P[1][1],P[2][1],P[3][1]})
    me=side(1,false) blit(ppool,1,14,92,true) refresh()
  else
    home()
  end
end

function on_tick()
  if S~=2 or not nfc then return end
  local now=badge.sys.ms()
  if now<nxt then return end
  nxt=now+300
  local c=badge.nfc.card()
  if not c then return end
  local t=badge.nfc.read_text() badge.nfc.clear()
  local m=string.match(t or "","^PKM(%d+)$")
  local id=m and tonumber(m)
  if id and P[id] then scan(false) encounter(id)
  else MSG:set_text("That is not a\nPokemon sticker.") end
end

function on_button(b,k)
  if k~=badge.input.KIND.PRESSED then return end
  local I=badge.input.BUTTON
  if S==0 then
    if b==I.UP then cur=(cur+1)%3+1 elseif b==I.DOWN then cur=cur%3+1
    elseif b==I.A then act=cur owned=BIT[cur] save() home() return end
    menu({P[1][1],P[2][1],P[3][1]}) me=side(cur,false) blit(ppool,cur,14,92,true) refresh()
  elseif S==1 then
    if b==I.UP or b==I.DOWN then cur=3-cur menu({"SCAN","SWITCH"})
    elseif b==I.A then
      if cur==1 then scan(true)
      else
        for _=1,3 do act=act%3+1 if (owned//BIT[act])%2==1 then break end end
        save() home()
      end
    end
  elseif S==2 then
    if b==I.B then scan(false) home() end
  elseif S==3 then
    if b==I.UP or b==I.DOWN then cur=3-cur menu({P[me.id][4][1],P[me.id][5][1]})
    elseif b==I.A then player_turn(P[me.id][3+cur])
    elseif b==I.B then say({"Got away safely!"},home) end
  elseif S==4 then
    if b==I.A then advance() end
  end
end

function on_exit()
  save()
  badge.led.clear() badge.led.show()
  if nfc then badge.nfc.disable() end
end
