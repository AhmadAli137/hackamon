-- Pokemon data: name, hp, type (1 fire 2 water 3 grass 4 electric),
-- attack {name,power}, effect move {name,power,effect}, palette, 20x20 sprite.
-- Sprite letters index the palette; "." is transparent.
return {
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
