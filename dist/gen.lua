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
local N,W,BG=20,44,0xf8f8f0
local acc,job={},0
local function wd(i) return (i%5==0) and 3 or 2 end
local function px16(c)
  local v=(c//65536//8)*2048+((c//256)%256//4)*32+(c%256//8)
  return string.char(v%256,v//256)
end
local function render(id,mirror,name,part)
  if part==11 then badge.fs.write(name,table.concat(acc)) acc={} return end
  local pal,spr=SPR[id][1],SPR[id][2]
  local keys={}
  for k in pairs(pal) do keys[#keys+1]=k end
  table.sort(keys)
  local idx={}
  for i,k in ipairs(keys) do idx[k]=i end
  if part==1 then
    if mirror then
      acc={string.char(0x19,0x12,0,0,W,0,W,0,W*2,0,0,0)}
    else
      local p={string.char(0x19,0x09,0,0,W,0,W,0,24,0,0,0),string.char(0,0,0,0)}
      for _,k in ipairs(keys) do local c=pal[k] p[#p+1]=string.char(c%256,(c//256)%256,c//65536,255) end
      for _=#keys+2,16 do p[#p+1]=string.char(0,0,0,0) end
      acc={table.concat(p)}
    end
  end
  for y=(part-1)*2+1,part*2 do
    local o,row=(y-1)*N,nil
    if mirror then
      local parts,cache={},{}
      for x=1,N do
        local ch=string.sub(spr,o+N+1-x,o+N+1-x)
        local key=ch..wd(x)
        local p=cache[key]
        if not p then p=string.rep(px16(ch=="." and BG or pal[ch]),wd(x)) cache[key]=p end
        parts[x]=p
      end
      row=table.concat(parts)
    else
      local v,n={},0
      for x=1,N do
        local ch=string.sub(spr,o+x,o+x)
        local i=(ch==".") and 0 or idx[ch]
        for _=1,wd(x) do n=n+1 v[n]=i end
      end
      local b={}
      for i=1,W//2 do b[i]=v[2*i-1]*16+v[2*i] end
      b[#b+1]=0 b[#b+1]=0                       -- pad the row to a 24-byte stride
      row=string.char(table.unpack(b))
    end
    acc[#acc+1]=string.rep(row,wd(y))
  end
end
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
