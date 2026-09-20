-- Sprite image renderer. Loaded only on a first launch. Each call renders two sprite
-- rows of one image (part 1..10) so the work spreads across ticks. Scale is 2.2x: every
-- fifth column and row is 3 px, the rest 2, so a 20x20 sprite becomes 44x44.
-- fmt "rgb": LVGL v9 RGB565, background baked in as cream. 3,884 bytes per image.
-- fmt "i4":  LVGL v9 4-bit indexed, palette index 0 transparent. 1,132 bytes per image.
local N,BG,W=20,0xf8f8f0,44

local function px16(c)
  local v=(c//65536//8)*2048+((c//256)%256//4)*32+(c%256//8)
  return string.char(v%256,v//256)
end
local function wd(i) return (i%5==0) and 3 or 2 end

-- SP = sprites.lua table, id = Pokemon index, mirror = face right, part = 1..10
return function(SP,id,mirror,name,part,fmt)
  local pal,spr=SP[id][1],SP[id][2]
  local keys={}
  for k in pairs(pal) do keys[#keys+1]=k end
  table.sort(keys)
  local idx={}
  for i,k in ipairs(keys) do idx[k]=i end
  local rows={}
  for y=(part-1)*2+1,part*2 do
    local o,row=(y-1)*N,nil
    if fmt=="i4" then
      local v,n={},0
      for x=1,N do
        local xx=mirror and (N+1-x) or x
        local ch=string.sub(spr,o+xx,o+xx)
        local i=(ch==".") and 0 or idx[ch]
        for _=1,wd(x) do n=n+1 v[n]=i end
      end
      local b={}
      for i=1,W//2 do b[i]=v[2*i-1]*16+v[2*i] end
      b[#b+1]=0 b[#b+1]=0                       -- pad the row to a 24-byte stride
      row=string.char(table.unpack(b))
    else
      local parts,cache={},{}
      for x=1,N do
        local xx=mirror and (N+1-x) or x
        local ch=string.sub(spr,o+xx,o+xx)
        local key=ch..wd(x)
        local p=cache[key]
        if not p then p=string.rep(px16(ch=="." and BG or pal[ch]),wd(x)) cache[key]=p end
        parts[x]=p
      end
      row=table.concat(parts)
    end
    rows[#rows+1]=string.rep(row,wd(y))
  end
  local data=table.concat(rows)
  if part==1 then
    local hdr
    if fmt=="i4" then
      -- header, then 16 palette entries as B,G,R,A; entry 0 is fully transparent
      local p={string.char(0x19,0x09,0,0,W,0,W,0,24,0,0,0),string.char(0,0,0,0)}
      for _,k in ipairs(keys) do local c=pal[k] p[#p+1]=string.char(c%256,(c//256)%256,c//65536,255) end
      for _=#keys+2,16 do p[#p+1]=string.char(0,0,0,0) end
      hdr=table.concat(p)
    else
      hdr=string.char(0x19,0x12,0,0,W,0,W,0,W*2,0,0,0)
    end
    badge.fs.write(name,hdr..data)
  else
    badge.fs.append(name,data)
  end
end
