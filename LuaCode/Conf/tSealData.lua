--******************************************************************************
-- Copyright(C) Phantom CO,.LTD. All rights reserved
-- Created by Loong's tool. Please do not edit it.
-- proto:W_纹印.xml, excel:W 纹印.xls, sheet:Sheet1
--******************************************************************************
tSealData={}
local We=tSealData
We["30021"]={id=30021, name="1级攻击纹印", type=3, lv=1, hit=22, crit=22, parts={1, 7, 8, 9, 10}, canGem=30022, num=3}
We["30022"]={id=30022, name="2级攻击纹印", type=3, lv=2, hit=44, crit=44, parts={1, 7, 8, 9, 10}, canGem=30023, num=3, need=30021}
We["30023"]={id=30023, name="3级攻击纹印", type=3, lv=3, hit=80, crit=80, parts={1, 7, 8, 9, 10}, canGem=30024, num=3, need=30022}
We["30024"]={id=30024, name="4级攻击纹印", type=3, lv=4, hit=144, crit=144, parts={1, 7, 8, 9, 10}, canGem=30025, num=3, need=30023}
We["30025"]={id=30025, name="5级攻击纹印", type=3, lv=5, hit=251, crit=251, parts={1, 7, 8, 9, 10}, canGem=30026, num=3, need=30024}
We["30026"]={id=30026, name="6级攻击纹印", type=3, lv=6, hit=432, crit=432, parts={1, 7, 8, 9, 10}, canGem=30027, num=3, need=30025}
We["30027"]={id=30027, name="7级攻击纹印", type=3, lv=7, hit=741, crit=741, parts={1, 7, 8, 9, 10}, canGem=30028, num=3, need=30026}
We["30028"]={id=30028, name="8级攻击纹印", type=3, lv=8, hit=1267, crit=1267, parts={1, 7, 8, 9, 10}, canGem=30029, num=3, need=30027}
We["30029"]={id=30029, name="9级攻击纹印", type=3, lv=9, hit=2160, crit=2160, parts={1, 7, 8, 9, 10}, num=3, need=30028}
We["30031"]={id=30031, name="1级生命纹印", type=1, lv=1, dodge=22, tena=22, parts={2, 3, 4, 5, 6}, canGem=30032, num=3}
We["30032"]={id=30032, name="2级生命纹印", type=1, lv=2, dodge=44, tena=44, parts={2, 3, 4, 5, 6}, canGem=30033, num=3, need=30031}
We["30033"]={id=30033, name="3级生命纹印", type=1, lv=3, dodge=80, tena=80, parts={2, 3, 4, 5, 6}, canGem=30034, num=3, need=30032}
We["30034"]={id=30034, name="4级生命纹印", type=1, lv=4, dodge=144, tena=144, parts={2, 3, 4, 5, 6}, canGem=30035, num=3, need=30033}
We["30035"]={id=30035, name="5级生命纹印", type=1, lv=5, dodge=251, tena=251, parts={2, 3, 4, 5, 6}, canGem=30036, num=3, need=30034}
We["30036"]={id=30036, name="6级生命纹印", type=1, lv=6, dodge=432, tena=432, parts={2, 3, 4, 5, 6}, canGem=30037, num=3, need=30035}
We["30037"]={id=30037, name="7级生命纹印", type=1, lv=7, dodge=741, tena=741, parts={2, 3, 4, 5, 6}, canGem=30038, num=3, need=30036}
We["30038"]={id=30038, name="8级生命纹印", type=1, lv=8, dodge=1267, tena=1267, parts={2, 3, 4, 5, 6}, canGem=30039, num=3, need=30037}
We["30039"]={id=30039, name="9级生命纹印", type=1, lv=9, dodge=2160, tena=2160, parts={2, 3, 4, 5, 6}, need=30038}
