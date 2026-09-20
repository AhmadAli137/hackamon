-- First-launch sprite renderer: palettes and 20x20 pixel art (SPR), plus GEN which writes
-- them as LVGL v9 image files. Both are installed as globals and cleared by main.lua once
-- the images exist, so none of this stays in RAM during play.
-- Scale is 2.2x: every fifth column and row is 3 px, the rest 2, so 20x20 becomes 44x44.
-- Output is LVGL v9 4-bit indexed with palette index 0 transparent: 1,132 bytes per image.
SPR={
 {{k=0x202020,a=0xf8d030,b=0xc89820,r=0xe04040,w=0xffffff},
  ".kk..............kk..kkk............kkk..kkak..........kakk...kaak........kaak....kaaak......kaaak.....kaakkkkkkkkaak......kaaaaaaaaaaaak.....kaaaaaaaaaaaaaak....kaakwaaaaaakwaak....kaakkaaaaaakkaak....kaaaaaakkaaaaaak...krraaaakaaaakaaarrk.krraaaaakaakaaaarrk..kaaaaaaakkaaaaakkk..kaaaaaaaaaaaaakaak.kaaakaaaaaaaakaaaak.kaaaakaaaaaakaaaak..kbbaaaaaaaaaaaabbk...kkbaaakaakaaabkk......kkkkkkkkkkkkk..."}, -- Pikachu
 {{k=0x202020,a=0xf08838,b=0xc05820,c=0xf8e0a0,f=0xf8d838,g=0xf05028,w=0xffffff},
  "......kkkkk..............kaaaaak............kaaaaaaak...........kawkaawkk...........kakkaakkk...........kaaaaaaak............kaakaak..............kkkkk..............kaaaaak..kk........kaakcckaak.kk......kaaakccckaak.kf.....kaaakccckaak.kgk....kaaakccckaaakkfgk...kaakkccckbaaakffk....kakccckbbaaaakk.....kaakkkbbaaaaak.....kbaaaaaabkkkkk.....kbbkaaaaakbbk.......kbkkkaaakkkbk.......kkk.kkkkk..kk....."}, -- Charmander
 {{k=0x202020,a=0x70b0e8,b=0x3878b8,c=0xd09848,d=0x886030,e=0xf0d8a0,w=0xffffff},
  ".....kkkkkk.............kaaaaaak...........kaaaaaaaak..........kaawkaaawk..........kaakkaaakk..........kaaaaaaaak...........kaakaaak............kkaaaaakkkk........kbbkkkkkcccdk......kbbbkeeekccccdk.....kbbbkeeeekccccdk....kbbbkeeeekcccdck.....kbkkeeeekccddk.......kkeeeeekdddk.......kbbkeeekkkkk.......kbbbkkkkkbbbk.......kbbbk...kbbbk.......kbbbk...kbbbk........kkk.....kkk.........................."}, -- Squirtle
 {{k=0x202020,a=0x60c8a8,b=0x309878,c=0x80d860,d=0x40a040,r=0xd03030,w=0xffffff},
  "..........kkkkkk............kkcccccdk..........kcccddcccdk........kccdccccdcck.......kkcdccccccddk......kaakkcddccddk......kaaaaakkkkkkk......kaaaaaaaaaaaak.....kaarkaaaaaakraak....kaakkaaaaaakkaak....kaaaaaaaaaaaaaaak...kakaaaakbbaaakaak...kaakkkkaaaaaaaaak...kbaaaaaabaaaabaak....kaaaakkaaaaakbbk....kaaaak.kaaaak.kk....kbbbk..kbbbbk.......kbbbk..kbbbbk........kkk....kkkk.........................."}, -- Bulbasaur
}

local N,W=20,44
local acc,job={},0
local function wd(i) return (i%5==0) and 3 or 2 end

-- Parts 1..10 each render two sprite rows into acc; part 11 writes the file in one go.
local function render(id,mirror,name,part)
  if part==11 then badge.fs.write(name,table.concat(acc)) acc={} return end
  local pal,spr=SPR[id][1],SPR[id][2]
  local keys={}
  for k in pairs(pal) do keys[#keys+1]=k end
  table.sort(keys)
  local idx={}
  for i,k in ipairs(keys) do idx[k]=i end
  if part==1 then
    -- header, then 16 palette entries as B,G,R,A; entry 0 is fully transparent
    local p={string.char(0x19,0x09,0,0,W,0,W,0,24,0,0,0),string.char(0,0,0,0)}
    for _,k in ipairs(keys) do local c=pal[k] p[#p+1]=string.char(c%256,(c//256)%256,c//65536,255) end
    for _=#keys+2,16 do p[#p+1]=string.char(0,0,0,0) end
    acc={table.concat(p)}
  end
  for y=(part-1)*2+1,part*2 do
    local o,v,n=(y-1)*N,{},0
    for x=1,N do
      local xx=mirror and (N+1-x) or x
      local ch=string.sub(spr,o+xx,o+xx)
      local i=(ch==".") and 0 or idx[ch]
      for _=1,wd(x) do n=n+1 v[n]=i end
    end
    local b={}
    for i=1,W//2 do b[i]=v[2*i-1]*16+v[2*i] end
    b[#b+1]=0 b[#b+1]=0                         -- pad the row to a 24-byte stride
    acc[#acc+1]=string.rep(string.char(table.unpack(b)),wd(y))
  end
end

-- One step of the first-launch sequence: 8 images x 11 parts. Returns true when all are
-- written. Also removes appdata copies left by an earlier build so they do not count
-- against the storage quota.
GEN=function()
  if job==0 then
    for i=1,4 do badge.fs.remove("appdata/s"..i..".bin") badge.fs.remove("appdata/m"..i..".bin") end
  end
  job=job+1
  local k=(job-1)//11+1
  local id,mirror=(k+1)//2,(k%2==0)
  render(id,mirror,(mirror and "m" or "s")..id..".bin",(job-1)%11+1)
  if job%3==0 then collectgarbage("collect") end
  return job>=88
end
