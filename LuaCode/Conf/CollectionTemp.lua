--******************************************************************************
-- Copyright(C) Phantom CO,.LTD. All rights reserved
-- Created by Loong's tool. Please do not edit it.
-- proto:C_采集物配置.xml, excel:C 采集物配置.xls, sheet:Sheet1
--******************************************************************************
CollectionTemp={}
local We=CollectionTemp
We[1]={id=100001, name="", icon="icon-sword", mod="Collection_cube", text="剑来", dis=1000}
We[2]={id=100002, name="解封封印", icon="icon-break", mod="Collection_cube", text="解封", dis=300}
We[3]={id=100003, name="解封神兵", icon="icon-steal2", mod="P_Sword02_02", text="解封", dis=100}
We[4]={id=100004, name="激活石剑", icon="icon-steal2", mod="Collection_cube", text="解封", dis=100}
We[5]={id=100005, name="白芷", icon="icon-hand", mod="SM_Evenet_mflower01", text="采集", dis=80}
We[6]={id=100006, name="水灵珠", icon="icon-hand", mod="mod_dongchaguanghuan_01", text="获取", dis=80}
We[7]={id=100007, name="", icon="icon-wuxingpan", mod="Collection_cube", text="查探", dis=80}
We[8]={id=100008, name="放置符印", icon="icon-wuxingpan", mod="Collection_cube", text="放置", dis=100}
We[9]={id=100009, name="树叶", icon="icon-hand", mod="SM_Rock_BP02", text="采集", dis=100}
We[10]={id=100010, name="符印", icon="icon-hand", mod="mod_wuxingpan_01", text="获取", dis=80}
We[11]={id=100011, name="", icon="icon-hand", mod="Collection_cube", text="取信", dis=100}
We[12]={id=100012, name="花灯", icon="icon-hand", mod="Collection_cube", text="祈福", dis=100}
We[13]={id=100014, name="", icon="icon-hand", mod="Collection_cube", text="探查", dis=100}
We[14]={id=100015, name="", icon="icon-hand", mod="Collection_cube", text="取丹", dis=100}
We[15]={id=100016, name="信鼓", icon="icon-hand", mod="Collection_cube", text="敲击", dis=100}
We[16]={id=100017, name="珊瑚", icon="icon-hand", mod="SM_Evenet_mflower01", text="采集", dis=100}
We[17]={id=100018, name="酒", icon="icon-hand", mod="Collection_cube", text="采集", dis=100}
We[18]={id=100019, name="鱼", icon="icon-hand", mod="SM_Rock_BP02", text="采集", dis=100}
We[19]={id=100020, name="鱼饵", icon="icon-hand", mod="SM_Rock_BP02", text="采集", dis=100}
We[20]={id=100021, name="烟花", icon="icon-hand", mod="Collection_cube", text="采集", dis=100}
We[21]={id=100022, name="烤鱼", icon="icon-hand", mod="SM_Rock_BP02", text="采集", dis=100}
We[22]={id=100023, name="妹纸", icon="icon-hand", mod="SM_Rock_BP02", text="采集", dis=100}
We[23]={id=100024, name="祭拜前辈", icon="icon-sacrifice", mod="Collection_cube", text="祭拜", dis=220}
We[24]={id=100025, name="前辈", icon="icon-hand", mod="SM_Rock_BP02", text="祭拜", dis=100}
We[25]={id=100026, name="琴", icon="icon-hand", mod="Event_qing", text="拾取", dis=100}
We[26]={id=100027, name="", icon="icon-med", mod="Collection_cube", text="服药", dis=100}
We[27]={id=100028, name="红玉珊瑚", icon="icon-hand", mod="Collection_cube", text="拾取", dis=170}
We[28]={id=100029, name="烧酒", icon="icon-hand", mod="Collection_cube", text="拾取", dis=100}
We[29]={id=100030, name="鱼篓", icon="icon-hand", mod="Collection_cube", text="拾取", dis=100}
We[30]={id=100031, name="烟花", icon="icon-hand", mod="Collection_cube", text="点燃", dis=100}
We[31]={id=100032, name="温酒", icon="icon-wine", mod="Collection_cube", text="饮酒", dis=120}
We[32]={id=100033, name="传送", icon="icon-portal", mod="Collection_cube", text="激活", dis=200}
We[33]={id=100034, name="激活结界", icon="icon-hand", mod="Collection_cube", text="拾取", dis=100}
We[34]={id=100035, name="满汉全席", icon="icon-hand", mod="Collection_cube", text="享用", dis=100}
We[35]={id=100036, name="", icon="icon-sword", mod="Collection_cube", text="剑来", dis=1000}
We[36]={id=100037, name="传信符石", icon="icon-learn", mod="Collection_cube", text="激活", dis=1000}
We[37]={id=100038, name="", icon="icon-break", mod="Collection_cube", text="启动", dis=120}
We[38]={id=100039, name="寒渊魂石", icon="icon-stone", mod="M_Gather_Crystal01_UI", text="采集", dis=200}
We[39]={id=100040, name="上古灵石", icon="icon-hand", mod="M_Gather_Crystal02", text="采集", dis=200}
We[40]={id=100041, name="寒渊魂石", icon="icon-stone", mod="M_Gather_Crystal01", text="采集", dis=200}
We[41]={id=100042, name="上古灵石", icon="icon-hand", mod="M_Gather_Crystal02", text="采集", dis=200}
We[42]={id=100043, name="", icon="icon-hand", mod="Collection_cube", text="触碰", dis=100}
We[43]={id=100044, name="远古灵晶", icon="icon-stone", mod="M_Gather_Crystal01_02", text="采集", dis=200}
We[44]={id=100100, name="宴席", icon="icon-hand", mod="caijiwu_tangwan", text="享用", dis=100}
We[45]={id=100101, name="喜糖", icon="icon-hand", mod="M_Weeding_xitang", text="抢", dis=200}
We[46]={id=100102, name="宴席", icon="icon-hand", mod="caijiwu_yanxi01", text="享用", dis=100}
We[47]={id=100103, name="宴席", icon="icon-hand", mod="caijiwu_yanxi02", text="享用", dis=100}
We[48]={id=200001, name="签符", icon="icon-hand", mod="Collection_cube", text="抽取", dis=100}
