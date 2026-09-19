-- Sprite image renderer. Loaded by main.lua only when the image files need
-- (re)building, so it is not resident during normal play.
-- Streams an LVGL v9 RGB565 image to flash five rows at a time. Scale is 2.5x:
-- columns and rows alternate 3 and 2 pixels, so a 20x20 sprite becomes 50x50.
local N,BG=20,0xf8f8f0

local function px16(c)
  local v=(c//65536//8)*2048+((c//256)%256//4)*32+(c%256//8)
  return string.char(v%256,v//256)
end

return function(P,id,mirror,name)
  local pal,spr=P[id][6],P[id][7]
  badge.fs.write(name,string.char(0x19,0x12,0,0,50,0,50,0,100,0,0,0))
  local cache,chunk={},{}
  for y=1,N do
    local o,parts=(y-1)*N,{}
    for x=1,N do
      local xx=mirror and (N+1-x) or x
      local ch=string.sub(spr,o+xx,o+xx)
      local wd=(x%2==1) and 3 or 2
      local px=cache[ch..wd]
      if not px then px=string.rep(px16(ch=="." and BG or pal[ch]),wd) cache[ch..wd]=px end
      parts[x]=px
    end
    chunk[#chunk+1]=string.rep(table.concat(parts),(y%2==1) and 3 or 2)
    if #chunk==5 then badge.fs.append(name,table.concat(chunk)) chunk={} badge.sys.gc_step() end
  end
end
