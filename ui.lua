-- Builds the static widgets once and returns their handles. Reads the app root from
-- the global UI_ROOT. Only the returned table stays in memory; this code is freed.
local root=UI_ROOT
local W={}
local function lbl(f,al,x,y)
  local l=badge.ui.label(root,"") l:style({text_font=f,text_color=0x101010}) l:align(al,x,y) return l
end
local function hb(al,x,y)
  local b=badge.ui.bar(root,0,100,100) b:set_size(110,8) b:align(al,x,y) b:style({bg_color=0xc8c8c0},"main") return b
end
W.BG=badge.ui.box(root,320,240) W.BG:style({bg_color=0xf8f8f0,border_width=0,radius=0}) W.BG:align("center",0,0)
W.EN=lbl(16,"top_left",8,6) W.EB=hb("top_left",8,28) W.EH=lbl(14,"top_left",8,40)
W.PN=lbl(16,"bottom_right",-8,-112) W.PB=hb("bottom_right",-8,-98) W.PH=lbl(16,"bottom_right",-8,-76)
local d=badge.ui.box(root,288,60)
d:style({bg_color=0xffffff,border_color=0x101010,border_width=2,radius=4,pad_all=0}) d:align("bottom_mid",0,-2)
-- Fixed widths make the labels wrap and clip instead of overlapping each other.
W.MSG=badge.ui.label(d,"") W.MSG:style({text_font=14,text_color=0x101010}) W.MSG:set_size(146,54) W.MSG:set_pos(8,3)
W.MENU=badge.ui.label(d,"") W.MENU:style({text_font=14,text_color=0x101010}) W.MENU:set_size(124,54) W.MENU:set_pos(158,3)
return W
