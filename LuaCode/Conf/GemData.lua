--******************************************************************************
-- Copyright(C) Phantom CO,.LTD. All rights reserved
-- Created by Loong's tool. Please do not edit it.
-- proto:B_宝石.xml, excel:B 宝石.xls, sheet:Sheet1
--******************************************************************************
GemData={}
local We=GemData
We["30001"]={id=30001, name="1级攻击宝石", type=3, lv=1, atk=29, arm=7, parts={1, 7, 8, 9, 10}, canGem=30002, num=3}
We["30002"]={id=30002, name="2级攻击宝石", type=3, lv=2, atk=58, arm=14, parts={1, 7, 8, 9, 10}, canGem=30003, num=3, need=30001}
We["30003"]={id=30003, name="3级攻击宝石", type=3, lv=3, atk=107, arm=27, parts={1, 7, 8, 9, 10}, canGem=30004, num=3, need=30002}
We["30004"]={id=30004, name="4级攻击宝石", type=3, lv=4, atk=191, arm=48, parts={1, 7, 8, 9, 10}, canGem=30005, num=3, need=30003}
We["30005"]={id=30005, name="5级攻击宝石", type=3, lv=5, atk=334, arm=83, parts={1, 7, 8, 9, 10}, canGem=30006, num=3, need=30004}
We["30006"]={id=30006, name="6级攻击宝石", type=3, lv=6, atk=576, arm=144, parts={1, 7, 8, 9, 10}, canGem=30007, num=3, need=30005}
We["30007"]={id=30007, name="7级攻击宝石", type=3, lv=7, atk=988, arm=247, parts={1, 7, 8, 9, 10}, canGem=30008, num=3, need=30006}
We["30008"]={id=30008, name="8级攻击宝石", type=3, lv=8, atk=1689, arm=422, parts={1, 7, 8, 9, 10}, canGem=30009, num=3, need=30007}
We["30009"]={id=30009, name="9级攻击宝石", type=3, lv=9, atk=2880, arm=720, parts={1, 7, 8, 9, 10}, num=3, need=30008}
We["30011"]={id=30011, name="1级生命宝石", type=1, lv=1, hp=579, def=7, parts={2, 3, 4, 5, 6}, canGem=30012, num=3}
We["30012"]={id=30012, name="2级生命宝石", type=1, lv=2, hp=1160, def=14, parts={2, 3, 4, 5, 6}, canGem=30013, num=3, need=30011}
We["30013"]={id=30013, name="3级生命宝石", type=1, lv=3, hp=2147, def=27, parts={2, 3, 4, 5, 6}, canGem=30014, num=3, need=30012}
We["30014"]={id=30014, name="4级生命宝石", type=1, lv=4, hp=3824, def=48, parts={2, 3, 4, 5, 6}, canGem=30015, num=3, need=30013}
We["30015"]={id=30015, name="5级生命宝石", type=1, lv=5, hp=6677, def=83, parts={2, 3, 4, 5, 6}, canGem=30016, num=3, need=30014}
We["30016"]={id=30016, name="6级生命宝石", type=1, lv=6, hp=11525, def=144, parts={2, 3, 4, 5, 6}, canGem=30017, num=3, need=30015}
We["30017"]={id=30017, name="7级生命宝石", type=1, lv=7, hp=19768, def=247, parts={2, 3, 4, 5, 6}, canGem=30018, num=3, need=30016}
We["30018"]={id=30018, name="8级生命宝石", type=1, lv=8, hp=33779, def=422, parts={2, 3, 4, 5, 6}, canGem=30019, num=3, need=30017}
We["30019"]={id=30019, name="9级生命宝石", type=1, lv=9, hp=57600, def=720, parts={2, 3, 4, 5, 6}, need=30018}
