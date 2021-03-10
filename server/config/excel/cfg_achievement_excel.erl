-module(cfg_achievement_excel).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(101001, {c_achievement,101001,"初出茅庐",1,110101,0,1000,"3060500,1",0})
?C(101002, {c_achievement,101002,"初露锋芒",1,110101,0,2000,"220024,1",0})
?C(101003, {c_achievement,101003,"初窥仙途",1,110101,0,3000,"3060500,1",0})
?C(101004, {c_achievement,101004,"小有成就",1,110101,0,5000,"3060500,1",0})
?C(101005, {c_achievement,101005,"登堂入室",1,110101,0,6000,"3060500,1",0})
?C(101006, {c_achievement,101006,"出类拔萃",1,110101,0,7000,"220025,1",0})
?C(101007, {c_achievement,101007,"游刃有余",1,110101,0,8000,"3060500,1",0})
?C(101008, {c_achievement,101008,"炉火纯青",1,110101,0,9000,"3060500,1",0})
?C(101009, {c_achievement,101009,"天人合一",1,110101,0,10000,"220026,1",0})
?C(101010, {c_achievement,101010,"无与伦比",1,110101,0,11000,"3060400,1",0})
?C(101011, {c_achievement,101011,"傲视群雄",1,110101,0,12000,"3060400,1",0})
?C(101012, {c_achievement,101012,"惊世骇俗",1,110101,0,13000,"3060400,1",0})
?C(101013, {c_achievement,101013,"所向披靡",1,110101,0,14000,"220027,1",0})
?C(101014, {c_achievement,101014,"举世无双",1,110101,0,15000,"3060400,1",0})
?C(101015, {c_achievement,101015,"空前绝后",1,110101,0,16000,"3060400,1",0})
?C(101016, {c_achievement,101016,"超凡入圣",1,110101,0,17000,"3060400,1",0})
?C(101017, {c_achievement,101017,"震古烁今",1,110101,0,18000,"3060200,1",0})
?C(101018, {c_achievement,101018,"登峰造极",1,110101,0,19000,"3060200,1",0})
?C(101019, {c_achievement,101019,"一代仙师",1,110101,0,20000,"220028,1",0})
?C(101020, {c_achievement,101020,"仙震四方",1,110101,0,21000,"3060200,1",0})
?C(101021, {c_achievement,101021,"仙镇寰宇",1,110101,0,22000,"3060200,1",0})
?C(101022, {c_achievement,101022,"仙道鸿钧",1,110101,0,23000,"3060200,1",0})
?C(101023, {c_achievement,101023,"返璞归真",1,110101,0,24000,"3060200,1",0})
?C(201001, {c_achievement,201001,"道无止境（一）",2,220101,0,140,"30402,5;3,5",40})
?C(201002, {c_achievement,201002,"道无止境（二）",2,220101,0,200,"30402,5;3,10",50})
?C(201003, {c_achievement,201003,"道无止境（三）",2,220101,0,230,"30402,5;3,10",50})
?C(201004, {c_achievement,201004,"道无止境（四）",2,220101,0,250,"30402,5;3,15",70})
?C(201005, {c_achievement,201005,"道无止境（五）",2,220101,0,280,"30402,5;3,20",90})
?C(201006, {c_achievement,201006,"道无止境（六）",2,220101,0,320,"30402,5;3,25",110})
?C(201007, {c_achievement,201007,"终点也是起点",2,220101,0,370,"30402,5;3,30",150})
?C(201008, {c_achievement,201008,"一飞冲天（一）",2,220201,0,10,"30402,5;3,5",40})
?C(201009, {c_achievement,201009,"一飞冲天（二）",2,220201,0,30,"30402,5;3,5",40})
?C(201010, {c_achievement,201010,"一飞冲天（三）",2,220201,0,50,"30402,5;3,10",50})
?C(201011, {c_achievement,201011,"一飞冲天（四）",2,220201,0,70,"30402,5;3,10",50})
?C(201012, {c_achievement,201012,"一飞冲天（五）",2,220201,0,100,"30402,5;3,10",60})
?C(201013, {c_achievement,201013,"一飞冲天（六）",2,220201,0,130,"30402,5;3,10",60})
?C(201014, {c_achievement,201014,"一飞冲天（七）",2,220201,0,160,"30402,5;3,10",70})
?C(201015, {c_achievement,201015,"一飞冲天（八）",2,220201,0,200,"30402,5;3,10",70})
?C(201016, {c_achievement,201016,"百炼成神（一）",2,220301,0,10,"1,500000;3,5",40})
?C(201017, {c_achievement,201017,"百炼成神（二）",2,220301,0,30,"1,500000;3,10",40})
?C(201018, {c_achievement,201018,"百炼成神（三）",2,220301,0,50,"1,500000;3,10",50})
?C(201019, {c_achievement,201019,"百炼成神（四）",2,220301,0,70,"1,500000;3,15",50})
?C(201020, {c_achievement,201020,"百炼成神（五）",2,220301,0,100,"1,500000;3,15",60})
?C(201021, {c_achievement,201021,"百炼成神（六）",2,220301,0,130,"1,500000;3,20",60})
?C(201022, {c_achievement,201022,"百炼成神（七）",2,220301,0,160,"1,500000;3,20",70})
?C(201023, {c_achievement,201023,"百炼成神（八）",2,220301,0,200,"1,500000;3,25",70})
?C(201024, {c_achievement,201024,"先天至宝（一）",2,220401,0,10,"30402,5;3,5",40})
?C(201025, {c_achievement,201025,"先天至宝（二）",2,220401,0,30,"30402,5;3,5",40})
?C(201026, {c_achievement,201026,"先天至宝（三）",2,220401,0,50,"30402,5;3,10",50})
?C(201027, {c_achievement,201027,"先天至宝（四）",2,220401,0,70,"30402,5;3,10",50})
?C(201028, {c_achievement,201028,"先天至宝（五）",2,220401,0,100,"30402,5;3,10",60})
?C(201029, {c_achievement,201029,"先天至宝（六）",2,220401,0,130,"30402,5;3,10",60})
?C(201030, {c_achievement,201030,"先天至宝（七）",2,220401,0,160,"30402,5;3,10",70})
?C(201031, {c_achievement,201031,"先天至宝（八）",2,220401,0,200,"30402,5;3,10",70})
?C(201032, {c_achievement,201032,"有翅膀的人",2,220601,3050100,1,"1,1000000;3,10",100})
?C(201033, {c_achievement,201033,"冲上云霄",2,220601,3050200,1,"1,2000000;3,15",200})
?C(201034, {c_achievement,201034,"一万英尺的高空",2,220601,3050300,1,"1,3000000;3,20",300})
?C(201035, {c_achievement,201035,"展翅翱翔",2,220601,3050400,1,"1,4000000;3,25",400})
?C(201036, {c_achievement,201036,"哟！宝贝",2,220601,3020100,1,"1,1000000;3,10",100})
?C(201037, {c_achievement,201037,"如获至宝",2,220601,3020200,1,"1,2000000;3,15",200})
?C(201038, {c_achievement,201038,"亮瞎敌人的双眼",2,220601,3020300,1,"1,3000000;3,20",300})
?C(201039, {c_achievement,201039,"宝塔镇河妖",2,220601,3020400,1,"1,4000000;3,25",400})
?C(201040, {c_achievement,201040,"我欲诛仙",2,220601,3040100,1,"1,3000000;3,25",100})
?C(201041, {c_achievement,201041,"月煌虚引",2,220601,3040200,1,"1,3000000;3,25",100})
?C(201042, {c_achievement,201042,"境界提升（一）",2,220701,1101,1,"30402,5;3,5",20})
?C(201043, {c_achievement,201043,"境界提升（二）",2,220701,1201,1,"30402,5;3,5",30})
?C(201044, {c_achievement,201044,"境界提升（三）",2,220701,1301,1,"30402,5;3,10",40})
?C(201045, {c_achievement,201045,"境界提升（四）",2,220701,1401,1,"30402,5;3,10",50})
?C(201046, {c_achievement,201046,"境界提升（五）",2,220701,1501,1,"30402,5;3,10",60})
?C(201047, {c_achievement,201047,"境界提升（六）",2,220701,1601,1,"30402,10;3,15",70})
?C(201048, {c_achievement,201048,"境界提升（七）",2,220701,1701,1,"30402,10;3,15",80})
?C(201049, {c_achievement,201049,"境界提升（八）",2,220701,1801,1,"30402,10;3,20",90})
?C(201050, {c_achievement,201050,"境界提升（九）",2,220701,1901,1,"30402,10;3,20",100})
?C(201051, {c_achievement,201051,"境界提升（十）",2,220701,2001,1,"30402,10;3,30",150})
?C(201052, {c_achievement,201052,"境界提升（十一）",2,220701,2101,1,"30402,20;3,40",200})
?C(201053, {c_achievement,201053,"境界提升（十二）",2,220701,2201,1,"30402,20;3,50",250})
?C(201054, {c_achievement,201054,"境界提升（十三）",2,220701,2301,1,"30402,20;3,60",300})
?C(201055, {c_achievement,201055,"境界提升（十四）",2,220701,2401,1,"30402,20;3,70",350})
?C(201056, {c_achievement,201056,"境界提升（十五）",2,220701,2501,1,"30402,20;3,80",400})
?C(201057, {c_achievement,201057,"境界提升（十六）",2,220701,2601,1,"30402,30;3,90",450})
?C(201058, {c_achievement,201058,"境界提升（十七）",2,220701,2701,1,"30402,30;3,100",500})
?C(201059, {c_achievement,201059,"境界提升（十八）",2,220701,2801,1,"30402,30;3,110",500})
?C(201060, {c_achievement,201060,"境界提升（十九）",2,220701,2901,1,"30402,30;3,120",500})
?C(201061, {c_achievement,201061,"蜀门至宝",2,220601,3021100,1,"1,4000000;3,25",400})
?C(301001, {c_achievement,301001,"仙途跋涉（一）",3,330101,0,2,"30402,3;3,5",60})
?C(301002, {c_achievement,301002,"仙途跋涉（二）",3,330101,0,3,"30402,4;3,10",70})
?C(301003, {c_achievement,301003,"仙途跋涉（三）",3,330101,0,4,"30402,6;3,10",80})
?C(301004, {c_achievement,301004,"仙途跋涉（四）",3,330101,0,5,"30402,8;3,15",90})
?C(301005, {c_achievement,301005,"仙途跋涉（五）",3,330101,0,6,"30402,10;3,15",100})
?C(301006, {c_achievement,301006,"形影不离（一）",3,330201,0,2,"30402,3;3,5",60})
?C(301007, {c_achievement,301007,"形影不离（二）",3,330201,0,3,"30402,4;3,10",70})
?C(301008, {c_achievement,301008,"形影不离（三）",3,330201,0,4,"30402,6;3,10",80})
?C(301009, {c_achievement,301009,"形影不离（四）",3,330201,0,5,"30402,8;3,15",90})
?C(301010, {c_achievement,301010,"形影不离（五）",3,330201,0,6,"30402,10;3,15",100})
?C(301011, {c_achievement,301011,"不能浪费（一）",3,330202,0,50,"30402,5;3,5",60})
?C(301012, {c_achievement,301012,"不能浪费（二）",3,330202,0,100,"30402,5;3,10",70})
?C(301013, {c_achievement,301013,"不能浪费（三）",3,330202,0,200,"30402,5;3,10",80})
?C(301014, {c_achievement,301014,"不能浪费（四）",3,330202,0,300,"30402,5;3,15",90})
?C(301015, {c_achievement,301015,"不能浪费（五）",3,330202,0,400,"30402,5;3,15",100})
?C(401001, {c_achievement,401001,"无敌的装备（一）",4,440101,1,1,"1,200000;3,10",40})
?C(401002, {c_achievement,401002,"无敌的装备（二）",4,440101,2,1,"1,500000;3,15",60})
?C(401003, {c_achievement,401003,"无敌的装备（三）",4,440101,3,1,"1,1000000;3,15",200})
?C(401004, {c_achievement,401004,"雍容华贵",4,440102,9,1,"1,1000000;3,15",100})
?C(401005, {c_achievement,401005,"珠光宝气",4,440102,10,1,"1,1000000;3,15",100})
?C(401006, {c_achievement,401006,"雷劫套装（一）",4,440104,1,5,"6100001,5;3,5",30})
?C(401007, {c_achievement,401007,"雷劫套装（二）",4,440104,2,5,"6100001,5;3,5",40})
?C(401008, {c_achievement,401008,"雷劫套装（三）",4,440104,3,5,"6100001,10;3,5",50})
?C(401009, {c_achievement,401009,"雷劫套装（四）",4,440104,4,5,"6100001,10;3,5",60})
?C(401010, {c_achievement,401010,"雷劫套装（五）",4,440104,5,5,"6100001,20;3,5",70})
?C(401011, {c_achievement,401011,"雷劫套装（六）",4,440104,6,5,"6100001,20;3,5",80})
?C(401012, {c_achievement,401012,"雷劫套装（七）",4,440104,7,5,"6100001,30;3,5",90})
?C(401013, {c_achievement,401013,"雷劫套装（八）",4,440104,8,5,"6100001,30;3,5",100})
?C(401014, {c_achievement,401014,"雷劫套装（九）",4,440104,9,5,"6100001,50;3,5",110})
?C(401015, {c_achievement,401015,"雷劫套装（十）",4,440104,10,5,"6100001,50;3,5",120})
?C(401016, {c_achievement,401016,"雷霆套装（一）",4,440105,1,5,"6100001,10;3,10",50})
?C(401017, {c_achievement,401017,"雷霆套装（二）",4,440105,2,5,"6100001,20;3,10",60})
?C(401018, {c_achievement,401018,"雷霆套装（三）",4,440105,3,5,"6100001,30;3,10",70})
?C(401019, {c_achievement,401019,"雷霆套装（四）",4,440105,4,5,"6100001,40;3,10",80})
?C(401020, {c_achievement,401020,"雷霆套装（五）",4,440105,5,5,"6100001,50;3,10",90})
?C(401021, {c_achievement,401021,"阳炎套装（一）",4,440106,1,5,"6100002,10;3,20",100})
?C(401022, {c_achievement,401022,"阳炎套装（二）",4,440106,2,5,"6100002,10;3,20",120})
?C(401023, {c_achievement,401023,"阳炎套装（三）",4,440106,3,5,"6100002,10;3,20",140})
?C(401024, {c_achievement,401024,"阳炎套装（四）",4,440106,4,5,"6100002,10;3,20",160})
?C(401025, {c_achievement,401025,"阳炎套装（五）",4,440106,5,5,"6100002,10;3,20",180})
?C(401026, {c_achievement,401026,"阳元套装（一）",4,440107,1,5,"6100002,20;3,50",120})
?C(401027, {c_achievement,401027,"阳元套装（二）",4,440107,2,5,"6100002,20;3,50",140})
?C(401028, {c_achievement,401028,"阳元套装（三）",4,440107,3,5,"6100002,20;3,50",160})
?C(401029, {c_achievement,401029,"阳元套装（四）",4,440107,4,5,"6100002,20;3,50",180})
?C(401030, {c_achievement,401030,"阳元套装（五）",4,440107,5,5,"6100002,20;3,50",200})
?C(501001, {c_achievement,501001,"斩妖除魔（一）",5,550101,0,10000,"30402,3;3,5",70})
?C(501002, {c_achievement,501002,"斩妖除魔（二）",5,550101,0,50000,"30402,3;3,5",70})
?C(501003, {c_achievement,501003,"斩妖除魔（三）",5,550101,0,100000,"30402,3;3,5",70})
?C(501004, {c_achievement,501004,"斩妖除魔（四）",5,550101,0,150000,"30402,3;3,5",70})
?C(501005, {c_achievement,501005,"斩妖除魔（五）",5,550101,0,200000,"220031,1",80})
?C(501006, {c_achievement,501006,"斩妖除魔（六）",5,550101,0,270000,"30402,3;3,10",80})
?C(501007, {c_achievement,501007,"斩妖除魔（七）",5,550101,0,350000,"30402,3;3,10",80})
?C(501008, {c_achievement,501008,"斩妖除魔（八）",5,550101,0,450000,"30402,3;3,10",80})
?C(501009, {c_achievement,501009,"斩妖除魔（九）",5,550101,0,550000,"220032,1",80})
?C(501010, {c_achievement,501010,"斩妖除魔（十）",5,550101,0,1000000,"30402,3;3,10",100})
?C(501011, {c_achievement,501011,"斩妖除魔（十一）",5,550101,0,2000000,"30402,3;3,10",100})
?C(501012, {c_achievement,501012,"斩妖除魔（十二）",5,550101,0,4000000,"30402,3;3,10",100})
?C(501013, {c_achievement,501013,"斩妖除魔（十三）",5,550101,0,6000000,"30402,3;3,10",100})
?C(501014, {c_achievement,501014,"斩妖除魔（十四）",5,550101,0,8000000,"30402,3;3,10",120})
?C(501015, {c_achievement,501015,"斩妖除魔（十五）",5,550101,0,10000000,"220033,1",120})
?C(501016, {c_achievement,501016,"斩妖除魔（十六）",5,550101,0,13000000,"30402,3;3,10",120})
?C(501017, {c_achievement,501017,"斩妖除魔（十七）",5,550101,0,16000000,"30402,3;3,10",120})
?C(501018, {c_achievement,501018,"屠魔证道",5,550101,0,20000000,"30402,3;3,10",140})
?C(501019, {c_achievement,501019,"口若悬河（一）",5,550201,0,5,"1,200000;3,5",60})
?C(501020, {c_achievement,501020,"口若悬河（二）",5,550201,0,10,"1,200000;3,5",60})
?C(501021, {c_achievement,501021,"口若悬河（三）",5,550201,0,20,"220029,1",60})
?C(501022, {c_achievement,501022,"口若悬河（四）",5,550201,0,30,"1,200000;3,10",80})
?C(501023, {c_achievement,501023,"口若悬河（五）",5,550201,0,50,"1,200000;3,10",80})
?C(501024, {c_achievement,501024,"口若悬河（六）",5,550201,0,70,"1,200000;3,10",80})
?C(501025, {c_achievement,501025,"口若悬河（七）",5,550201,0,100,"1,200000;3,10",80})
?C(501026, {c_achievement,501026,"口若悬河（八）",5,550201,0,140,"1,200000;3,10",90})
?C(501027, {c_achievement,501027,"口若悬河（九）",5,550201,0,180,"1,200000;3,10",90})
?C(501028, {c_achievement,501028,"口若悬河（十）",5,550201,0,240,"1,200000;3,10",90})
?C(501029, {c_achievement,501029,"口若悬河（十一）",5,550201,0,320,"1,200000;3,10",90})
?C(501030, {c_achievement,501030,"口若悬河（十二）",5,550201,0,500,"1,200000;3,10",110})
?C(501031, {c_achievement,501031,"口若悬河（十三）",5,550201,0,700,"1,200000;3,10",110})
?C(501032, {c_achievement,501032,"口若悬河（十四）",5,550201,0,1000,"1,200000;3,10",110})
?C(501033, {c_achievement,501033,"天道酬勤（一）",5,550202,0,5,"1,200000;3,5",40})
?C(501034, {c_achievement,501034,"天道酬勤（二）",5,550202,0,10,"1,200000;3,10",50})
?C(501035, {c_achievement,501035,"天道酬勤（三）",5,550202,0,20,"1,200000;3,10",60})
?C(501036, {c_achievement,501036,"天道酬勤（四）",5,550202,0,30,"1,200000;3,10",70})
?C(501037, {c_achievement,501037,"天道酬勤（五）",5,550202,0,50,"1,200000;3,10",80})
?C(501038, {c_achievement,501038,"天道酬勤（六）",5,550202,0,100,"1,200000;3,10",90})
?C(501039, {c_achievement,501039,"天道酬勤（七）",5,550202,0,300,"1,200000;3,15",100})
?C(501040, {c_achievement,501040,"天道酬勤（八）",5,550202,0,500,"1,200000;3,15",110})
?C(501041, {c_achievement,501041,"问鼎三界（一）",5,550301,0,10,"30402,5;3,5",50})
?C(501042, {c_achievement,501042,"问鼎三界（二）",5,550301,0,30,"30402,5;3,10",60})
?C(501043, {c_achievement,501043,"问鼎三界（三）",5,550301,0,50,"30402,5;3,10",70})
?C(501044, {c_achievement,501044,"问鼎三界（四）",5,550301,0,100,"30402,5;3,15",80})
?C(501045, {c_achievement,501045,"问鼎三界（五）",5,550301,0,200,"30402,5;3,15",90})
?C(501046, {c_achievement,501046,"问鼎三界（六）",5,550301,0,500,"30402,5;3,20",100})
?C(501047, {c_achievement,501047,"问鼎三界（七）",5,550301,0,1000,"30402,5;3,20",110})
?C(501048, {c_achievement,501048,"勇冠三军（一）",5,550302,0,10,"30402,5;3,5",50})
?C(501049, {c_achievement,501049,"勇冠三军（二）",5,550302,0,30,"30402,5;3,10",60})
?C(501050, {c_achievement,501050,"勇冠三军（三）",5,550302,0,50,"30402,5;3,10",70})
?C(501051, {c_achievement,501051,"勇冠三军（四）",5,550302,0,100,"30402,5;3,15",80})
?C(501052, {c_achievement,501052,"勇冠三军（五）",5,550302,0,200,"30402,5;3,15",90})
?C(501053, {c_achievement,501053,"勇冠三军（六）",5,550302,0,500,"30402,5;3,20",100})
?C(501054, {c_achievement,501054,"勇冠三军（七）",5,550302,0,1000,"30402,5;3,20",110})
?C(501055, {c_achievement,501055,"连战连捷（一）",5,550303,0,1,"30402,5;3,5",20})
?C(501056, {c_achievement,501056,"连战连捷（二）",5,550303,0,3,"30402,5;3,10",40})
?C(501057, {c_achievement,501057,"连战连捷（三）",5,550303,0,5,"30402,5;3,10",60})
?C(501058, {c_achievement,501058,"连战连捷（四）",5,550303,0,7,"30402,5;3,15",80})
?C(501059, {c_achievement,501059,"连战连捷（五）",5,550303,0,8,"30402,5;3,15",100})
?C(501060, {c_achievement,501060,"连战连捷（六）",5,550303,0,9,"30402,5;3,20",120})
?C(501061, {c_achievement,501061,"连战连捷（七）",5,550303,0,10,"30402,5;3,20",140})
?C(501062, {c_achievement,501062,"护花使者（一）",5,550304,0,3,"1,200000;3,5",40})
?C(501063, {c_achievement,501063,"护花使者（二）",5,550304,0,10,"1,200000;3,10",50})
?C(501064, {c_achievement,501064,"护花使者（三）",5,550304,0,18,"220041,1;3,10",60})
?C(501065, {c_achievement,501065,"护花使者（四）",5,550304,0,50,"1,200000;3,15",70})
?C(501066, {c_achievement,501066,"护花使者（五）",5,550304,0,100,"1,200000;3,15",80})
?C(501067, {c_achievement,501067,"护花使者（六）",5,550304,0,200,"1,200000;3,20",90})
?C(501068, {c_achievement,501068,"护花使者（七）",5,550304,0,500,"1,200000;3,20",100})
?C(501069, {c_achievement,501069,"满腹经纶（一）",5,550305,0,10,"30402,3;3,5",40})
?C(501070, {c_achievement,501070,"满腹经纶（二）",5,550305,0,30,"30402,3;3,10",50})
?C(501071, {c_achievement,501071,"满腹经纶（三）",5,550305,0,50,"30402,3;3,10",60})
?C(501072, {c_achievement,501072,"满腹经纶（四）",5,550305,0,100,"30402,3;3,15",70})
?C(501073, {c_achievement,501073,"满腹经纶（五）",5,550305,0,200,"30402,3;3,15",80})
?C(501074, {c_achievement,501074,"满腹经纶（六）",5,550305,0,500,"30402,3;3,20",90})
?C(501075, {c_achievement,501075,"满腹经纶（七）",5,550305,0,1000,"220030,1",100})
?C(501076, {c_achievement,501076,"财运亨通（一）",5,550401,20101,1,"1,200000;3,5",40})
?C(501077, {c_achievement,501077,"财运亨通（二）",5,550401,20102,1,"1,200000;3,10",50})
?C(501078, {c_achievement,501078,"财运亨通（三）",5,550401,20103,1,"1,200000;3,10",60})
?C(501079, {c_achievement,501079,"财运亨通（四）",5,550401,20104,1,"1,200000;3,15",70})
?C(501080, {c_achievement,501080,"财运亨通（五）",5,550401,20105,1,"1,200000;3,15",80})
?C(501081, {c_achievement,501081,"遗迹护法（一）",5,550401,20301,1,"30402,3;3,5",40})
?C(501082, {c_achievement,501082,"遗迹护法（二）",5,550401,20302,1,"30402,5;3,10",50})
?C(501083, {c_achievement,501083,"遗迹护法（三）",5,550401,20303,1,"30402,5;3,10",60})
?C(501084, {c_achievement,501084,"遗迹护法（四）",5,550401,20304,1,"30402,5;3,15",70})
?C(501085, {c_achievement,501085,"遗迹护法（五）",5,550401,20305,1,"30402,5;3,15",80})
?C(501086, {c_achievement,501086,"一鼓作气（一）",5,550402,0,10,"30402,5;3,5",60})
?C(501087, {c_achievement,501087,"一鼓作气（二）",5,550402,0,30,"30402,5;3,5",60})
?C(501088, {c_achievement,501088,"一鼓作气（三）",5,550402,0,50,"30402,5;3,5",60})
?C(501089, {c_achievement,501089,"一鼓作气（四）",5,550402,0,80,"30402,5;3,10",80})
?C(501090, {c_achievement,501090,"一鼓作气（五）",5,550402,0,100,"30402,5;3,10",80})
?C(501091, {c_achievement,501091,"一鼓作气（六）",5,550402,0,140,"30402,5;3,10",80})
?C(501092, {c_achievement,501092,"一鼓作气（七）",5,550402,0,180,"30402,5;3,10",80})
?C(501093, {c_achievement,501093,"一鼓作气（八）",5,550402,0,210,"30402,5;3,10",90})
?C(501094, {c_achievement,501094,"一鼓作气（九）",5,550402,0,240,"30402,5;3,10",90})
?C(501095, {c_achievement,501095,"一鼓作气（十）",5,550402,0,300,"30402,5;3,10",90})
?C(501096, {c_achievement,501096,"一鼓作气（十一）",5,550402,0,450,"30402,5;3,10",110})
?C(501097, {c_achievement,501097,"一鼓作气（十二）",5,550402,0,600,"30402,5;3,10",110})
?C(501098, {c_achievement,501098,"一鼓作气（十三）",5,550402,0,900,"30402,5;3,10",110})
?C(501099, {c_achievement,501099,"一鼓作气（十四）",5,550402,0,1200,"30402,5;3,10",110})
?C(501100, {c_achievement,501100,"一鼓作气（十五）",5,550402,0,1500,"30402,5;3,10",110})
?C(501101, {c_achievement,501101,"一鼓作气（十六）",5,550402,0,2000,"30402,5;3,10",130})
?C(501102, {c_achievement,501102,"一鼓作气（十七）",5,550402,0,2500,"30402,5;3,10",130})
?C(501103, {c_achievement,501103,"兢兢业业（一）",5,550501,0,50,"30402,3;3,5",70})
?C(501104, {c_achievement,501104,"兢兢业业（二）",5,550501,0,100,"30402,3;3,5",70})
?C(501105, {c_achievement,501105,"兢兢业业（三）",5,550501,0,150,"30402,3;3,5",80})
?C(501106, {c_achievement,501106,"兢兢业业（四）",5,550501,0,200,"30402,3;3,5",80})
?C(501107, {c_achievement,501107,"兢兢业业（五）",5,550501,0,250,"30402,3;3,10",80})
?C(501108, {c_achievement,501108,"兢兢业业（六）",5,550501,0,300,"30402,3;3,10",90})
?C(501109, {c_achievement,501109,"兢兢业业（七）",5,550501,0,350,"220035,1",90})
?C(501110, {c_achievement,501110,"兢兢业业（八）",5,550501,0,400,"30402,3;3,10",90})
?C(501111, {c_achievement,501111,"兢兢业业（九）",5,550501,0,450,"30402,3;3,10",100})
?C(501112, {c_achievement,501112,"兢兢业业（十）",5,550501,0,500,"220036,1",100})
?C(501113, {c_achievement,501113,"兢兢业业（十一）",5,550501,0,700,"30402,3;3,10",100})
?C(501114, {c_achievement,501114,"兢兢业业（十二）",5,550501,0,1000,"30402,3;3,10",120})
?C(501115, {c_achievement,501115,"兢兢业业（十三）",5,550501,0,1500,"30402,3;3,10",120})
?C(501116, {c_achievement,501116,"道庭独尊",5,550501,0,2000,"30402,3;3,10",140})
?C(601001, {c_achievement,601001,"谁与争锋（一）",6,660101,0,1,"1,1000000;3,5",30})
?C(601002, {c_achievement,601002,"谁与争锋（二）",6,660101,0,4,"1,1200000;3,10",50})
?C(601003, {c_achievement,601003,"谁与争锋（三）",6,660101,0,8,"1,1400000;3,15",70})
?C(601004, {c_achievement,601004,"谁与争锋（四）",6,660101,0,12,"1,1600000;3,20",90})
?C(601005, {c_achievement,601005,"谁与争锋（五）",6,660101,0,15,"1,1800000;3,25",110})
?C(601006, {c_achievement,601006,"独霸天下（一）",6,660102,0,1,"1,1000000;3,10",40})
?C(601007, {c_achievement,601007,"独霸天下（二）",6,660102,0,3,"1,1200000;3,15",60})
?C(601008, {c_achievement,601008,"独霸天下（三）",6,660102,0,5,"1,1400000;3,20",80})
?C(601009, {c_achievement,601009,"独霸天下（四）",6,660102,0,8,"1,1600000;3,25",100})
?C(601010, {c_achievement,601010,"独霸天下（五）",6,660102,0,12,"1,1800000;3,30",120})
?C(601011, {c_achievement,601011,"致命一击",6,660103,0,1,"1,1000000;3,15",50})
?C(601012, {c_achievement,601012,"参加道庭",6,660104,0,1,"1,200000;3,15",40})
?C(601013, {c_achievement,601013,"猪圆玉润（一）",6,660105,0,1,"1,200000;3,5",10})
?C(601014, {c_achievement,601014,"猪圆玉润（二）",6,660105,0,6,"1,200000;3,5",10})
?C(601015, {c_achievement,601015,"猪圆玉润（三）",6,660105,0,8,"220038,1",20})
?C(601016, {c_achievement,601016,"猪圆玉润（四）",6,660105,0,15,"1,200000;3,5",30})
?C(601017, {c_achievement,601017,"猪圆玉润（五）",6,660105,0,30,"1,200000;3,10",40})
?C(601018, {c_achievement,601018,"猪圆玉润（六）",6,660105,0,50,"1,200000;3,10",50})
?C(601019, {c_achievement,601019,"猪圆玉润（七）",6,660105,0,80,"1,200000;3,10",60})
?C(601020, {c_achievement,601020,"猪圆玉润（八）",6,660105,0,120,"1,200000;3,10",70})
?C(601021, {c_achievement,601021,"猪圆玉润（九）",6,660105,0,200,"1,200000;3,10",80})
?C(601022, {c_achievement,601022,"学富五车（一）",6,660106,0,100,"1,200000;3,5",40})
?C(601023, {c_achievement,601023,"学富五车（二）",6,660106,0,150,"1,200000;3,10",50})
?C(601024, {c_achievement,601024,"学富五车（三）",6,660106,0,200,"1,200000;3,10",60})
?C(601025, {c_achievement,601025,"学富五车（四）",6,660106,0,260,"220034,1",70})
?C(601026, {c_achievement,601026,"学富五车（五）",6,660106,0,350,"1,200000;3,15",80})
?C(601027, {c_achievement,601027,"学富五车（六）",6,660106,0,500,"1,200000;3,20",90})
?C(601028, {c_achievement,601028,"学富五车（七）",6,660106,0,1000,"1,3000000;3,25",100})
?C(601029, {c_achievement,601029,"一掷千金（一）",6,660107,0,1,"1,200000;3,5",20})
?C(601030, {c_achievement,601030,"一掷千金（二）",6,660107,0,10,"1,200000;3,10",30})
?C(601031, {c_achievement,601031,"一掷千金（三）",6,660107,0,50,"1,200000;3,15",50})
?C(601032, {c_achievement,601032,"一掷千金（四）",6,660107,0,100,"220037,1",80})
?C(601033, {c_achievement,601033,"一掷千金（五）",6,660107,0,500,"1,200000;3,25",100})
?C(601034, {c_achievement,601034,"替天行道",6,660201,0,1,"1,300000;3,25",50})
?C(601035, {c_achievement,601035,"第一滴血",6,660202,0,1,"1,300000;3,10",50})
?C(601036, {c_achievement,601036,"纳尼！？",6,660203,0,1,"1,200000;3,5",40})
?C(701001, {c_achievement,701001,"第一桶金",7,770101,0,10000000,"1,200000;3,5",70})
?C(701002, {c_achievement,701002,"积少成多",7,770101,0,50000000,"1,200000;3,5",70})
?C(701003, {c_achievement,701003,"勤俭持家",7,770101,0,100000000,"1,200000;3,5",70})
?C(701004, {c_achievement,701004,"一个小目标",7,770101,0,200000000,"220039,1",80})
?C(701005, {c_achievement,701005,"掘金者",7,770101,0,300000000,"1,200000;3,10",80})
?C(701006, {c_achievement,701006,"彩票头奖",7,770101,0,400000000,"1,200000;3,10",80})
?C(701007, {c_achievement,701007,"亿万富翁",7,770101,0,500000000,"1,200000;3,10",100})
?C(701008, {c_achievement,701008,"闪亮亮",7,770101,0,700000000,"1,200000;3,10",100})
?C(701009, {c_achievement,701009,"响叮当",7,770101,0,1000000000,"1,200000;3,10",100})
?C(701010, {c_achievement,701010,"福布斯新秀",7,770101,0,1500000000,"1,200000;3,10",110})
?C(701011, {c_achievement,701011,"首富还差一点点",7,770101,0,2000000000,"1,200000;3,10",110})
?C(701012, {c_achievement,701012,"有钱就是任性",7,770101,0,3000000000,"1,200000;3,10",110})
?C(701013, {c_achievement,701013,"大目标达成",7,770101,0,4000000000,"220040,1",120})
?C(701014, {c_achievement,701014,"打卡成功",7,770201,0,1,"30402,5;3,5",70})
?C(701015, {c_achievement,701015,"登陆就点",7,770201,0,3,"30402,5;3,5",70})
?C(701016, {c_achievement,701016,"再点点",7,770201,0,5,"30402,5;3,10",80})
?C(701017, {c_achievement,701017,"签到送豪礼哟",7,770201,0,7,"30402,5;3,10",80})
?C(701018, {c_achievement,701018,"别挡我的签到路",7,770201,0,10,"30402,5;3,10",80})
?C(701019, {c_achievement,701019,"滴！学生卡",7,770201,0,15,"30402,5;3,10",90})
?C(701020, {c_achievement,701020,"滴！老玩家卡",7,770201,0,20,"30402,5;3,10",90})
?C(701021, {c_achievement,701021,"滴！老司机卡",7,770201,0,30,"30402,5;3,10",90})
?C(701022, {c_achievement,701022,"新的打卡姿势！",7,770201,0,50,"30402,5;3,10",100})
?C(701023, {c_achievement,701023,"打卡姿势很特别",7,770201,0,80,"30402,5;3,10",100})
?C(701024, {c_achievement,701024,"解锁所有打卡姿势",7,770201,0,120,"30402,5;3,10",100})
?C(701025, {c_achievement,701025,"根本停不下来",7,770201,0,180,"30402,5;3,10",120})
?C(701026, {c_achievement,701026,"到处是我的指纹",7,770201,0,250,"30402,5;3,10",120})
?C(701027, {c_achievement,701027,"全勤奖",7,770201,0,365,"30402,5;3,10",120})
?C(701028, {c_achievement,701028,"东西放不下",7,770301,0,5,"30402,3;3,10",40})
?C(701029, {c_achievement,701029,"口袋很深",7,770301,0,10,"30402,3;3,10",60})
?C(701030, {c_achievement,701030,"来者不拒",7,770301,0,20,"30402,3;3,10",80})
?C(701031, {c_achievement,701031,"全部拿来",7,770301,0,30,"30402,3;3,10",90})
?C(701032, {c_achievement,701032,"驴牌包包",7,770301,0,50,"30402,3;3,10",110})
?C(701033, {c_achievement,701033,"二次元口袋",7,770301,0,100,"30402,3;3,10",130})
?C(701034, {c_achievement,701034,"私藏丰厚",7,770302,0,5,"30402,3;3,10",40})
?C(701035, {c_achievement,701035,"小型仓库",7,770302,0,10,"30402,3;3,15",60})
?C(701036, {c_achievement,701036,"中型仓库",7,770302,0,20,"30402,3;3,20",80})
?C(701037, {c_achievement,701037,"大型仓库",7,770302,0,30,"30402,3;3,25",90})
?C(701038, {c_achievement,701038,"银行保险柜",7,770302,0,40,"30402,3;3,30",110})
?CFG_E.