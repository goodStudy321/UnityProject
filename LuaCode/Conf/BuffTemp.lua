--******************************************************************************
-- Copyright(C) Phantom CO,.LTD. All rights reserved
-- Created by Loong's tool. Please do not edit it.
-- proto:B_Buff配置表.xml, excel:B Buff配置表.xls, sheet:Sheet1
--******************************************************************************
BuffTemp={}
local We=BuffTemp
We["101001"]={id=101001, name="眩晕", des="", path="buff_yunxuan.jpg", time=5}
We["101002"]={id=101002, name="眩晕", des="1.5秒眩晕（角色4技能附带效果）", path="buff_yunxuan.jpg", time=2}
We["101003"]={id=101003, name="眩晕", des="2秒眩晕（仙魂副本技能2效果）", path="buff_yunxuan.jpg", time=2}
We["102001"]={id=102001, name="定身", des="无法移动", path="buff_dingshen.jpg", time=5}
We["102002"]={id=102002, name="定身", des="1v1场景无法移动", path="buff_dingshen.jpg", time=60}
We["103001"]={id=103001, name="沉默", des="无法施放技能", path="buff_chenmo.jpg", time=5}
We["104001"]={id=104001, name="缴械", des="无法施放普攻", path="buff_chenmo.jpg", time=5}
We["105001"]={id=105001, name="减速", des="移动速度降低", path="buff_jiansu.jpg", valueList={{k=43, v=-100}}, time=5}
We["105002"]={id=105002, name="被动技能减速", des="移动速度降低10%", path="buff_jiansu.jpg", valueList={{k=43, v=-1000}}, time=3}
We["106001"]={id=106001, name="攻击加成", des="加攻击", path="buff_gongji.jpg", valueList={{k=2, v=1000}}, time=15}
We["107001"]={id=107001, name="中毒降血", des="中毒扣血", path="buff_zhongdu.jpg", valueList={{k=1000, v=0}}, time=15}
We["108001"]={id=108001, name="生命回复", des="加血", path="buff_huixue.jpg", valueList={{k=1000, v=0}}, time=15}
We["108002"]={id=108002, name="生命回复", des="加血", path="buff_huixue.jpg", valueList={{k=500, v=0}}, time=1}
We["108003"]={id=108003, name="被动技能【生命恢复】", des="每10s回复5%生命值", path="buff_huixue.jpg", valueList={{k=500, v=0}}, time=1}
We["109001"]={id=109001, name="被动技能【金刚诀】", des="金刚决buff加减伤", path="buff_gongji.jpg", valueList={{k=12, v=2000}}, time=15}
We["110001"]={id=110001, name="被动技能【伤害加深】", des="增加20%人物技能伤害", path="buff_gongji.jpg", valueList={{k=16, v=2000}}, time=10}
We["111001"]={id=111001, name="被动技能【攻击光环】", des="增加友方10%伤害（队伍）", path="buff_gongji.jpg", valueList={{k=11, v=1000}}, time=0}
We["112001"]={id=112001, name="被动技能【清心】", des="每隔40秒可以解除一次自己身上的异常状态", path="buff_gongji.jpg", time=0}
We["113001"]={id=113001, name="冰冻", des="冰冻3秒", path="buff_bingdong.jpg", time=3}
We["114001"]={id=114001, name="缠绕", des="缠绕3秒", path="buff_yunxuan.jpg", time=3}
We["115001"]={id=115001, name="无敌", des="免疫一切伤害", path="buff_wudi.jpg", time=2}
We["116001"]={id=116001, name="控制解除", des="解除控制", path="buff_yunxuan.jpg", time=1}
We["117001"]={id=117001, name="生命回复", des="加血", path="buff_huixue.jpg", valueList={{k=2000, v=0}}, time=1}
We["118001"]={id=118001, name="控制解除", des="解除控制", path="buff_yunxuan.jpg", time=1}
We["119001"]={id=119001, name="免疫", des="免疫", path="buff_yunxuan.jpg", time=2}
We["120001"]={id=120001, name="PVP减伤", des="增加25%PVP减伤", path="buff_gongji.jpg", valueList={{k=49, v=2500}}, time=15}
We["121001"]={id=121001, name="压迫", des="对定身造成额外伤害", path="buff_gongji.jpg", valueList={{k=56, v=10000}}, time=4}
We["122001"]={id=122001, name="减速", des="仙魂减少移速", path="buff_jiansu.jpg", valueList={{k=27, v=-100}}, time=5}
We["123001"]={id=123001, name="生命回复", des="", path="buff_huixue.jpg", valueList={{k=300, v=0}}, time=1}
We["124001"]={id=124001, name="控制解除", des="解除控制", path="buff_yunxuan.jpg", time=1}
We["125001"]={id=125001, name="PVP减伤", des="PVP受到伤害降低", path="buff_wudi.jpg", valueList={{k=49, v=2200}}, time=10}
We["125002"]={id=125002, name="PVP减伤", des="PVP受到伤害降低", path="buff_wudi.jpg", valueList={{k=49, v=2400}}, time=10}
We["125003"]={id=125003, name="PVP减伤", des="PVP受到伤害降低", path="buff_wudi.jpg", valueList={{k=49, v=2600}}, time=10}
We["125004"]={id=125004, name="PVP减伤", des="PVP受到伤害降低", path="buff_wudi.jpg", valueList={{k=49, v=2800}}, time=10}
We["125005"]={id=125005, name="PVP减伤", des="PVP受到伤害降低", path="buff_wudi.jpg", valueList={{k=49, v=3000}}, time=10}
We["125006"]={id=125006, name="PVP减伤", des="PVP受到伤害降低", path="buff_wudi.jpg", valueList={{k=49, v=3200}}, time=10}
We["125007"]={id=125007, name="PVP减伤", des="PVP受到伤害降低", path="buff_wudi.jpg", valueList={{k=49, v=3400}}, time=10}
We["125008"]={id=125008, name="PVP减伤", des="PVP受到伤害降低", path="buff_wudi.jpg", valueList={{k=49, v=3600}}, time=10}
We["125009"]={id=125009, name="PVP减伤", des="PVP受到伤害降低", path="buff_wudi.jpg", valueList={{k=49, v=3800}}, time=10}
We["125010"]={id=125010, name="PVP减伤", des="PVP受到伤害降低", path="buff_wudi.jpg", valueList={{k=49, v=4000}}, time=10}
We["126001"]={id=126001, name="生命回复", des="生命回复", path="buff_huixue.jpg", valueList={{k=1000, v=0}}, time=5}
We["126002"]={id=126002, name="生命回复", des="生命回复", path="buff_huixue.jpg", valueList={{k=1000, v=0}}, time=5}
We["126003"]={id=126003, name="生命回复", des="生命回复", path="buff_huixue.jpg", valueList={{k=1000, v=0}}, time=5}
We["126004"]={id=126004, name="生命回复", des="生命回复", path="buff_huixue.jpg", valueList={{k=1000, v=0}}, time=5}
We["126005"]={id=126005, name="生命回复", des="生命回复", path="buff_huixue.jpg", valueList={{k=1000, v=0}}, time=5}
We["126006"]={id=126006, name="生命回复", des="生命回复", path="buff_huixue.jpg", valueList={{k=1000, v=0}}, time=5}
We["126007"]={id=126007, name="生命回复", des="生命回复", path="buff_huixue.jpg", valueList={{k=1000, v=0}}, time=5}
We["126008"]={id=126008, name="生命回复", des="生命回复", path="buff_huixue.jpg", valueList={{k=1000, v=0}}, time=5}
We["126009"]={id=126009, name="生命回复", des="生命回复", path="buff_huixue.jpg", valueList={{k=1000, v=0}}, time=5}
We["126010"]={id=126010, name="生命回复", des="生命回复", path="buff_huixue.jpg", valueList={{k=1000, v=0}}, time=5}
We["127001"]={id=127001, name="攻击加成", des="加攻击", path="buff_gongji.jpg", valueList={{k=2, v=1200}}, time=5}
We["127002"]={id=127002, name="攻击加成", des="加攻击", path="buff_gongji.jpg", valueList={{k=2, v=1400}}, time=5}
We["127003"]={id=127003, name="攻击加成", des="加攻击", path="buff_gongji.jpg", valueList={{k=2, v=1600}}, time=5}
We["127004"]={id=127004, name="攻击加成", des="加攻击", path="buff_gongji.jpg", valueList={{k=2, v=1800}}, time=5}
We["127005"]={id=127005, name="攻击加成", des="加攻击", path="buff_gongji.jpg", valueList={{k=2, v=2000}}, time=5}
We["127006"]={id=127006, name="攻击加成", des="加攻击", path="buff_gongji.jpg", valueList={{k=2, v=2200}}, time=5}
We["127007"]={id=127007, name="攻击加成", des="加攻击", path="buff_gongji.jpg", valueList={{k=2, v=2400}}, time=5}
We["127008"]={id=127008, name="攻击加成", des="加攻击", path="buff_gongji.jpg", valueList={{k=2, v=2600}}, time=5}
We["127009"]={id=127009, name="攻击加成", des="加攻击", path="buff_gongji.jpg", valueList={{k=2, v=2800}}, time=5}
We["127010"]={id=127010, name="攻击加成", des="加攻击", path="buff_gongji.jpg", valueList={{k=2, v=3000}}, time=5}
We["128001"]={id=128001, name="攻击加成6%", des="加攻击", path="buff_gongji.jpg", valueList={{k=19, v=600}}, time=5}
We["128002"]={id=128002, name="攻击加成7%", des="加攻击", path="buff_gongji.jpg", valueList={{k=19, v=700}}, time=5}
We["128003"]={id=128003, name="攻击加成8%", des="加攻击", path="buff_gongji.jpg", valueList={{k=19, v=800}}, time=5}
We["128004"]={id=128004, name="攻击加成9%", des="加攻击", path="buff_gongji.jpg", valueList={{k=19, v=900}}, time=5}
We["128005"]={id=128005, name="攻击加成10%", des="加攻击", path="buff_gongji.jpg", valueList={{k=19, v=1000}}, time=5}
We["129001"]={id=129001, name="免伤50%", des="魔域场景PVP受到伤害降低", path="buff_wudi.jpg", valueList={{k=49, v=5000}}, time=1200}
We["201001"]={id=201001, name="加伤害", des="加伤害", path="buff_gongji.jpg", valueList={{k=11, v=1000}}, time=1800}
We["201002"]={id=201002, name="攻击加成10%", des="加攻击", path="buff_gongji.jpg", valueList={{k=19, v=1000}}, time=5}
We["201003"]={id=201003, name="攻击加成10%", des="[法宝]攻击玩家时，25%概率提高10%攻击力", path="buff_gongji.jpg", valueList={{k=19, v=1000}}, time=5}
We["201004"]={id=201004, name="攻击加成10%", des="[法宝]目标血量低于20%时候，提高10%的攻击力", path="buff_gongji.jpg", valueList={{k=19, v=1000}}, time=5}
We["201005"]={id=201005, name="攻击加成20%", des="[法宝]角色血量低于20%时候，提高20%的攻击力", path="buff_gongji.jpg", valueList={{k=19, v=1000}}, time=5}
We["202001"]={id=202001, name="挂机加移速", des="加移速", path="buff_yisu.jpg", valueList={{k=27, v=280}}, time=0}
We["202002"]={id=202002, name="道庭大战", des="加移速", path="buff_yisu.jpg", valueList={{k=27, v=150}}, time=0}
We["203001"]={id=203001, name="疲劳", des="无法攻击怪物", path="buff_pilao.jpg", time=0}
We["204001"]={id=204001, name="打怪经验加成", des="打怪经验加成", path="buff_jingyan.jpg", valueList={{k=26, v=10000}}, time=3600}
We["204002"]={id=204002, name="打怪经验加成", des="打怪经验加成", path="buff_jingyan.jpg", valueList={{k=26, v=5000}}, time=3600}
We["204003"]={id=204003, name="打怪经验加成", des="打怪经验加成", path="buff_jingyan.jpg", valueList={{k=26, v=10000}}, time=3600}
We["204004"]={id=204004, name="打怪经验加成", des="打怪经验加成", path="buff_jingyan.jpg", valueList={{k=26, v=20000}}, time=3600}
We["205001"]={id=205001, name="无敌", des="无敌", path="buff_wudi.jpg", time=30}
We["206001"]={id=206001, name="反伤", des="反伤", path="buff_wudi.jpg", valueList={{k=53, v=1000}}, time=600}
We["207001"]={id=207001, name="打怪经验加成", des="守卫仙盟地图打怪经验加成", path="buff_jingyan.jpg", valueList={{k=26, v=3000}}, time=1800}
We["208001"]={id=208001, name="攻击加成", des="仙魂副本特殊技能", path="buff_gongji.jpg", valueList={{k=19, v=2000}}, time=15}
We["208002"]={id=208002, name="攻击眩晕", des="仙魂副本特殊技能", path="buff_yunxuan.jpg", valueList={{k=58, v=5000}}, time=15}
We["209001"]={id=209001, name="攻击加成", des="仙侣副本甜蜜度Buff效果", path="buff_gongji.jpg", valueList={{k=19, v=2000}}, time=24}
We["210001"]={id=210001, name="道庭战连胜buff1", des="道庭战连胜buff1", path="buff_gongji.jpg", valueList={{k=18, v=1500}, {k=19, v=1500}, {k=20, v=1500}}, time=1000}
We["210002"]={id=210002, name="道庭战连胜buff2", des="道庭战连胜buff2", path="buff_gongji.jpg", valueList={{k=18, v=3000}, {k=19, v=3000}, {k=20, v=3000}}, time=1000}
We["210003"]={id=210003, name="道庭战连胜buff3", des="道庭战连胜buff3", path="buff_gongji.jpg", valueList={{k=18, v=4500}, {k=19, v=4500}, {k=20, v=4500}}, time=1000}
We["210004"]={id=210004, name="道庭战连胜buff4", des="道庭战连胜buff4", path="buff_gongji.jpg", valueList={{k=18, v=6000}, {k=19, v=6000}, {k=20, v=6000}}, time=1000}
We["210005"]={id=210005, name="道庭战连胜buff5", des="道庭战连胜buff5", path="buff_gongji.jpg", valueList={{k=18, v=7500}, {k=19, v=7500}, {k=20, v=7500}}, time=1000}
We["210006"]={id=210006, name="道庭战连胜buff6", des="道庭战连胜buff6", path="buff_gongji.jpg", valueList={{k=18, v=9000}, {k=19, v=9000}, {k=20, v=9000}}, time=1000}
We["210007"]={id=210007, name="道庭战连胜buff7", des="道庭战连胜buff7", path="buff_gongji.jpg", valueList={{k=18, v=10500}, {k=19, v=10500}, {k=20, v=10500}}, time=1000}
We["210008"]={id=210008, name="道庭战连胜buff8", des="道庭战连胜buff8", path="buff_gongji.jpg", valueList={{k=18, v=12000}, {k=19, v=12000}, {k=20, v=12000}}, time=1000}
We["210009"]={id=210009, name="道庭战连胜buff9", des="道庭战连胜buff9", path="buff_gongji.jpg", valueList={{k=18, v=13500}, {k=19, v=13500}, {k=20, v=13500}}, time=1000}
We["210010"]={id=210010, name="道庭战连胜buff10", des="道庭战连胜buff10", path="buff_gongji.jpg", valueList={{k=18, v=15000}, {k=19, v=15000}, {k=20, v=15000}}, time=1000}
We["210201"]={id=210201, name="主宰庭主buff", des="主宰庭主buff", path="buff_gongji.jpg", valueList={{k=18, v=200}, {k=19, v=200}, {k=20, v=200}}, time=1000}
We["210202"]={id=210202, name="主宰庭主buff", des="主宰庭主buff", path="buff_gongji.jpg", valueList={{k=18, v=100}, {k=19, v=100}, {k=20, v=100}}, time=1000}
We["210203"]={id=210203, name="主宰庭主buff", des="主宰庭主buff", path="buff_gongji.jpg", valueList={{k=18, v=100}, {k=19, v=100}, {k=20, v=100}}, time=1000}
We["210210"]={id=210210, name="复仇buff", des="魔域boss复仇buff", path="buff_gongji.jpg", valueList={{k=19, v=1000}}, time=1800}
We["210220"]={id=210220, name="占领buff", des="魔域占领者buff", path="buff_huixue.jpg", valueList={{k=18, v=5000}}, time=1800}
We["210221"]={id=210221, name="占领buff", des="魔域占领者buff", path="buff_huixue.jpg", valueList={{k=18, v=10000}}, time=1800}
We["210222"]={id=210222, name="占领buff", des="魔域占领者buff", path="buff_huixue.jpg", valueList={{k=18, v=15000}}, time=1800}
We["210223"]={id=210223, name="占领buff", des="魔域占领者buff", path="buff_huixue.jpg", valueList={{k=18, v=20000}}, time=1800}
We["210224"]={id=210224, name="占领buff", des="魔域占领者buff", path="buff_huixue.jpg", valueList={{k=18, v=22000}}, time=1800}
We["210225"]={id=210225, name="占领buff", des="魔域占领者buff", path="buff_huixue.jpg", valueList={{k=18, v=25000}}, time=1800}
We["210301"]={id=210301, name="助威buff", des="道庭神兽助威buff", path="buff_gongji.jpg", valueList={{k=19, v=500}}, time=1800}
We["210302"]={id=210302, name="助威buff", des="道庭神兽助威buff", path="buff_gongji.jpg", valueList={{k=19, v=1000}}, time=1800}
We["210303"]={id=210303, name="助威buff", des="道庭神兽助威buff", path="buff_gongji.jpg", valueList={{k=19, v=1500}}, time=1800}
We["210304"]={id=210304, name="助威buff", des="道庭神兽助威buff", path="buff_gongji.jpg", valueList={{k=19, v=2000}}, time=1800}
We["210305"]={id=210305, name="助威buff", des="道庭神兽助威buff", path="buff_gongji.jpg", valueList={{k=19, v=2500}}, time=1800}
We["210306"]={id=210306, name="助威buff", des="道庭神兽助威buff", path="buff_gongji.jpg", valueList={{k=19, v=3000}}, time=1800}
We["210307"]={id=210307, name="助威buff", des="道庭神兽助威buff", path="buff_gongji.jpg", valueList={{k=19, v=3500}}, time=1800}
We["210308"]={id=210308, name="助威buff", des="道庭神兽助威buff", path="buff_gongji.jpg", valueList={{k=19, v=4000}}, time=1800}
We["210309"]={id=210309, name="助威buff", des="道庭神兽助威buff", path="buff_gongji.jpg", valueList={{k=19, v=4500}}, time=1800}
We["210310"]={id=210310, name="助威buff", des="道庭神兽助威buff", path="buff_gongji.jpg", valueList={{k=19, v=5000}}, time=1800}
We["210311"]={id=210311, name="助威buff", des="道庭神兽助威buff", path="buff_gongji.jpg", valueList={{k=19, v=5500}}, time=1800}
We["210312"]={id=210312, name="助威buff", des="道庭神兽助威buff", path="buff_gongji.jpg", valueList={{k=19, v=6000}}, time=1800}
We["210313"]={id=210313, name="助威buff", des="道庭神兽助威buff", path="buff_gongji.jpg", valueList={{k=19, v=6500}}, time=1800}
We["210314"]={id=210314, name="助威buff", des="道庭神兽助威buff", path="buff_gongji.jpg", valueList={{k=19, v=7000}}, time=1800}
We["210315"]={id=210315, name="助威buff", des="道庭神兽助威buff", path="buff_gongji.jpg", valueList={{k=19, v=7500}}, time=1800}
We["210316"]={id=210316, name="助威buff", des="道庭神兽助威buff", path="buff_gongji.jpg", valueList={{k=19, v=8000}}, time=1800}
We["210317"]={id=210317, name="助威buff", des="道庭神兽助威buff", path="buff_gongji.jpg", valueList={{k=19, v=8500}}, time=1800}
We["210318"]={id=210318, name="助威buff", des="道庭神兽助威buff", path="buff_gongji.jpg", valueList={{k=19, v=9000}}, time=1800}
We["210319"]={id=210319, name="助威buff", des="道庭神兽助威buff", path="buff_gongji.jpg", valueList={{k=19, v=9500}}, time=1800}
We["210320"]={id=210320, name="助威buff", des="道庭神兽助威buff", path="buff_gongji.jpg", valueList={{k=19, v=10000}}, time=1800}
We["300001"]={id=300001, name="攻击加成", des="妖魔岭怪物攻击加成", path="buff_gongji.jpg", valueList={{k=19, v=10000}}, time=1800}
We["301001"]={id=301001, name="防御加成", des="妖魔岭怪物防御加成", path="buff_fangyu.jpg", valueList={{k=20, v=10000}}, time=1800}
We["302001"]={id=302001, name="生命回复", des="妖魔岭怪物回血", path="buff_huixue.jpg", valueList={{k=1000, v=0}}, time=15}
We["303001"]={id=303001, name="萍水相逢", des="好友buff加成", path="buff_gongji.jpg", valueList={{k=2, v=190}, {k=1, v=3800}, {k=26, v=100}}, time=0}
We["303002"]={id=303002, name="相见恨晚", des="好友buff加成", path="buff_gongji.jpg", valueList={{k=2, v=420}, {k=1, v=8400}, {k=26, v=200}}, time=0}
We["303003"]={id=303003, name="志同道合", des="好友buff加成", path="buff_gongji.jpg", valueList={{k=2, v=700}, {k=1, v=14000}, {k=26, v=300}}, time=0}
We["303004"]={id=303004, name="患难与共", des="好友buff加成", path="buff_gongji.jpg", valueList={{k=2, v=1030}, {k=1, v=20600}, {k=26, v=400}}, time=0}
We["303005"]={id=303005, name="义结金兰", des="好友buff加成", path="buff_gongji.jpg", valueList={{k=2, v=1430}, {k=1, v=28600}, {k=26, v=500}}, time=0}
We["303006"]={id=303006, name="情深似海", des="好友buff加成", path="buff_gongji.jpg", valueList={{k=2, v=1910}, {k=1, v=38200}, {k=26, v=600}}, time=0}
We["303007"]={id=303007, name="肝胆相照", des="好友buff加成", path="buff_gongji.jpg", valueList={{k=2, v=2485}, {k=1, v=49700}, {k=26, v=700}}, time=0}
We["303008"]={id=303008, name="亲密无间", des="好友buff加成", path="buff_gongji.jpg", valueList={{k=2, v=3175}, {k=1, v=63500}, {k=26, v=800}}, time=0}
We["303009"]={id=303009, name="心有灵心", des="好友buff加成", path="buff_gongji.jpg", valueList={{k=2, v=4005}, {k=1, v=80100}, {k=26, v=900}}, time=0}
We["303010"]={id=303010, name="心心相印", des="好友buff加成", path="buff_gongji.jpg", valueList={{k=2, v=5000}, {k=1, v=100000}, {k=26, v=1000}}, time=0}
We["304001"]={id=304001, name="护盾buff", des="护盾相关buff", path="buff_fangyu.jpg", valueList={{k=3000, v=0}}, time=15}
We["305001"]={id=305001, name="变猪buff", des="变身相关buff", path="buff_yunxuan.jpg", valueList={{k=9100, v=0}}, time=600}
We["400001"]={id=400001, name="致死豁免", des="致死伤害豁免", path="buff_wudi.jpg", time=1}
We["501001"]={id=501001, name="攻击加成", des="藏宝图加攻击", path="buff_gongji.jpg", valueList={{k=19, v=10000}}, time=1800}
We["502001"]={id=502001, name="加防御", des="藏宝图加防御", path="buff_fangyu.jpg", valueList={{k=20, v=10000}}, time=1800}
We["999990"]={id=999990, name="GM命令攻击加成", des="加攻击", path="buff_gongji.jpg", valueList={{k=2, v=10000000}}, time=0}
We["999991"]={id=999991, name="GM命令加移速", des="加移速", path="buff_yisu.jpg", valueList={{k=27, v=1000}}, time=0}
We["999992"]={id=999992, name="GM命令加各种攻击属性", des="加移速", path="buff_yisu.jpg", valueList={{k=2, v=100000000}, {k=7, v=100000}, {k=11, v=10000}, {k=16, v=10000}, {k=0, v=0}}, time=0}
We["1001101"]={id=1001101, name="剧毒之触", des="", path="", valueList={{k=2600, v=0}}, time=5}
We["1001102"]={id=1001102, name="剧毒之触", des="", path="", valueList={{k=3200, v=0}}, time=5}
We["1001103"]={id=1001103, name="剧毒之触", des="", path="", valueList={{k=3800, v=0}}, time=5}
We["1001104"]={id=1001104, name="剧毒之触", des="", path="", valueList={{k=4400, v=0}}, time=5}
We["1001105"]={id=1001105, name="剧毒之触", des="", path="", valueList={{k=5000, v=0}}, time=5}
We["1001106"]={id=1001106, name="剧毒之触", des="", path="", valueList={{k=5600, v=0}}, time=5}
We["1001107"]={id=1001107, name="剧毒之触", des="", path="", valueList={{k=6200, v=0}}, time=5}
We["1001108"]={id=1001108, name="剧毒之触", des="", path="", valueList={{k=6800, v=0}}, time=5}
We["1001109"]={id=1001109, name="剧毒之触", des="", path="", valueList={{k=7400, v=0}}, time=5}
We["1001110"]={id=1001110, name="剧毒之触", des="", path="", valueList={{k=8000, v=0}}, time=5}
We["1001201"]={id=1001201, name="眩晕", des="", path="buff_yunxuan.jpg", time=2}
We["1001202"]={id=1001202, name="眩晕", des="", path="buff_yunxuan.jpg", time=2}
We["1001203"]={id=1001203, name="眩晕", des="", path="buff_yunxuan.jpg", time=2}
We["1001204"]={id=1001204, name="眩晕", des="", path="buff_yunxuan.jpg", time=2}
We["1001205"]={id=1001205, name="眩晕", des="", path="buff_yunxuan.jpg", time=2}
We["1001206"]={id=1001206, name="眩晕", des="", path="buff_yunxuan.jpg", time=2}
We["1001207"]={id=1001207, name="眩晕", des="", path="buff_yunxuan.jpg", time=2}
We["1001208"]={id=1001208, name="眩晕", des="", path="buff_yunxuan.jpg", time=2}
We["1001209"]={id=1001209, name="眩晕", des="", path="buff_yunxuan.jpg", time=2}
We["1001210"]={id=1001210, name="眩晕", des="", path="buff_yunxuan.jpg", time=2}
We["1001301"]={id=1001301, name="伤害加深", des="", path="", valueList={{k=11, v=1200}}, time=3}
We["1001302"]={id=1001302, name="伤害加深", des="", path="", valueList={{k=11, v=1400}}, time=3}
We["1001303"]={id=1001303, name="伤害加深", des="", path="", valueList={{k=11, v=1600}}, time=3}
We["1001304"]={id=1001304, name="伤害加深", des="", path="", valueList={{k=11, v=1800}}, time=3}
We["1001305"]={id=1001305, name="伤害加深", des="", path="", valueList={{k=11, v=2000}}, time=3}
We["1001306"]={id=1001306, name="伤害加深", des="", path="", valueList={{k=11, v=2200}}, time=3}
We["1001307"]={id=1001307, name="伤害加深", des="", path="", valueList={{k=11, v=2400}}, time=3}
We["1001308"]={id=1001308, name="伤害加深", des="", path="", valueList={{k=11, v=2600}}, time=3}
We["1001309"]={id=1001309, name="伤害加深", des="", path="", valueList={{k=11, v=2800}}, time=3}
We["1001310"]={id=1001310, name="伤害加深", des="", path="", valueList={{k=11, v=3000}}, time=3}
We["1002101"]={id=1002101, name="剧毒增幅", des="", path="", valueList={{k=11, v=2600}}, time=0}
We["1002102"]={id=1002102, name="剧毒增幅", des="", path="", valueList={{k=11, v=3200}}, time=0}
We["1002103"]={id=1002103, name="剧毒增幅", des="", path="", valueList={{k=11, v=3800}}, time=0}
We["1002104"]={id=1002104, name="剧毒增幅", des="", path="", valueList={{k=11, v=4400}}, time=0}
We["1002105"]={id=1002105, name="剧毒增幅", des="", path="", valueList={{k=11, v=5000}}, time=0}
We["1002106"]={id=1002106, name="剧毒增幅", des="", path="", valueList={{k=11, v=5600}}, time=0}
We["1002107"]={id=1002107, name="剧毒增幅", des="", path="", valueList={{k=11, v=6200}}, time=0}
We["1002108"]={id=1002108, name="剧毒增幅", des="", path="", valueList={{k=11, v=6800}}, time=0}
We["1002109"]={id=1002109, name="剧毒增幅", des="", path="", valueList={{k=11, v=7400}}, time=0}
We["1002110"]={id=1002110, name="剧毒增幅", des="", path="", valueList={{k=11, v=8000}}, time=0}
We["1002201"]={id=1002201, name="减速", des="", path="buff_jiansu.jpg", valueList={{k=55, v=-1900}}, time=2}
We["1002202"]={id=1002202, name="减速", des="", path="buff_jiansu.jpg", valueList={{k=55, v=-2300}}, time=2}
We["1002203"]={id=1002203, name="减速", des="", path="buff_jiansu.jpg", valueList={{k=55, v=-5500}}, time=2}
We["1002204"]={id=1002204, name="减速", des="", path="buff_jiansu.jpg", valueList={{k=55, v=-3100}}, time=2}
We["1002205"]={id=1002205, name="减速", des="", path="buff_jiansu.jpg", valueList={{k=55, v=-3500}}, time=2}
We["1002206"]={id=1002206, name="减速", des="", path="buff_jiansu.jpg", valueList={{k=55, v=-3900}}, time=2}
We["1002207"]={id=1002207, name="减速", des="", path="buff_jiansu.jpg", valueList={{k=55, v=-4300}}, time=2}
We["1002208"]={id=1002208, name="减速", des="", path="buff_jiansu.jpg", valueList={{k=55, v=-4700}}, time=2}
We["1002209"]={id=1002209, name="减速", des="", path="buff_jiansu.jpg", valueList={{k=55, v=-5100}}, time=2}
We["1002210"]={id=1002210, name="减速", des="", path="buff_jiansu.jpg", valueList={{k=55, v=-5500}}, time=3}
We["1002301"]={id=1002301, name="防御提高", des="", path="", valueList={{k=20, v=2500}}, time=3}
We["1002302"]={id=1002302, name="防御提高", des="", path="", valueList={{k=20, v=3000}}, time=3}
We["1002303"]={id=1002303, name="防御提高", des="", path="", valueList={{k=20, v=3500}}, time=3}
We["1002304"]={id=1002304, name="防御提高", des="", path="", valueList={{k=20, v=4000}}, time=3}
We["1002305"]={id=1002305, name="防御提高", des="", path="", valueList={{k=20, v=4500}}, time=3}
We["1002306"]={id=1002306, name="防御提高", des="", path="", valueList={{k=20, v=5000}}, time=3}
We["1002307"]={id=1002307, name="防御提高", des="", path="", valueList={{k=20, v=5500}}, time=3}
We["1002308"]={id=1002308, name="防御提高", des="", path="", valueList={{k=20, v=6000}}, time=3}
We["1002309"]={id=1002309, name="防御提高", des="", path="", valueList={{k=20, v=6500}}, time=3}
We["1002310"]={id=1002310, name="防御提高", des="", path="", valueList={{k=20, v=7000}}, time=3}
We["1003101"]={id=1003101, name="定身", des="", path="buff_dingshen.jpg", time=4}
We["1003102"]={id=1003102, name="定身", des="", path="buff_dingshen.jpg", time=4}
We["1003103"]={id=1003103, name="定身", des="", path="buff_dingshen.jpg", time=4}
We["1003104"]={id=1003104, name="定身", des="", path="buff_dingshen.jpg", time=4}
We["1003105"]={id=1003105, name="定身", des="", path="buff_dingshen.jpg", time=4}
We["1003106"]={id=1003106, name="定身", des="", path="buff_dingshen.jpg", time=4}
We["1003107"]={id=1003107, name="定身", des="", path="buff_dingshen.jpg", time=4}
We["1003108"]={id=1003108, name="定身", des="", path="buff_dingshen.jpg", time=4}
We["1003109"]={id=1003109, name="定身", des="", path="buff_dingshen.jpg", time=4}
We["1003110"]={id=1003110, name="定身", des="", path="buff_dingshen.jpg", time=4}
We["1003201"]={id=1003201, name="燃烧", des="", path="", valueList={{k=7000, v=0}}, time=3}
We["1003202"]={id=1003202, name="燃烧", des="", path="", valueList={{k=8200, v=0}}, time=3}
We["1003203"]={id=1003203, name="燃烧", des="", path="", valueList={{k=9400, v=0}}, time=3}
We["1003204"]={id=1003204, name="燃烧", des="", path="", valueList={{k=10600, v=0}}, time=3}
We["1003205"]={id=1003205, name="燃烧", des="", path="", valueList={{k=11800, v=0}}, time=3}
We["1003206"]={id=1003206, name="燃烧", des="", path="", valueList={{k=13000, v=0}}, time=3}
We["1003207"]={id=1003207, name="燃烧", des="", path="", valueList={{k=14200, v=0}}, time=3}
We["1003208"]={id=1003208, name="燃烧", des="", path="", valueList={{k=15400, v=0}}, time=3}
We["1003209"]={id=1003209, name="燃烧", des="", path="", valueList={{k=16600, v=0}}, time=3}
We["1003210"]={id=1003210, name="燃烧", des="", path="", valueList={{k=17800, v=0}}, time=3}
We["1003301"]={id=1003301, name="攻击降低", des="", path="", valueList={{k=19, v=-1200}}, time=2}
We["1003302"]={id=1003302, name="攻击降低", des="", path="", valueList={{k=19, v=-1400}}, time=2}
We["1003303"]={id=1003303, name="攻击降低", des="", path="", valueList={{k=19, v=-1600}}, time=2}
We["1003304"]={id=1003304, name="攻击降低", des="", path="", valueList={{k=19, v=-1800}}, time=2}
We["1003305"]={id=1003305, name="攻击降低", des="", path="", valueList={{k=19, v=-2000}}, time=2}
We["1003306"]={id=1003306, name="攻击降低", des="", path="", valueList={{k=19, v=-2200}}, time=2}
We["1003307"]={id=1003307, name="攻击降低", des="", path="", valueList={{k=19, v=-2400}}, time=2}
We["1003308"]={id=1003308, name="攻击降低", des="", path="", valueList={{k=19, v=-2600}}, time=2}
We["1003309"]={id=1003309, name="攻击降低", des="", path="", valueList={{k=19, v=-2800}}, time=2}
We["1003310"]={id=1003310, name="攻击降低", des="", path="", valueList={{k=19, v=-3000}}, time=2}
We["1004101"]={id=1004101, name="防御降低", des="", path="", valueList={{k=20, v=-3600}}, time=4}
We["1004102"]={id=1004102, name="防御降低", des="", path="", valueList={{k=20, v=-4200}}, time=4}
We["1004103"]={id=1004103, name="防御降低", des="", path="", valueList={{k=20, v=-4800}}, time=4}
We["1004104"]={id=1004104, name="防御降低", des="", path="", valueList={{k=20, v=-5400}}, time=4}
We["1004105"]={id=1004105, name="防御降低", des="", path="", valueList={{k=20, v=-6000}}, time=4}
We["1004106"]={id=1004106, name="防御降低", des="", path="", valueList={{k=20, v=-6600}}, time=4}
We["1004107"]={id=1004107, name="防御降低", des="", path="", valueList={{k=20, v=-7200}}, time=4}
We["1004108"]={id=1004108, name="防御降低", des="", path="", valueList={{k=20, v=-7800}}, time=4}
We["1004109"]={id=1004109, name="防御降低", des="", path="", valueList={{k=20, v=-8400}}, time=4}
We["1004110"]={id=1004110, name="防御降低", des="", path="", valueList={{k=20, v=-9000}}, time=4}
We["1004201"]={id=1004201, name="攻击提高", des="", path="", valueList={{k=19, v=1300}}, time=3}
We["1004202"]={id=1004202, name="攻击提高", des="", path="", valueList={{k=19, v=1600}}, time=3}
We["1004203"]={id=1004203, name="攻击提高", des="", path="", valueList={{k=19, v=1900}}, time=3}
We["1004204"]={id=1004204, name="攻击提高", des="", path="", valueList={{k=19, v=2200}}, time=3}
We["1004205"]={id=1004205, name="攻击提高", des="", path="", valueList={{k=19, v=2500}}, time=3}
We["1004206"]={id=1004206, name="攻击提高", des="", path="", valueList={{k=19, v=2800}}, time=3}
We["1004207"]={id=1004207, name="攻击提高", des="", path="", valueList={{k=19, v=3100}}, time=3}
We["1004208"]={id=1004208, name="攻击提高", des="", path="", valueList={{k=19, v=3400}}, time=3}
We["1004209"]={id=1004209, name="攻击提高", des="", path="", valueList={{k=19, v=3700}}, time=3}
We["1004210"]={id=1004210, name="攻击提高", des="", path="", valueList={{k=19, v=4000}}, time=3}
We["1004301"]={id=1004301, name="命中降低", des="", path="", valueList={{k=22, v=-2600}}, time=3}
We["1004302"]={id=1004302, name="命中降低", des="", path="", valueList={{k=22, v=-3200}}, time=3}
We["1004303"]={id=1004303, name="命中降低", des="", path="", valueList={{k=22, v=-3800}}, time=3}
We["1004304"]={id=1004304, name="命中降低", des="", path="", valueList={{k=22, v=-4400}}, time=3}
We["1004305"]={id=1004305, name="命中降低", des="", path="", valueList={{k=22, v=-5000}}, time=3}
We["1004306"]={id=1004306, name="命中降低", des="", path="", valueList={{k=22, v=-5600}}, time=3}
We["1004307"]={id=1004307, name="命中降低", des="", path="", valueList={{k=22, v=-6200}}, time=3}
We["1004308"]={id=1004308, name="命中降低", des="", path="", valueList={{k=22, v=-6800}}, time=3}
We["1004309"]={id=1004309, name="命中降低", des="", path="", valueList={{k=22, v=-7400}}, time=3}
We["1004310"]={id=1004310, name="命中降低", des="", path="", valueList={{k=22, v=-8000}}, time=3}
We["1005101"]={id=1005101, name="沉默", des="", path="buff_chenmo.jpg", time=5}
We["1005102"]={id=1005102, name="沉默", des="", path="buff_chenmo.jpg", time=5}
We["1005103"]={id=1005103, name="沉默", des="", path="buff_chenmo.jpg", time=5}
We["1005104"]={id=1005104, name="沉默", des="", path="buff_chenmo.jpg", time=5}
We["1005105"]={id=1005105, name="沉默", des="", path="buff_chenmo.jpg", time=5}
We["1005106"]={id=1005106, name="沉默", des="", path="buff_chenmo.jpg", time=5}
We["1005107"]={id=1005107, name="沉默", des="", path="buff_chenmo.jpg", time=5}
We["1005108"]={id=1005108, name="沉默", des="", path="buff_chenmo.jpg", time=5}
We["1005109"]={id=1005109, name="沉默", des="", path="buff_chenmo.jpg", time=5}
We["1005110"]={id=1005110, name="沉默", des="", path="buff_chenmo.jpg", time=5}
We["1005201"]={id=1005201, name="降低目标技能伤害", des="", path="", valueList={{k=16, v=-2600}}, time=4}
We["1005202"]={id=1005202, name="降低目标技能伤害", des="", path="", valueList={{k=16, v=-3200}}, time=4}
We["1005203"]={id=1005203, name="降低目标技能伤害", des="", path="", valueList={{k=16, v=-3800}}, time=4}
We["1005204"]={id=1005204, name="降低目标技能伤害", des="", path="", valueList={{k=16, v=-4400}}, time=4}
We["1005205"]={id=1005205, name="降低目标技能伤害", des="", path="", valueList={{k=16, v=-5000}}, time=4}
We["1005206"]={id=1005206, name="降低目标技能伤害", des="", path="", valueList={{k=16, v=-5600}}, time=4}
We["1005207"]={id=1005207, name="降低目标技能伤害", des="", path="", valueList={{k=16, v=-6200}}, time=4}
We["1005208"]={id=1005208, name="降低目标技能伤害", des="", path="", valueList={{k=16, v=-6800}}, time=4}
We["1005209"]={id=1005209, name="降低目标技能伤害", des="", path="", valueList={{k=16, v=-7400}}, time=4}
We["1005210"]={id=1005210, name="降低目标技能伤害", des="", path="", valueList={{k=16, v=-8000}}, time=4}
We["1005301"]={id=1005301, name="护盾", des="", path="", valueList={{k=1300, v=0}}, time=4}
We["1005302"]={id=1005302, name="护盾", des="", path="", valueList={{k=1600, v=0}}, time=4}
We["1005303"]={id=1005303, name="护盾", des="", path="", valueList={{k=1900, v=0}}, time=4}
We["1005304"]={id=1005304, name="护盾", des="", path="", valueList={{k=2200, v=0}}, time=4}
We["1005305"]={id=1005305, name="护盾", des="", path="", valueList={{k=2500, v=0}}, time=4}
We["1005306"]={id=1005306, name="护盾", des="", path="", valueList={{k=2800, v=0}}, time=4}
We["1005307"]={id=1005307, name="护盾", des="", path="", valueList={{k=3100, v=0}}, time=4}
We["1005308"]={id=1005308, name="护盾", des="", path="", valueList={{k=3400, v=0}}, time=4}
We["1005309"]={id=1005309, name="护盾", des="", path="", valueList={{k=3700, v=0}}, time=4}
We["1005310"]={id=1005310, name="护盾", des="", path="", valueList={{k=4000, v=0}}, time=4}
We["1006101"]={id=1006101, name="缴械", des="", path="", time=2}
We["1006102"]={id=1006102, name="缴械", des="", path="", time=2}
We["1006103"]={id=1006103, name="缴械", des="", path="", time=2}
We["1006104"]={id=1006104, name="缴械", des="", path="", time=2}
We["1006105"]={id=1006105, name="缴械", des="", path="", time=2}
We["1006106"]={id=1006106, name="缴械", des="", path="", time=2}
We["1006107"]={id=1006107, name="缴械", des="", path="", time=2}
We["1006108"]={id=1006108, name="缴械", des="", path="", time=2}
We["1006109"]={id=1006109, name="缴械", des="", path="", time=2}
We["1006110"]={id=1006110, name="缴械", des="", path="", time=2}
We["1006201"]={id=1006201, name="爆伤提高", des="", path="", valueList={{k=9, v=5000}}, time=3}
We["1006202"]={id=1006202, name="爆伤提高", des="", path="", valueList={{k=9, v=5000}}, time=3}
We["1006203"]={id=1006203, name="爆伤提高", des="", path="", valueList={{k=9, v=5000}}, time=3}
We["1006204"]={id=1006204, name="爆伤提高", des="", path="", valueList={{k=9, v=5000}}, time=3}
We["1006205"]={id=1006205, name="爆伤提高", des="", path="", valueList={{k=9, v=5000}}, time=3}
We["1006206"]={id=1006206, name="爆伤提高", des="", path="", valueList={{k=9, v=5000}}, time=3}
We["1006207"]={id=1006207, name="爆伤提高", des="", path="", valueList={{k=9, v=5000}}, time=3}
We["1006208"]={id=1006208, name="爆伤提高", des="", path="", valueList={{k=9, v=5000}}, time=3}
We["1006209"]={id=1006209, name="爆伤提高", des="", path="", valueList={{k=9, v=5000}}, time=3}
We["1006210"]={id=1006210, name="爆伤提高", des="", path="", valueList={{k=9, v=5000}}, time=3}
We["1006301"]={id=1006301, name="生命恢复", des="", path="", valueList={{k=6500, v=0}}, time=1}
We["1006302"]={id=1006302, name="生命恢复", des="", path="", valueList={{k=8000, v=0}}, time=1}
We["1006303"]={id=1006303, name="生命恢复", des="", path="", valueList={{k=9500, v=0}}, time=1}
We["1006304"]={id=1006304, name="生命恢复", des="", path="", valueList={{k=11000, v=0}}, time=1}
We["1006305"]={id=1006305, name="生命恢复", des="", path="", valueList={{k=12500, v=0}}, time=1}
We["1006306"]={id=1006306, name="生命恢复", des="", path="", valueList={{k=14000, v=0}}, time=1}
We["1006307"]={id=1006307, name="生命恢复", des="", path="", valueList={{k=15500, v=0}}, time=1}
We["1006308"]={id=1006308, name="生命恢复", des="", path="", valueList={{k=17000, v=0}}, time=1}
We["1006309"]={id=1006309, name="生命恢复", des="", path="", valueList={{k=18500, v=0}}, time=1}
We["1006310"]={id=1006310, name="生命恢复", des="", path="", valueList={{k=20000, v=0}}, time=1}
We["1007101"]={id=1007101, name="中毒恢复", des="", path="", valueList={{k=500, v=0}}, time=4}
We["1007102"]={id=1007102, name="中毒恢复", des="", path="", valueList={{k=500, v=0}}, time=4}
We["1007103"]={id=1007103, name="中毒恢复", des="", path="", valueList={{k=500, v=0}}, time=4}
We["1007104"]={id=1007104, name="中毒恢复", des="", path="", valueList={{k=500, v=0}}, time=4}
We["1007105"]={id=1007105, name="中毒恢复", des="", path="", valueList={{k=500, v=0}}, time=4}
We["1007106"]={id=1007106, name="中毒恢复", des="", path="", valueList={{k=500, v=0}}, time=4}
We["1007107"]={id=1007107, name="中毒恢复", des="", path="", valueList={{k=500, v=0}}, time=4}
We["1007108"]={id=1007108, name="中毒恢复", des="", path="", valueList={{k=500, v=0}}, time=4}
We["1007109"]={id=1007109, name="中毒恢复", des="", path="", valueList={{k=500, v=0}}, time=4}
We["1007110"]={id=1007110, name="中毒恢复", des="", path="", valueList={{k=500, v=0}}, time=4}
We["1007201"]={id=1007201, name="点燃后伤害降低", des="", path="", valueList={{k=12, v=1100}}, time=3}
We["1007202"]={id=1007202, name="点燃后伤害降低", des="", path="", valueList={{k=12, v=1200}}, time=3}
We["1007203"]={id=1007203, name="点燃后伤害降低", des="", path="", valueList={{k=12, v=1300}}, time=3}
We["1007204"]={id=1007204, name="点燃后伤害降低", des="", path="", valueList={{k=12, v=1400}}, time=3}
We["1007205"]={id=1007205, name="点燃后伤害降低", des="", path="", valueList={{k=12, v=1500}}, time=3}
We["1007206"]={id=1007206, name="点燃后伤害降低", des="", path="", valueList={{k=12, v=1600}}, time=3}
We["1007207"]={id=1007207, name="点燃后伤害降低", des="", path="", valueList={{k=12, v=1700}}, time=3}
We["1007208"]={id=1007208, name="点燃后伤害降低", des="", path="", valueList={{k=12, v=1800}}, time=3}
We["1007209"]={id=1007209, name="点燃后伤害降低", des="", path="", valueList={{k=12, v=1900}}, time=3}
We["1007210"]={id=1007210, name="点燃后伤害降低", des="", path="", valueList={{k=12, v=2000}}, time=3}
We["1007301"]={id=1007301, name="破甲提高", des="", path="", valueList={{k=21, v=6500}}, time=5}
We["1007302"]={id=1007302, name="破甲提高", des="", path="", valueList={{k=21, v=8000}}, time=5}
We["1007303"]={id=1007303, name="破甲提高", des="", path="", valueList={{k=21, v=9500}}, time=5}
We["1007304"]={id=1007304, name="破甲提高", des="", path="", valueList={{k=21, v=11000}}, time=5}
We["1007305"]={id=1007305, name="破甲提高", des="", path="", valueList={{k=21, v=12500}}, time=5}
We["1007306"]={id=1007306, name="破甲提高", des="", path="", valueList={{k=21, v=14000}}, time=5}
We["1007307"]={id=1007307, name="破甲提高", des="", path="", valueList={{k=21, v=15500}}, time=5}
We["1007308"]={id=1007308, name="破甲提高", des="", path="", valueList={{k=21, v=17000}}, time=5}
We["1007309"]={id=1007309, name="破甲提高", des="", path="", valueList={{k=21, v=18500}}, time=5}
We["1007310"]={id=1007310, name="破甲提高", des="", path="", valueList={{k=21, v=20000}}, time=5}
We["1101101"]={id=1101101, name="眩晕", des="", path="", time=2}
We["1101102"]={id=1101102, name="眩晕", des="", path="", time=2}
We["1101103"]={id=1101103, name="眩晕", des="", path="", time=2}
We["1101104"]={id=1101104, name="眩晕", des="", path="", time=2}
We["1101105"]={id=1101105, name="眩晕", des="", path="", time=2}
We["1101106"]={id=1101106, name="眩晕", des="", path="", time=2}
We["1101107"]={id=1101107, name="眩晕", des="", path="", time=2}
We["1101108"]={id=1101108, name="眩晕", des="", path="", time=2}
We["1101109"]={id=1101109, name="眩晕", des="", path="", time=2}
We["1101110"]={id=1101110, name="眩晕", des="", path="", time=2}
We["1101201"]={id=1101201, name="点燃", des="", path="", valueList={{k=8000, v=0}}, time=3}
We["1101202"]={id=1101202, name="点燃", des="", path="", valueList={{k=9000, v=0}}, time=3}
We["1101203"]={id=1101203, name="点燃", des="", path="", valueList={{k=10000, v=0}}, time=3}
We["1101204"]={id=1101204, name="点燃", des="", path="", valueList={{k=11000, v=0}}, time=3}
We["1101205"]={id=1101205, name="点燃", des="", path="", valueList={{k=12000, v=0}}, time=3}
We["1101206"]={id=1101206, name="点燃", des="", path="", valueList={{k=13000, v=0}}, time=3}
We["1101207"]={id=1101207, name="点燃", des="", path="", valueList={{k=14000, v=0}}, time=3}
We["1101208"]={id=1101208, name="点燃", des="", path="", valueList={{k=15000, v=0}}, time=3}
We["1101209"]={id=1101209, name="点燃", des="", path="", valueList={{k=16000, v=0}}, time=3}
We["1101210"]={id=1101210, name="点燃", des="", path="", valueList={{k=17000, v=0}}, time=3}
We["1101301"]={id=1101301, name="暴击后伤害增加", des="", path="", valueList={{k=11, v=1200}}, time=2}
We["1101302"]={id=1101302, name="暴击后伤害增加", des="", path="", valueList={{k=11, v=1400}}, time=2}
We["1101303"]={id=1101303, name="暴击后伤害增加", des="", path="", valueList={{k=11, v=1600}}, time=2}
We["1101304"]={id=1101304, name="暴击后伤害增加", des="", path="", valueList={{k=11, v=1800}}, time=2}
We["1101305"]={id=1101305, name="暴击后伤害增加", des="", path="", valueList={{k=11, v=2000}}, time=2}
We["1101306"]={id=1101306, name="暴击后伤害增加", des="", path="", valueList={{k=11, v=2200}}, time=2}
We["1101307"]={id=1101307, name="暴击后伤害增加", des="", path="", valueList={{k=11, v=2400}}, time=2}
We["1101308"]={id=1101308, name="暴击后伤害增加", des="", path="", valueList={{k=11, v=2600}}, time=2}
We["1101309"]={id=1101309, name="暴击后伤害增加", des="", path="", valueList={{k=11, v=2800}}, time=2}
We["1101310"]={id=1101310, name="暴击后伤害增加", des="", path="", valueList={{k=11, v=3000}}, time=2}
We["1102101"]={id=1102101, name="伤害降低", des="", path="", valueList={{k=11, v=-1200}}, time=2}
We["1102102"]={id=1102102, name="伤害降低", des="", path="", valueList={{k=11, v=-1400}}, time=2}
We["1102103"]={id=1102103, name="伤害降低", des="", path="", valueList={{k=11, v=-1600}}, time=2}
We["1102104"]={id=1102104, name="伤害降低", des="", path="", valueList={{k=11, v=-1800}}, time=2}
We["1102105"]={id=1102105, name="伤害降低", des="", path="", valueList={{k=11, v=-2000}}, time=2}
We["1102106"]={id=1102106, name="伤害降低", des="", path="", valueList={{k=11, v=-2200}}, time=2}
We["1102107"]={id=1102107, name="伤害降低", des="", path="", valueList={{k=11, v=-2400}}, time=2}
We["1102108"]={id=1102108, name="伤害降低", des="", path="", valueList={{k=11, v=-2600}}, time=2}
We["1102109"]={id=1102109, name="伤害降低", des="", path="", valueList={{k=11, v=-2800}}, time=2}
We["1102110"]={id=1102110, name="伤害降低", des="", path="", valueList={{k=11, v=-3000}}, time=2}
We["1102201"]={id=1102201, name="对方伤害降低", des="", path="", valueList={{k=11, v=-700}}, time=2}
We["1102202"]={id=1102202, name="对方伤害降低", des="", path="", valueList={{k=11, v=-900}}, time=2}
We["1102203"]={id=1102203, name="对方伤害降低", des="", path="", valueList={{k=11, v=-1100}}, time=2}
We["1102204"]={id=1102204, name="对方伤害降低", des="", path="", valueList={{k=11, v=-1300}}, time=2}
We["1102205"]={id=1102205, name="对方伤害降低", des="", path="", valueList={{k=11, v=-1500}}, time=2}
We["1102206"]={id=1102206, name="对方伤害降低", des="", path="", valueList={{k=11, v=-1700}}, time=2}
We["1102207"]={id=1102207, name="对方伤害降低", des="", path="", valueList={{k=11, v=-1900}}, time=2}
We["1102208"]={id=1102208, name="对方伤害降低", des="", path="", valueList={{k=11, v=-2100}}, time=2}
We["1102209"]={id=1102209, name="对方伤害降低", des="", path="", valueList={{k=11, v=-2300}}, time=2}
We["1102210"]={id=1102210, name="对方伤害降低", des="", path="", valueList={{k=11, v=-2500}}, time=2}
We["1102301"]={id=1102301, name="伤害反射", des="", path="", valueList={{k=53, v=2500}}, time=3}
We["1102302"]={id=1102302, name="伤害反射", des="", path="", valueList={{k=53, v=3000}}, time=3}
We["1102303"]={id=1102303, name="伤害反射", des="", path="", valueList={{k=53, v=3500}}, time=3}
We["1102304"]={id=1102304, name="伤害反射", des="", path="", valueList={{k=53, v=4000}}, time=3}
We["1102305"]={id=1102305, name="伤害反射", des="", path="", valueList={{k=53, v=4500}}, time=3}
We["1102306"]={id=1102306, name="伤害反射", des="", path="", valueList={{k=53, v=5000}}, time=3}
We["1102307"]={id=1102307, name="伤害反射", des="", path="", valueList={{k=53, v=5500}}, time=3}
We["1102308"]={id=1102308, name="伤害反射", des="", path="", valueList={{k=53, v=6000}}, time=3}
We["1102309"]={id=1102309, name="伤害反射", des="", path="", valueList={{k=53, v=6500}}, time=3}
We["1102310"]={id=1102310, name="伤害反射", des="", path="", valueList={{k=53, v=7000}}, time=3}
We["1103101"]={id=1103101, name="多重中毒", des="", path="", valueList={{k=2600, v=0}}, time=5}
We["1103102"]={id=1103102, name="多重中毒", des="", path="", valueList={{k=3200, v=0}}, time=5}
We["1103103"]={id=1103103, name="多重中毒", des="", path="", valueList={{k=3800, v=0}}, time=5}
We["1103104"]={id=1103104, name="多重中毒", des="", path="", valueList={{k=4400, v=0}}, time=5}
We["1103105"]={id=1103105, name="多重中毒", des="", path="", valueList={{k=5000, v=0}}, time=5}
We["1103106"]={id=1103106, name="多重中毒", des="", path="", valueList={{k=5600, v=0}}, time=5}
We["1103107"]={id=1103107, name="多重中毒", des="", path="", valueList={{k=6200, v=0}}, time=5}
We["1103108"]={id=1103108, name="多重中毒", des="", path="", valueList={{k=6800, v=0}}, time=5}
We["1103109"]={id=1103109, name="多重中毒", des="", path="", valueList={{k=7400, v=0}}, time=5}
We["1103110"]={id=1103110, name="多重中毒", des="", path="", valueList={{k=8000, v=0}}, time=5}
We["1103201"]={id=1103201, name="眩晕", des="", path="", time=2}
We["1103202"]={id=1103202, name="眩晕", des="", path="", time=2}
We["1103203"]={id=1103203, name="眩晕", des="", path="", time=2}
We["1103204"]={id=1103204, name="眩晕", des="", path="", time=2}
We["1103205"]={id=1103205, name="眩晕", des="", path="", time=2}
We["1103206"]={id=1103206, name="眩晕", des="", path="", time=2}
We["1103207"]={id=1103207, name="眩晕", des="", path="", time=2}
We["1103208"]={id=1103208, name="眩晕", des="", path="", time=2}
We["1103209"]={id=1103209, name="眩晕", des="", path="", time=2}
We["1103210"]={id=1103210, name="眩晕", des="", path="", time=2}
We["1103301"]={id=1103301, name="触发暴击", des="", path="", time=0}
We["1103302"]={id=1103302, name="触发暴击", des="", path="", time=0}
We["1103303"]={id=1103303, name="触发暴击", des="", path="", time=0}
We["1103304"]={id=1103304, name="触发暴击", des="", path="", time=0}
We["1103305"]={id=1103305, name="触发暴击", des="", path="", time=0}
We["1103306"]={id=1103306, name="触发暴击", des="", path="", time=0}
We["1103307"]={id=1103307, name="触发暴击", des="", path="", time=0}
We["1103308"]={id=1103308, name="触发暴击", des="", path="", time=0}
We["1103309"]={id=1103309, name="触发暴击", des="", path="", time=0}
We["1103310"]={id=1103310, name="触发暴击", des="", path="", time=0}
We["1104001"]={id=1104001, name="太极剑体驱散效果", des="每隔40秒可以解除一次自己身上的异常状态", path="buff_gongji.jpg", time=0}
We["1104101"]={id=1104101, name="范围减速", des="", path="", valueList={{k=55, v=-3500}}, time=3}
We["1104102"]={id=1104102, name="范围减速", des="", path="", valueList={{k=55, v=-4000}}, time=3}
We["1104103"]={id=1104103, name="范围减速", des="", path="", valueList={{k=55, v=-4500}}, time=3}
We["1104104"]={id=1104104, name="范围减速", des="", path="", valueList={{k=55, v=-5000}}, time=3}
We["1104105"]={id=1104105, name="范围减速", des="", path="", valueList={{k=55, v=-5500}}, time=3}
We["1104106"]={id=1104106, name="范围减速", des="", path="", valueList={{k=55, v=-6000}}, time=3}
We["1104107"]={id=1104107, name="范围减速", des="", path="", valueList={{k=55, v=-6500}}, time=3}
We["1104108"]={id=1104108, name="范围减速", des="", path="", valueList={{k=55, v=-7000}}, time=3}
We["1104109"]={id=1104109, name="范围减速", des="", path="", valueList={{k=55, v=-7500}}, time=3}
We["1104110"]={id=1104110, name="范围减速", des="", path="", valueList={{k=55, v=-8000}}, time=3}
We["1104201"]={id=1104201, name="命中点燃后攻击提高", des="", path="", valueList={{k=19, v=700}}, time=3}
We["1104202"]={id=1104202, name="命中点燃后攻击提高", des="", path="", valueList={{k=19, v=900}}, time=3}
We["1104203"]={id=1104203, name="命中点燃后攻击提高", des="", path="", valueList={{k=19, v=1100}}, time=3}
We["1104204"]={id=1104204, name="命中点燃后攻击提高", des="", path="", valueList={{k=19, v=1300}}, time=3}
We["1104205"]={id=1104205, name="命中点燃后攻击提高", des="", path="", valueList={{k=19, v=1500}}, time=3}
We["1104206"]={id=1104206, name="命中点燃后攻击提高", des="", path="", valueList={{k=19, v=1700}}, time=3}
We["1104207"]={id=1104207, name="命中点燃后攻击提高", des="", path="", valueList={{k=19, v=1900}}, time=3}
We["1104208"]={id=1104208, name="命中点燃后攻击提高", des="", path="", valueList={{k=19, v=2100}}, time=3}
We["1104209"]={id=1104209, name="命中点燃后攻击提高", des="", path="", valueList={{k=19, v=2300}}, time=3}
We["1104210"]={id=1104210, name="命中点燃后攻击提高", des="", path="", valueList={{k=19, v=2500}}, time=3}
We["1104301"]={id=1104301, name="反击", des="", path="", valueList={{k=53, v=6000}}, time=0}
We["1104302"]={id=1104302, name="反击", des="", path="", valueList={{k=53, v=7000}}, time=0}
We["1104303"]={id=1104303, name="反击", des="", path="", valueList={{k=53, v=8000}}, time=0}
We["1104304"]={id=1104304, name="反击", des="", path="", valueList={{k=53, v=9000}}, time=0}
We["1104305"]={id=1104305, name="反击", des="", path="", valueList={{k=53, v=10000}}, time=0}
We["1104306"]={id=1104306, name="反击", des="", path="", valueList={{k=53, v=11000}}, time=0}
We["1104307"]={id=1104307, name="反击", des="", path="", valueList={{k=53, v=12000}}, time=0}
We["1104308"]={id=1104308, name="反击", des="", path="", valueList={{k=53, v=13000}}, time=0}
We["1104309"]={id=1104309, name="反击", des="", path="", valueList={{k=53, v=14000}}, time=0}
We["1104310"]={id=1104310, name="反击", des="", path="", valueList={{k=53, v=15000}}, time=0}
We["1111001"]={id=1111001, name="移花接木", des="概率回血", path="", valueList={{k=200, v=0}}, time=1}
We["1116001"]={id=1116001, name="无声润物", des="每3秒回复一定攻击力比例生命值", path="", valueList={{k=2300, v=0}}, time=1}
We["1116002"]={id=1116002, name="无声润物", des="每3秒回复一定攻击力比例生命值", path="", valueList={{k=2600, v=0}}, time=1}
We["1116003"]={id=1116003, name="无声润物", des="每3秒回复一定攻击力比例生命值", path="", valueList={{k=2900, v=0}}, time=1}
We["1116004"]={id=1116004, name="无声润物", des="每3秒回复一定攻击力比例生命值", path="", valueList={{k=3200, v=0}}, time=1}
We["1116005"]={id=1116005, name="无声润物", des="每3秒回复一定攻击力比例生命值", path="", valueList={{k=3500, v=0}}, time=1}
We["1116006"]={id=1116006, name="无声润物", des="每3秒回复一定攻击力比例生命值", path="", valueList={{k=3800, v=0}}, time=1}
We["1116007"]={id=1116007, name="无声润物", des="每3秒回复一定攻击力比例生命值", path="", valueList={{k=4100, v=0}}, time=1}
We["1116008"]={id=1116008, name="无声润物", des="每3秒回复一定攻击力比例生命值", path="", valueList={{k=4400, v=0}}, time=1}
We["1116009"]={id=1116009, name="无声润物", des="每3秒回复一定攻击力比例生命值", path="", valueList={{k=4700, v=0}}, time=1}
We["1116010"]={id=1116010, name="无声润物", des="每3秒回复一定攻击力比例生命值", path="", valueList={{k=5000, v=0}}, time=1}
We["1117001"]={id=1117001, name="枯木生华", des="概率回血", path="", valueList={{k=1100, v=0}}, time=1}
We["1117002"]={id=1117002, name="枯木生华", des="概率回血", path="", valueList={{k=1200, v=0}}, time=1}
We["1117003"]={id=1117003, name="枯木生华", des="概率回血", path="", valueList={{k=1300, v=0}}, time=1}
We["1117004"]={id=1117004, name="枯木生华", des="概率回血", path="", valueList={{k=1400, v=0}}, time=1}
We["1117005"]={id=1117005, name="枯木生华", des="概率回血", path="", valueList={{k=1500, v=0}}, time=1}
We["1117006"]={id=1117006, name="枯木生华", des="概率回血", path="", valueList={{k=1600, v=0}}, time=1}
We["1117007"]={id=1117007, name="枯木生华", des="概率回血", path="", valueList={{k=1700, v=0}}, time=1}
We["1117008"]={id=1117008, name="枯木生华", des="概率回血", path="", valueList={{k=1800, v=0}}, time=1}
We["1117009"]={id=1117009, name="枯木生华", des="概率回血", path="", valueList={{k=1900, v=0}}, time=1}
We["1117010"]={id=1117010, name="枯木生华", des="概率回血", path="", valueList={{k=2000, v=0}}, time=1}
We["5012001"]={id=5012001, name="生命回复", des="生命回复", path="buff_huixue.jpg", valueList={{k=1500, v=0}}, time=5}
We["5012002"]={id=5012002, name="生命回复", des="生命回复", path="buff_huixue.jpg", valueList={{k=2000, v=0}}, time=5}
We["5012003"]={id=5012003, name="生命回复", des="生命回复", path="buff_huixue.jpg", valueList={{k=2500, v=0}}, time=5}
We["5012004"]={id=5012004, name="生命回复", des="生命回复", path="buff_huixue.jpg", valueList={{k=3000, v=0}}, time=5}
We["5012005"]={id=5012005, name="生命回复", des="生命回复", path="buff_huixue.jpg", valueList={{k=3500, v=0}}, time=5}
We["9201001"]={id=9201001, name="攻击提高", des="", path="", valueList={{k=19, v=2000}}, time=5}
We["9203001"]={id=9203001, name="麻痹目标", des="", path="", valueList={{k=2000, v=0}}, time=2}
We["9205001"]={id=9205001, name="伤害降低", des="", path="", valueList={{k=12, v=3000}}, time=5}
We["9207001"]={id=9207001, name="生命回复", des="", path="", valueList={{k=500, v=0}}, time=5}
We["9209001"]={id=9209001, name="暴击提高", des="", path="", valueList={{k=24, v=1000}}, time=5}
We["11005001"]={id=11005001, name="敌方攻击防御减少", des="", path="", valueList={{k=19, v=200}, {k=20, v=200}}, time=5}
We["11005002"]={id=11005002, name="敌方攻击防御减少", des="", path="", valueList={{k=19, v=400}, {k=20, v=400}}, time=5}
We["11005003"]={id=11005003, name="敌方攻击防御减少", des="", path="", valueList={{k=19, v=600}, {k=20, v=600}}, time=5}
We["11005004"]={id=11005004, name="敌方攻击防御减少", des="", path="", valueList={{k=19, v=800}, {k=20, v=800}}, time=5}
We["11005005"]={id=11005005, name="敌方攻击防御减少", des="", path="", valueList={{k=19, v=1000}, {k=20, v=1000}}, time=5}
We["11005006"]={id=11005006, name="敌方攻击防御减少", des="", path="", valueList={{k=19, v=1200}, {k=20, v=1200}}, time=5}
We["11005007"]={id=11005007, name="敌方攻击防御减少", des="", path="", valueList={{k=19, v=1400}, {k=20, v=1400}}, time=5}
We["11005008"]={id=11005008, name="敌方攻击防御减少", des="", path="", valueList={{k=19, v=1600}, {k=20, v=1600}}, time=5}
We["11005009"]={id=11005009, name="敌方攻击防御减少", des="", path="", valueList={{k=19, v=1800}, {k=20, v=1800}}, time=5}
We["11005010"]={id=11005010, name="敌方攻击防御减少", des="", path="", valueList={{k=19, v=2000}, {k=20, v=2000}}, time=5}
We["11005011"]={id=11005011, name="偷取敌方攻击防御", des="", path="", valueList={{k=19, v=200}, {k=20, v=200}}, time=5}
We["11005012"]={id=11005012, name="偷取敌方攻击防御", des="", path="", valueList={{k=19, v=400}, {k=20, v=400}}, time=5}
We["11005013"]={id=11005013, name="偷取敌方攻击防御", des="", path="", valueList={{k=19, v=600}, {k=20, v=600}}, time=5}
We["11005014"]={id=11005014, name="偷取敌方攻击防御", des="", path="", valueList={{k=19, v=800}, {k=20, v=800}}, time=5}
We["11005015"]={id=11005015, name="偷取敌方攻击防御", des="", path="", valueList={{k=19, v=1000}, {k=20, v=1000}}, time=5}
We["11005016"]={id=11005016, name="偷取敌方攻击防御", des="", path="", valueList={{k=19, v=1200}, {k=20, v=1200}}, time=5}
We["11005017"]={id=11005017, name="偷取敌方攻击防御", des="", path="", valueList={{k=19, v=1400}, {k=20, v=1400}}, time=5}
We["11005018"]={id=11005018, name="偷取敌方攻击防御", des="", path="", valueList={{k=19, v=1600}, {k=20, v=1600}}, time=5}
We["11005019"]={id=11005019, name="偷取敌方攻击防御", des="", path="", valueList={{k=19, v=1800}, {k=20, v=1800}}, time=5}
We["11005020"]={id=11005020, name="偷取敌方攻击防御", des="", path="", valueList={{k=19, v=2000}, {k=20, v=2000}}, time=5}
We["11009001"]={id=11009001, name="提高伤害减免", des="", path="", valueList={{k=12, v=500}}, time=5}
We["11009002"]={id=11009002, name="提高伤害减免", des="", path="", valueList={{k=12, v=1000}}, time=5}
We["11009003"]={id=11009003, name="提高伤害减免", des="", path="", valueList={{k=12, v=1500}}, time=5}
We["11009004"]={id=11009004, name="提高伤害减免", des="", path="", valueList={{k=12, v=2000}}, time=5}
We["11009005"]={id=11009005, name="提高伤害减免", des="", path="", valueList={{k=12, v=2500}}, time=5}
We["11009006"]={id=11009006, name="提高伤害减免", des="", path="", valueList={{k=12, v=3000}}, time=5}
We["11010001"]={id=11010001, name="致死豁免", des="致死伤害豁免", path="buff_wudi.jpg", time=5}
We["11011001"]={id=11011001, name="免疫", des="免疫", path="buff_yunxuan.jpg", time=1.9}
We["11011002"]={id=11011002, name="免疫", des="免疫", path="buff_yunxuan.jpg", time=2.3}
We["11011003"]={id=11011003, name="免疫", des="免疫", path="buff_yunxuan.jpg", time=2.7}
We["11011004"]={id=11011004, name="免疫", des="免疫", path="buff_yunxuan.jpg", time=3.1}
We["11011005"]={id=11011005, name="免疫", des="免疫", path="buff_yunxuan.jpg", time=3.5}
We["11011006"]={id=11011006, name="免疫", des="免疫", path="buff_yunxuan.jpg", time=3.9}
We["11011007"]={id=11011007, name="免疫", des="免疫", path="buff_yunxuan.jpg", time=4.3}
We["11011008"]={id=11011008, name="免疫", des="免疫", path="buff_yunxuan.jpg", time=4.7}
We["11011009"]={id=11011009, name="免疫", des="免疫", path="buff_yunxuan.jpg", time=5.1}
We["11011010"]={id=11011010, name="免疫", des="免疫", path="buff_yunxuan.jpg", time=5.5}
We["11012001"]={id=11012001, name="每秒回复固定生命", des="生命回复", path="", valueList={{k=500, v=0}}, time=3}
We["11012002"]={id=11012002, name="每秒回复固定生命", des="生命回复", path="", valueList={{k=500, v=0}}, time=4}
We["11012003"]={id=11012003, name="每秒回复固定生命", des="生命回复", path="", valueList={{k=500, v=0}}, time=5}
We["11012004"]={id=11012004, name="每秒回复固定生命", des="生命回复", path="", valueList={{k=500, v=0}}, time=6}
We["11012005"]={id=11012005, name="每秒回复固定生命", des="生命回复", path="", valueList={{k=500, v=0}}, time=7}
We["11012006"]={id=11012006, name="每秒回复固定生命", des="生命回复", path="", valueList={{k=500, v=0}}, time=8}
We["11014001"]={id=11014001, name="境界提高增伤/减伤", des="", path="", valueList={{k=94, v=10}, {k=93, v=10}}, time=60}
We["11014002"]={id=11014002, name="境界提高增伤/减伤", des="", path="", valueList={{k=94, v=20}, {k=93, v=20}}, time=60}
We["11014003"]={id=11014003, name="境界提高增伤/减伤", des="", path="", valueList={{k=94, v=30}, {k=93, v=30}}, time=60}
We["11014004"]={id=11014004, name="境界提高增伤/减伤", des="", path="", valueList={{k=94, v=40}, {k=93, v=40}}, time=60}
We["11014005"]={id=11014005, name="境界提高增伤/减伤", des="", path="", valueList={{k=94, v=50}, {k=93, v=50}}, time=60}
We["11014006"]={id=11014006, name="境界提高增伤/减伤", des="", path="", valueList={{k=94, v=60}, {k=93, v=60}}, time=60}
We["11017001"]={id=11017001, name="格挡回复", des="", path="", valueList={{k=50, v=0}}, time=1}
We["11017002"]={id=11017002, name="格挡回复", des="", path="", valueList={{k=100, v=0}}, time=1}
We["11017003"]={id=11017003, name="格挡回复", des="", path="", valueList={{k=150, v=0}}, time=1}
We["11017004"]={id=11017004, name="格挡回复", des="", path="", valueList={{k=200, v=0}}, time=1}
We["11017005"]={id=11017005, name="格挡回复", des="", path="", valueList={{k=250, v=0}}, time=1}
We["11017006"]={id=11017006, name="格挡回复", des="", path="", valueList={{k=300, v=0}}, time=1}
We["11017007"]={id=11017007, name="格挡回复", des="", path="", valueList={{k=350, v=0}}, time=1}
We["11017008"]={id=11017008, name="格挡回复", des="", path="", valueList={{k=400, v=0}}, time=1}
We["11017009"]={id=11017009, name="格挡回复", des="", path="", valueList={{k=450, v=0}}, time=1}
We["11017010"]={id=11017010, name="格挡回复", des="", path="", valueList={{k=500, v=0}}, time=1}
We["11018001"]={id=11018001, name="格挡削弱", des="", path="", valueList={{k=95, v=-100}}, time=3}
We["11018002"]={id=11018002, name="格挡削弱", des="", path="", valueList={{k=95, v=-200}}, time=3}
We["11018003"]={id=11018003, name="格挡削弱", des="", path="", valueList={{k=95, v=-300}}, time=3}
We["11018004"]={id=11018004, name="格挡削弱", des="", path="", valueList={{k=95, v=-400}}, time=3}
We["11018005"]={id=11018005, name="格挡削弱", des="", path="", valueList={{k=95, v=-500}}, time=3}
We["11018006"]={id=11018006, name="格挡削弱", des="", path="", valueList={{k=95, v=-600}}, time=3}
We["11018007"]={id=11018007, name="格挡削弱", des="", path="", valueList={{k=95, v=-700}}, time=3}
We["11018008"]={id=11018008, name="格挡削弱", des="", path="", valueList={{k=95, v=-800}}, time=3}
We["11018009"]={id=11018009, name="格挡削弱", des="", path="", valueList={{k=95, v=-900}}, time=3}
We["11018010"]={id=11018010, name="格挡削弱", des="", path="", valueList={{k=95, v=-1000}}, time=3}
We["11020001"]={id=11020001, name="格挡反馈", des="", path="", valueList={{k=95, v=100}}, time=3}
We["11020002"]={id=11020002, name="格挡反馈", des="", path="", valueList={{k=95, v=200}}, time=3}
We["11020003"]={id=11020003, name="格挡反馈", des="", path="", valueList={{k=95, v=300}}, time=3}
We["11020004"]={id=11020004, name="格挡反馈", des="", path="", valueList={{k=95, v=400}}, time=3}
We["11020005"]={id=11020005, name="格挡反馈", des="", path="", valueList={{k=95, v=500}}, time=3}
We["11020006"]={id=11020006, name="格挡反馈", des="", path="", valueList={{k=95, v=600}}, time=3}
We["11020007"]={id=11020007, name="格挡反馈", des="", path="", valueList={{k=95, v=700}}, time=3}
We["11020008"]={id=11020008, name="格挡反馈", des="", path="", valueList={{k=95, v=800}}, time=3}
We["11020009"]={id=11020009, name="格挡反馈", des="", path="", valueList={{k=95, v=900}}, time=3}
We["11020010"]={id=11020010, name="格挡反馈", des="", path="", valueList={{k=95, v=1000}}, time=3}
We["11021001"]={id=11021001, name="格挡眩晕", des="2秒眩晕（仙魂副本技能2效果）", path="buff_yunxuan.jpg", time=1}
We["11022001"]={id=11022001, name="伤害减免提高", des="", path="", valueList={{k=12, v=50}}, time=3}
We["11022002"]={id=11022002, name="伤害减免提高", des="", path="", valueList={{k=12, v=100}}, time=3}
We["11022003"]={id=11022003, name="伤害减免提高", des="", path="", valueList={{k=12, v=150}}, time=3}
We["11022004"]={id=11022004, name="伤害减免提高", des="", path="", valueList={{k=12, v=200}}, time=3}
We["11022005"]={id=11022005, name="伤害减免提高", des="", path="", valueList={{k=12, v=250}}, time=3}
We["11022006"]={id=11022006, name="伤害减免提高", des="", path="", valueList={{k=12, v=300}}, time=3}
We["11022007"]={id=11022007, name="伤害减免提高", des="", path="", valueList={{k=12, v=350}}, time=3}
We["11022008"]={id=11022008, name="伤害减免提高", des="", path="", valueList={{k=12, v=400}}, time=3}
We["11022009"]={id=11022009, name="伤害减免提高", des="", path="", valueList={{k=12, v=450}}, time=3}
We["11022010"]={id=11022010, name="伤害减免提高", des="", path="", valueList={{k=12, v=500}}, time=3}
We["11023001"]={id=11023001, name="技能减免提高", des="", path="", valueList={{k=17, v=60}}, time=3}
We["11023002"]={id=11023002, name="技能减免提高", des="", path="", valueList={{k=17, v=120}}, time=3}
We["11023003"]={id=11023003, name="技能减免提高", des="", path="", valueList={{k=17, v=180}}, time=3}
We["11023004"]={id=11023004, name="技能减免提高", des="", path="", valueList={{k=17, v=240}}, time=3}
We["11023005"]={id=11023005, name="技能减免提高", des="", path="", valueList={{k=17, v=300}}, time=3}
We["11023006"]={id=11023006, name="技能减免提高", des="", path="", valueList={{k=17, v=360}}, time=3}
We["11023007"]={id=11023007, name="技能减免提高", des="", path="", valueList={{k=17, v=420}}, time=3}
We["11023008"]={id=11023008, name="技能减免提高", des="", path="", valueList={{k=17, v=480}}, time=3}
We["11023009"]={id=11023009, name="技能减免提高", des="", path="", valueList={{k=17, v=540}}, time=3}
We["11023010"]={id=11023010, name="技能减免提高", des="", path="", valueList={{k=17, v=600}}, time=3}
We["11025001"]={id=11025001, name="间歇格挡", des="", path="", valueList={{k=96, v=1000}}, time=5}
We["11025002"]={id=11025002, name="间歇格挡", des="", path="", valueList={{k=96, v=2000}}, time=5}
We["11025003"]={id=11025003, name="间歇格挡", des="", path="", valueList={{k=96, v=3000}}, time=5}
We["11025004"]={id=11025004, name="间歇格挡", des="", path="", valueList={{k=96, v=4000}}, time=5}
We["11025005"]={id=11025005, name="间歇格挡", des="", path="", valueList={{k=96, v=5000}}, time=5}
We["11027001"]={id=11027001, name="格挡恢复", des="", path="", valueList={{k=30, v=0}}, time=1}
We["11027002"]={id=11027002, name="格挡恢复", des="", path="", valueList={{k=60, v=0}}, time=1}
We["11027003"]={id=11027003, name="格挡恢复", des="", path="", valueList={{k=90, v=0}}, time=1}
We["11027004"]={id=11027004, name="格挡恢复", des="", path="", valueList={{k=120, v=0}}, time=1}
We["11027005"]={id=11027005, name="格挡恢复", des="", path="", valueList={{k=150, v=0}}, time=1}
We["11027006"]={id=11027006, name="格挡恢复", des="", path="", valueList={{k=180, v=0}}, time=1}
We["11029001"]={id=11029001, name="格挡免疫", des="", path="", time=1.8}
We["11029002"]={id=11029002, name="格挡免疫", des="", path="", time=2.1}
We["11029003"]={id=11029003, name="格挡免疫", des="", path="", time=2.4}
We["11029004"]={id=11029004, name="格挡免疫", des="", path="", time=2.7}
We["11029005"]={id=11029005, name="格挡免疫", des="", path="", time=3}
We["11029006"]={id=11029006, name="格挡免疫", des="", path="", time=1}
We["11036001"]={id=11036001, name="剑殇·洄", des="", path="", valueList={{k=5, v=0}}, time=1}
We["11036002"]={id=11036002, name="剑殇·洄", des="", path="", valueList={{k=10, v=0}}, time=1}
We["11036003"]={id=11036003, name="剑殇·洄", des="", path="", valueList={{k=15, v=0}}, time=1}
We["11036004"]={id=11036004, name="剑殇·洄", des="", path="", valueList={{k=20, v=0}}, time=1}
We["11036005"]={id=11036005, name="剑殇·洄", des="", path="", valueList={{k=25, v=0}}, time=1}
We["11036006"]={id=11036006, name="剑殇·洄", des="", path="", valueList={{k=30, v=0}}, time=1}
We["11036007"]={id=11036007, name="剑殇·洄", des="", path="", valueList={{k=35, v=0}}, time=1}
We["11036008"]={id=11036008, name="剑殇·洄", des="", path="", valueList={{k=40, v=0}}, time=1}
We["11036009"]={id=11036009, name="剑殇·洄", des="", path="", valueList={{k=45, v=0}}, time=1}
We["11036010"]={id=11036010, name="剑殇·洄", des="", path="", valueList={{k=50, v=0}}, time=1}
We["11038001"]={id=11038001, name="剑殇·怒", des="", path="", valueList={{k=19, v=200}}, time=5}
We["11038002"]={id=11038002, name="剑殇·怒", des="", path="", valueList={{k=19, v=400}}, time=5}
We["11038003"]={id=11038003, name="剑殇·怒", des="", path="", valueList={{k=19, v=600}}, time=5}
We["11038004"]={id=11038004, name="剑殇·怒", des="", path="", valueList={{k=19, v=800}}, time=5}
We["11038005"]={id=11038005, name="剑殇·怒", des="", path="", valueList={{k=19, v=1000}}, time=5}
We["11038006"]={id=11038006, name="剑殇·怒", des="", path="", valueList={{k=19, v=1200}}, time=5}
We["11038007"]={id=11038007, name="剑殇·怒", des="", path="", valueList={{k=19, v=1400}}, time=5}
We["11038008"]={id=11038008, name="剑殇·怒", des="", path="", valueList={{k=19, v=1600}}, time=5}
We["11038009"]={id=11038009, name="剑殇·怒", des="", path="", valueList={{k=19, v=1800}}, time=5}
We["11038010"]={id=11038010, name="剑殇·怒", des="", path="", valueList={{k=19, v=2000}}, time=5}
We["11041001"]={id=11041001, name="剑荡·破", des="", path="", valueList={{k=19, v=-200}}, time=3}
We["11041002"]={id=11041002, name="剑荡·破", des="", path="", valueList={{k=19, v=-400}}, time=3}
We["11041003"]={id=11041003, name="剑荡·破", des="", path="", valueList={{k=19, v=-600}}, time=3}
We["11041004"]={id=11041004, name="剑荡·破", des="", path="", valueList={{k=19, v=-800}}, time=3}
We["11041005"]={id=11041005, name="剑荡·破", des="", path="", valueList={{k=19, v=-1000}}, time=3}
We["11041006"]={id=11041006, name="剑荡·破", des="", path="", valueList={{k=19, v=-1200}}, time=3}
We["11041007"]={id=11041007, name="剑荡·破", des="", path="", valueList={{k=19, v=-1400}}, time=3}
We["11041008"]={id=11041008, name="剑荡·破", des="", path="", valueList={{k=19, v=-1600}}, time=3}
We["11041009"]={id=11041009, name="剑荡·破", des="", path="", valueList={{k=19, v=-1800}}, time=3}
We["11041010"]={id=11041010, name="剑荡·破", des="", path="", valueList={{k=19, v=-2000}}, time=3}
We["11042001"]={id=11042001, name="剑御·护", des="", path="buff_yunxuan.jpg", time=0.5}
We["11042002"]={id=11042002, name="剑御·护", des="", path="buff_yunxuan.jpg", time=1}
We["11042003"]={id=11042003, name="剑御·护", des="", path="buff_yunxuan.jpg", time=1.5}
We["11042004"]={id=11042004, name="剑御·护", des="", path="buff_yunxuan.jpg", time=2}
We["11042005"]={id=11042005, name="剑御·护", des="", path="buff_yunxuan.jpg", time=2.5}
We["11042006"]={id=11042006, name="剑御·护", des="", path="buff_yunxuan.jpg", time=3}
We["11043001"]={id=11043001, name="剑心·攻", des="", path="", valueList={{k=111, v=600}}, time=15}
We["11043002"]={id=11043002, name="剑心·攻", des="", path="", valueList={{k=111, v=1200}}, time=15}
We["11043003"]={id=11043003, name="剑心·攻", des="", path="", valueList={{k=111, v=1800}}, time=15}
We["11043004"]={id=11043004, name="剑心·攻", des="", path="", valueList={{k=111, v=2400}}, time=15}
We["11043005"]={id=11043005, name="剑心·攻", des="", path="", valueList={{k=111, v=3000}}, time=15}
We["11044001"]={id=11044001, name="剑荡·陨", des="", path="", valueList={{k=99, v=-3500}}, time=5}
We["11044002"]={id=11044002, name="剑荡·陨", des="", path="", valueList={{k=99, v=-4000}}, time=5}
We["11044003"]={id=11044003, name="剑荡·陨", des="", path="", valueList={{k=99, v=-4500}}, time=5}
We["11044004"]={id=11044004, name="剑荡·陨", des="", path="", valueList={{k=99, v=-5000}}, time=5}
We["11044005"]={id=11044005, name="剑荡·陨", des="", path="", valueList={{k=99, v=-5500}}, time=5}
We["11044006"]={id=11044006, name="剑荡·陨", des="", path="", valueList={{k=99, v=-6000}}, time=5}
We["11045001"]={id=11045001, name="剑心·护", des="", path="", valueList={{k=12, v=600}}, time=15}
We["11045002"]={id=11045002, name="剑心·护", des="", path="", valueList={{k=12, v=1200}}, time=15}
We["11045003"]={id=11045003, name="剑心·护", des="", path="", valueList={{k=12, v=1800}}, time=15}
We["11045004"]={id=11045004, name="剑心·护", des="", path="", valueList={{k=12, v=2400}}, time=15}
We["11045005"]={id=11045005, name="剑心·护", des="", path="", valueList={{k=12, v=3000}}, time=15}
We["11049001"]={id=11049001, name="暴击精通", des="", path="", valueList={{k=13, v=100}}, time=3}
We["11049002"]={id=11049002, name="暴击精通", des="", path="", valueList={{k=13, v=200}}, time=3}
We["11049003"]={id=11049003, name="暴击精通", des="", path="", valueList={{k=13, v=300}}, time=3}
We["11049004"]={id=11049004, name="暴击精通", des="", path="", valueList={{k=13, v=400}}, time=3}
We["11049005"]={id=11049005, name="暴击精通", des="", path="", valueList={{k=13, v=500}}, time=3}
We["11049006"]={id=11049006, name="暴击精通", des="", path="", valueList={{k=13, v=600}}, time=3}
We["11049007"]={id=11049007, name="暴击精通", des="", path="", valueList={{k=13, v=700}}, time=3}
We["11049008"]={id=11049008, name="暴击精通", des="", path="", valueList={{k=13, v=800}}, time=3}
We["11049009"]={id=11049009, name="暴击精通", des="", path="", valueList={{k=13, v=900}}, time=3}
We["11049010"]={id=11049010, name="暴击精通", des="", path="", valueList={{k=13, v=1000}}, time=3}
We["11052001"]={id=11052001, name="眩晕精通", des="", path="buff_yunxuan.jpg", time=1}
We["11053001"]={id=11053001, name="眩晕回馈", des="", path="", valueList={{k=25, v=0}}, time=4}
We["11053002"]={id=11053002, name="眩晕回馈", des="", path="", valueList={{k=50, v=0}}, time=4}
We["11053003"]={id=11053003, name="眩晕回馈", des="", path="", valueList={{k=75, v=0}}, time=4}
We["11053004"]={id=11053004, name="眩晕回馈", des="", path="", valueList={{k=100, v=0}}, time=4}
We["11053005"]={id=11053005, name="眩晕回馈", des="", path="", valueList={{k=125, v=0}}, time=4}
We["11053006"]={id=11053006, name="眩晕回馈", des="", path="", valueList={{k=150, v=0}}, time=4}
We["11053007"]={id=11053007, name="眩晕回馈", des="", path="", valueList={{k=175, v=0}}, time=4}
We["11053008"]={id=11053008, name="眩晕回馈", des="", path="", valueList={{k=200, v=0}}, time=4}
We["11053009"]={id=11053009, name="眩晕回馈", des="", path="", valueList={{k=225, v=0}}, time=4}
We["11053010"]={id=11053010, name="眩晕回馈", des="", path="", valueList={{k=250, v=0}}, time=4}
We["11054001"]={id=11054001, name="异状解除", des="", path="", time=1}
We["11054002"]={id=11054002, name="异状解除", des="", path="", time=2}
We["11054003"]={id=11054003, name="异状解除", des="", path="", time=3}
We["11054004"]={id=11054004, name="异状解除", des="", path="", time=4}
We["11054005"]={id=11054005, name="异状解除", des="", path="", time=5}
We["11054006"]={id=11054006, name="异状解除", des="", path="", time=6}
We["11054007"]={id=11054007, name="驱散负面", des="", path="", time=0}
We["11056001"]={id=11056001, name="暴伤增强", des="", path="", valueList={{k=9, v=200}}, time=4}
We["11056002"]={id=11056002, name="暴伤增强", des="", path="", valueList={{k=9, v=400}}, time=4}
We["11056003"]={id=11056003, name="暴伤增强", des="", path="", valueList={{k=9, v=600}}, time=4}
We["11056004"]={id=11056004, name="暴伤增强", des="", path="", valueList={{k=9, v=800}}, time=4}
We["11056005"]={id=11056005, name="暴伤增强", des="", path="", valueList={{k=9, v=1000}}, time=4}
We["11056006"]={id=11056006, name="暴伤增强", des="", path="", valueList={{k=9, v=1200}}, time=4}
We["11056007"]={id=11056007, name="暴伤增强", des="", path="", valueList={{k=9, v=1400}}, time=4}
We["11056008"]={id=11056008, name="暴伤增强", des="", path="", valueList={{k=9, v=1600}}, time=4}
We["11056009"]={id=11056009, name="暴伤增强", des="", path="", valueList={{k=9, v=1800}}, time=4}
We["11056010"]={id=11056010, name="暴伤增强", des="", path="", valueList={{k=9, v=2000}}, time=4}
We["11057001"]={id=11057001, name="暴击减免", des="", path="", valueList={{k=12, v=400}}, time=3}
We["11057002"]={id=11057002, name="暴击减免", des="", path="", valueList={{k=12, v=800}}, time=3}
We["11057003"]={id=11057003, name="暴击减免", des="", path="", valueList={{k=12, v=1200}}, time=3}
We["11057004"]={id=11057004, name="暴击减免", des="", path="", valueList={{k=12, v=1600}}, time=3}
We["11057005"]={id=11057005, name="暴击减免", des="", path="", valueList={{k=12, v=2000}}, time=3}
We["11057006"]={id=11057006, name="暴击减免", des="", path="", valueList={{k=12, v=2400}}, time=3}
We["11058001"]={id=11058001, name="暴击回馈", des="", path="", valueList={{k=18, v=500}}, time=5}
We["11059001"]={id=11059001, name="极致免疫", des="", path="", time=5}
We["11060001"]={id=11060001, name="多重减伤", des="", path="", valueList={{k=12, v=100}}, time=5}
We["11060002"]={id=11060002, name="多重减伤", des="", path="", valueList={{k=12, v=200}}, time=5}
We["11060003"]={id=11060003, name="多重减伤", des="", path="", valueList={{k=12, v=300}}, time=5}
We["11060004"]={id=11060004, name="多重减伤", des="", path="", valueList={{k=12, v=400}}, time=5}
We["11060005"]={id=11060005, name="多重减伤", des="", path="", valueList={{k=12, v=500}}, time=5}
We["11060006"]={id=11060006, name="多重减伤", des="", path="", valueList={{k=12, v=-100}}, time=5}
We["11060007"]={id=11060007, name="多重减伤", des="", path="", valueList={{k=12, v=-200}}, time=5}
We["11060008"]={id=11060008, name="多重减伤", des="", path="", valueList={{k=12, v=-300}}, time=5}
We["11060009"]={id=11060009, name="多重减伤", des="", path="", valueList={{k=12, v=-400}}, time=5}
We["11060010"]={id=11060010, name="多重减伤", des="", path="", valueList={{k=12, v=-500}}, time=5}
We["13001001"]={id=13001001, name="减速", des="", path="", valueList={{k=27, v=3000}}, time=2}
We["13001002"]={id=13001002, name="减速", des="", path="", valueList={{k=27, v=4000}}, time=2}
We["13001003"]={id=13001003, name="减速", des="", path="", valueList={{k=27, v=5000}}, time=2}
We["13001004"]={id=13001004, name="减速", des="", path="", valueList={{k=27, v=6000}}, time=2}
We["13001005"]={id=13001005, name="减速", des="", path="", valueList={{k=27, v=7000}}, time=2}
We["13001006"]={id=13001006, name="减速", des="", path="", valueList={{k=27, v=8000}}, time=2}
We["13002001"]={id=13002001, name="伤害减免提高", des="", path="", valueList={{k=12, v=600}}, time=3}
We["13002002"]={id=13002002, name="伤害减免提高", des="", path="", valueList={{k=12, v=900}}, time=3}
We["13002003"]={id=13002003, name="伤害减免提高", des="", path="", valueList={{k=12, v=1200}}, time=3}
We["13002004"]={id=13002004, name="伤害减免提高", des="", path="", valueList={{k=12, v=1500}}, time=3}
We["13002005"]={id=13002005, name="伤害减免提高", des="", path="", valueList={{k=12, v=1800}}, time=3}
We["13002006"]={id=13002006, name="伤害减免提高", des="", path="", valueList={{k=12, v=2100}}, time=3}
We["13003001"]={id=13003001, name="暴击几率提高", des="", path="", valueList={{k=13, v=400}}, time=3}
We["13003002"]={id=13003002, name="暴击几率提高", des="", path="", valueList={{k=13, v=600}}, time=3}
We["13003003"]={id=13003003, name="暴击几率提高", des="", path="", valueList={{k=13, v=800}}, time=3}
We["13003004"]={id=13003004, name="暴击几率提高", des="", path="", valueList={{k=13, v=1000}}, time=3}
We["13003005"]={id=13003005, name="暴击几率提高", des="", path="", valueList={{k=13, v=1200}}, time=3}
We["13003006"]={id=13003006, name="暴击几率提高", des="", path="", valueList={{k=13, v=1400}}, time=3}
We["13004001"]={id=13004001, name="闪避", des="", path="", valueList={{k=64, v=5000}}, time=2}
We["13004002"]={id=13004002, name="闪避", des="", path="", valueList={{k=64, v=6000}}, time=2}
We["13004003"]={id=13004003, name="闪避", des="", path="", valueList={{k=64, v=7000}}, time=2}
We["13004004"]={id=13004004, name="闪避", des="", path="", valueList={{k=64, v=8000}}, time=2}
We["13004005"]={id=13004005, name="闪避", des="", path="", valueList={{k=64, v=9000}}, time=2}
We["13004006"]={id=13004006, name="闪避", des="", path="", valueList={{k=64, v=10000}}, time=2}
We["14001001"]={id=14001001, name="致死豁免", des="致死伤害豁免", path="buff_wudi.jpg", time=2}
We["15001001"]={id=15001001, name="决斗场攻击加成", des="攻击增加", path="buff_gongji.jpg", valueList={{k=19, v=500}}, time=300}
We["15001002"]={id=15001002, name="决斗场伤害减免", des="PVP受到伤害降低", path="buff_wudi.jpg", valueList={{k=49, v=3000}}, time=300}
