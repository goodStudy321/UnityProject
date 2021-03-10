-module(cfg_dynamic_calc).
-include("config.hrl").
-export[find/1].
?CFG_H

?C(270001, {c_dynamic_calc,270001,"九幽第1波【单人】",1,1,1000,0,300,0,0,200,80})
?C(270002, {c_dynamic_calc,270002,"九幽第2波【单人】",1,1,1000,0,360,0,0,200,100})
?C(270003, {c_dynamic_calc,270003,"九幽第3波【单人】",1,1,1000,0,450,0,0,200,110})
?C(291001, {c_dynamic_calc,291001,"守卫仙盟-小怪1波",0,100,1000,0,2100,0,720,200,30000})
?C(291002, {c_dynamic_calc,291002,"守卫仙盟-小怪2波",0,100,1000,0,4200,0,750,200,30000})
?C(291003, {c_dynamic_calc,291003,"守卫仙盟-小怪3波",0,100,1000,0,6300,0,780,200,30000})
?C(291004, {c_dynamic_calc,291004,"守卫仙盟-小怪4波",0,100,1000,0,8400,0,810,200,30000})
?C(291005, {c_dynamic_calc,291005,"守卫仙盟-小怪5波",0,100,1000,0,10500,0,840,200,30000})
?C(291006, {c_dynamic_calc,291006,"守卫仙盟-小怪6波",0,100,1000,0,12600,0,870,200,30000})
?C(291007, {c_dynamic_calc,291007,"守卫仙盟-小怪7波",0,100,1000,0,14700,0,900,200,30000})
?C(291008, {c_dynamic_calc,291008,"守卫仙盟-小怪8波",0,100,1000,0,16800,0,930,200,30000})
?C(291009, {c_dynamic_calc,291009,"守卫仙盟-BOSS 1波",0,100,1000,0,12600,0,3600,200,100000})
?C(291010, {c_dynamic_calc,291010,"守卫仙盟-BOSS 2波",0,100,1000,0,25200,0,3600,200,100000})
?C(291011, {c_dynamic_calc,291011,"守卫仙盟-BOSS 3波",0,100,1000,0,37800,0,3600,200,100000})
?C(291012, {c_dynamic_calc,291012,"守卫仙盟-BOSS 4波",0,100,1000,0,50400,0,3600,200,100000})
?C(291013, {c_dynamic_calc,291013,"守卫仙盟-BOSS 5波",0,100,1000,0,63000,0,4725,200,100000})
?C(291014, {c_dynamic_calc,291014,"守卫仙盟-BOSS 6波",0,100,1000,0,75600,0,4725,200,100000})
?C(291015, {c_dynamic_calc,291015,"守卫仙盟-BOSS 7波",0,100,1000,0,88200,0,4725,200,100000})
?C(291016, {c_dynamic_calc,291016,"守卫仙盟-BOSS 8波",0,100,1000,0,100800,0,4725,200,100000})
?C(291017, {c_dynamic_calc,291017,"守卫仙盟-偷袭怪",0,100,1000,0,800,0,1500,200,100000})
?C(200196, {c_dynamic_calc,200196,"守卫仙盟-左边Npc",0,100,1000,0,15000,0,0,0,0})
?C(200197, {c_dynamic_calc,200197,"守卫仙盟-右边npc",0,100,1000,0,15000,0,0,0,0})
?C(200198, {c_dynamic_calc,200198,"守卫仙盟-中间npc",0,100,1000,0,20000,0,0,0,0})
?C(203001, {c_dynamic_calc,203001,"妖魔岭buff怪",0,55,1000,0,600,0,1500,200,0})
?C(203002, {c_dynamic_calc,203002,"妖魔岭buff怪",0,55,1000,0,600,0,1500,200,0})
?C(203003, {c_dynamic_calc,203003,"妖魔岭buff怪",0,55,1000,0,600,0,1500,200,0})
?C(203004, {c_dynamic_calc,203004,"妖魔岭-小怪",0,55,1000,0,300,0,500,200,0})
?C(203005, {c_dynamic_calc,203005,"妖魔岭-小怪",0,55,1000,0,300,0,500,200,0})
?C(203006, {c_dynamic_calc,203006,"鬼王殿-boss",0,55,1000,0,2500,0,3000,200,0})
?C(203007, {c_dynamic_calc,203007,"鬼王殿-小怪",0,55,1000,0,150,0,500,200,0})
?C(203008, {c_dynamic_calc,203008,"魔龙洞窟-boss",0,55,1000,0,3000,0,600,200,0})
?C(203009, {c_dynamic_calc,203009,"海源狂袭-小怪第一波",0,55,1000,0,150,0,500,200,0})
?C(203010, {c_dynamic_calc,203010,"海源狂袭-小怪第一波",0,55,1000,0,225,0,500,200,0})
?C(203011, {c_dynamic_calc,203011,"海源狂袭-boss第一波",0,55,1000,0,900,0,1500,200,0})
?C(203012, {c_dynamic_calc,203012,"海源狂袭-小怪第二波",0,55,1000,0,180,0,500,200,0})
?C(203013, {c_dynamic_calc,203013,"海源狂袭-小怪第二波",0,55,1000,0,255,0,500,200,0})
?C(203014, {c_dynamic_calc,203014,"海源狂袭-boss第二波",0,55,1000,0,1200,0,1500,200,0})
?C(203015, {c_dynamic_calc,203015,"海源狂袭-小怪第三波",0,55,1000,0,225,0,500,200,0})
?C(203016, {c_dynamic_calc,203016,"海源狂袭-小怪第三波",0,55,1000,0,300,0,500,200,0})
?C(203017, {c_dynamic_calc,203017,"海源狂袭-boss第三波",0,55,1000,0,1500,0,1500,200,0})
?C(203018, {c_dynamic_calc,203018,"海源狂袭-NPC",0,55,1000,0,45045,0,5000,200,0})
?C(203019, {c_dynamic_calc,203019,"海源狂袭-守卫",0,55,1000,0,45045,0,2500,200,0})
?C(270201, {c_dynamic_calc,270201,"0-309仙魂副本1波小怪",0,250,1000,0,1000,0,0,0,0})
?C(270202, {c_dynamic_calc,270202,"0-309仙魂副本2波小怪",0,250,1000,0,1200,0,0,0,0})
?C(270203, {c_dynamic_calc,270203,"0-309仙魂副本3波小怪",0,250,1000,0,1400,0,0,0,0})
?C(270204, {c_dynamic_calc,270204,"0-309仙魂副本4波小怪",0,250,1000,0,1600,0,0,0,0})
?C(270205, {c_dynamic_calc,270205,"0-309仙魂副本5波小怪",0,250,1000,0,1800,0,0,0,0})
?C(270206, {c_dynamic_calc,270206,"0-309仙魂副本6波小怪",0,250,1000,0,2000,0,0,0,0})
?C(270207, {c_dynamic_calc,270207,"0-309仙魂副本1波Boss",0,250,1000,0,10000,0,0,0,0})
?C(270208, {c_dynamic_calc,270208,"0-309仙魂副本2波Boss",0,250,1000,0,11000,0,0,0,0})
?C(270209, {c_dynamic_calc,270209,"0-309仙魂副本3波Boss",0,250,1000,0,12000,0,0,0,0})
?C(270210, {c_dynamic_calc,270210,"0-309仙魂副本4波Boss",0,250,1000,0,13000,0,0,0,0})
?C(270211, {c_dynamic_calc,270211,"0-309仙魂副本5波Boss",0,250,1000,0,14000,0,0,0,0})
?C(270212, {c_dynamic_calc,270212,"0-309仙魂副本6波Boss",0,250,1000,0,15000,0,0,0,0})
?C(270213, {c_dynamic_calc,270213,"0-309仙魂副本召唤神兽",0,250,1000,0,2000,0,0,0,0})
?C(270214, {c_dynamic_calc,270214,"仙魂副本守卫1",0,250,1000,0,5000,150,0,0,0})
?C(270215, {c_dynamic_calc,270215,"仙魂副本守卫2",0,250,1000,0,5000,75,0,0,0})
?C(270216, {c_dynamic_calc,270216,"仙魂副本守卫3",0,250,1000,0,5000,50,0,0,0})
?C(270217, {c_dynamic_calc,270217,"310-319仙魂副本1波小怪",0,250,1000,0,1000,0,0,0,0})
?C(270218, {c_dynamic_calc,270218,"310-319仙魂副本2波小怪",0,250,1000,0,1200,0,0,0,0})
?C(270219, {c_dynamic_calc,270219,"310-319仙魂副本3波小怪",0,250,1000,0,1400,0,0,0,0})
?C(270220, {c_dynamic_calc,270220,"310-319仙魂副本4波小怪",0,250,1000,0,1600,0,0,0,0})
?C(270221, {c_dynamic_calc,270221,"310-319仙魂副本5波小怪",0,250,1000,0,1800,0,0,0,0})
?C(270222, {c_dynamic_calc,270222,"310-319仙魂副本6波小怪",0,250,1000,0,2000,0,0,0,0})
?C(270223, {c_dynamic_calc,270223,"310-319仙魂副本1波Boss",0,250,1000,0,10000,0,0,0,0})
?C(270224, {c_dynamic_calc,270224,"310-319仙魂副本2波Boss",0,250,1000,0,11000,0,0,0,0})
?C(270225, {c_dynamic_calc,270225,"310-319仙魂副本3波Boss",0,250,1000,0,12000,0,0,0,0})
?C(270226, {c_dynamic_calc,270226,"310-319仙魂副本4波Boss",0,250,1000,0,13000,0,0,0,0})
?C(270227, {c_dynamic_calc,270227,"310-319仙魂副本5波Boss",0,250,1000,0,14000,0,0,0,0})
?C(270228, {c_dynamic_calc,270228,"310-319仙魂副本6波Boss",0,250,1000,0,15000,0,0,0,0})
?C(270229, {c_dynamic_calc,270229,"310-319仙魂副本召唤神兽",0,250,1000,0,2000,0,0,0,0})
?C(270230, {c_dynamic_calc,270230,"320-339仙魂副本1波小怪",0,250,1000,0,1000,0,0,0,0})
?C(270231, {c_dynamic_calc,270231,"320-339仙魂副本2波小怪",0,250,1000,0,1200,0,0,0,0})
?C(270232, {c_dynamic_calc,270232,"320-339仙魂副本3波小怪",0,250,1000,0,1400,0,0,0,0})
?C(270233, {c_dynamic_calc,270233,"320-339仙魂副本4波小怪",0,250,1000,0,1600,0,0,0,0})
?C(270234, {c_dynamic_calc,270234,"320-339仙魂副本5波小怪",0,250,1000,0,1800,0,0,0,0})
?C(270235, {c_dynamic_calc,270235,"320-339仙魂副本6波小怪",0,250,1000,0,2000,0,0,0,0})
?C(270236, {c_dynamic_calc,270236,"320-339仙魂副本1波Boss",0,250,1000,0,10000,0,0,0,0})
?C(270237, {c_dynamic_calc,270237,"320-339仙魂副本2波Boss",0,250,1000,0,11000,0,0,0,0})
?C(270238, {c_dynamic_calc,270238,"320-339仙魂副本3波Boss",0,250,1000,0,12000,0,0,0,0})
?C(270239, {c_dynamic_calc,270239,"320-339仙魂副本4波Boss",0,250,1000,0,13000,0,0,0,0})
?C(270240, {c_dynamic_calc,270240,"320-339仙魂副本5波Boss",0,250,1000,0,14000,0,0,0,0})
?C(270241, {c_dynamic_calc,270241,"320-339仙魂副本6波Boss",0,250,1000,0,15000,0,0,0,0})
?C(270242, {c_dynamic_calc,270242,"320-339仙魂副本召唤神兽",0,250,1000,0,2000,0,0,0,0})
?C(270243, {c_dynamic_calc,270243,"340-379仙魂副本1波小怪",0,250,1000,0,1000,0,0,0,0})
?C(270244, {c_dynamic_calc,270244,"340-379仙魂副本2波小怪",0,250,1000,0,1200,0,0,0,0})
?C(270245, {c_dynamic_calc,270245,"340-379仙魂副本3波小怪",0,250,1000,0,1400,0,0,0,0})
?C(270246, {c_dynamic_calc,270246,"340-379仙魂副本4波小怪",0,250,1000,0,1600,0,0,0,0})
?C(270247, {c_dynamic_calc,270247,"340-379仙魂副本5波小怪",0,250,1000,0,1800,0,0,0,0})
?C(270248, {c_dynamic_calc,270248,"340-379仙魂副本6波小怪",0,250,1000,0,2000,0,0,0,0})
?C(270249, {c_dynamic_calc,270249,"340-379仙魂副本1波Boss",0,250,1000,0,10000,0,0,0,0})
?C(270250, {c_dynamic_calc,270250,"340-379仙魂副本2波Boss",0,250,1000,0,11000,0,0,0,0})
?C(270251, {c_dynamic_calc,270251,"340-379仙魂副本3波Boss",0,250,1000,0,12000,0,0,0,0})
?C(270252, {c_dynamic_calc,270252,"340-379仙魂副本4波Boss",0,250,1000,0,13000,0,0,0,0})
?C(270253, {c_dynamic_calc,270253,"340-379仙魂副本5波Boss",0,250,1000,0,14000,0,0,0,0})
?C(270254, {c_dynamic_calc,270254,"340-379仙魂副本6波Boss",0,250,1000,0,15000,0,0,0,0})
?C(270255, {c_dynamic_calc,270255,"340-379仙魂副本召唤神兽",0,250,1000,0,2000,0,0,0,0})
?C(270256, {c_dynamic_calc,270256,"380-419仙魂副本1波小怪",0,250,1000,0,1000,0,0,0,0})
?C(270257, {c_dynamic_calc,270257,"380-419仙魂副本2波小怪",0,250,1000,0,1200,0,0,0,0})
?C(270258, {c_dynamic_calc,270258,"380-419仙魂副本3波小怪",0,250,1000,0,1400,0,0,0,0})
?C(270259, {c_dynamic_calc,270259,"380-419仙魂副本4波小怪",0,250,1000,0,1600,0,0,0,0})
?C(270260, {c_dynamic_calc,270260,"380-419仙魂副本5波小怪",0,250,1000,0,1800,0,0,0,0})
?C(270261, {c_dynamic_calc,270261,"380-419仙魂副本6波小怪",0,250,1000,0,2000,0,0,0,0})
?C(270262, {c_dynamic_calc,270262,"380-419仙魂副本1波Boss",0,250,1000,0,10000,0,0,0,0})
?C(270263, {c_dynamic_calc,270263,"380-419仙魂副本2波Boss",0,250,1000,0,11000,0,0,0,0})
?C(270264, {c_dynamic_calc,270264,"380-419仙魂副本3波Boss",0,250,1000,0,12000,0,0,0,0})
?C(270265, {c_dynamic_calc,270265,"380-419仙魂副本4波Boss",0,250,1000,0,13000,0,0,0,0})
?C(270266, {c_dynamic_calc,270266,"380-419仙魂副本5波Boss",0,250,1000,0,14000,0,0,0,0})
?C(270267, {c_dynamic_calc,270267,"380-419仙魂副本6波Boss",0,250,1000,0,15000,0,0,0,0})
?C(270268, {c_dynamic_calc,270268,"380-419仙魂副本召唤神兽",0,250,1000,0,2000,0,0,0,0})
?C(270269, {c_dynamic_calc,270269,"420-459仙魂副本1波小怪",0,250,1000,0,1000,0,0,0,0})
?C(270270, {c_dynamic_calc,270270,"420-459仙魂副本2波小怪",0,250,1000,0,1200,0,0,0,0})
?C(270271, {c_dynamic_calc,270271,"420-459仙魂副本3波小怪",0,250,1000,0,1400,0,0,0,0})
?C(270272, {c_dynamic_calc,270272,"420-459仙魂副本4波小怪",0,250,1000,0,1600,0,0,0,0})
?C(270273, {c_dynamic_calc,270273,"420-459仙魂副本5波小怪",0,250,1000,0,1800,0,0,0,0})
?C(270274, {c_dynamic_calc,270274,"420-459仙魂副本6波小怪",0,250,1000,0,2000,0,0,0,0})
?C(270275, {c_dynamic_calc,270275,"420-459仙魂副本1波Boss",0,250,1000,0,10000,0,0,0,0})
?C(270276, {c_dynamic_calc,270276,"420-459仙魂副本2波Boss",0,250,1000,0,11000,0,0,0,0})
?C(270277, {c_dynamic_calc,270277,"420-459仙魂副本3波Boss",0,250,1000,0,12000,0,0,0,0})
?C(270278, {c_dynamic_calc,270278,"420-459仙魂副本4波Boss",0,250,1000,0,13000,0,0,0,0})
?C(270279, {c_dynamic_calc,270279,"420-459仙魂副本5波Boss",0,250,1000,0,14000,0,0,0,0})
?C(270280, {c_dynamic_calc,270280,"420-459仙魂副本6波Boss",0,250,1000,0,15000,0,0,0,0})
?C(270281, {c_dynamic_calc,270281,"420-459仙魂副本召唤神兽",0,250,1000,0,2000,0,0,0,0})
?C(270282, {c_dynamic_calc,270282,"460-999仙魂副本1波小怪",0,250,1000,0,1000,0,0,0,0})
?C(270283, {c_dynamic_calc,270283,"460-999仙魂副本2波小怪",0,250,1000,0,1200,0,0,0,0})
?C(270284, {c_dynamic_calc,270284,"460-999仙魂副本3波小怪",0,250,1000,0,1400,0,0,0,0})
?C(270285, {c_dynamic_calc,270285,"460-999仙魂副本4波小怪",0,250,1000,0,1600,0,0,0,0})
?C(270286, {c_dynamic_calc,270286,"460-999仙魂副本5波小怪",0,250,1000,0,1800,0,0,0,0})
?C(270287, {c_dynamic_calc,270287,"460-999仙魂副本6波小怪",0,250,1000,0,2000,0,0,0,0})
?C(270288, {c_dynamic_calc,270288,"460-999仙魂副本1波Boss",0,250,1000,0,10000,0,0,0,0})
?C(270289, {c_dynamic_calc,270289,"460-999仙魂副本2波Boss",0,250,1000,0,11000,0,0,0,0})
?C(270290, {c_dynamic_calc,270290,"460-999仙魂副本3波Boss",0,250,1000,0,12000,0,0,0,0})
?C(270291, {c_dynamic_calc,270291,"460-999仙魂副本4波Boss",0,250,1000,0,13000,0,0,0,0})
?C(270292, {c_dynamic_calc,270292,"460-999仙魂副本5波Boss",0,250,1000,0,14000,0,0,0,0})
?C(270293, {c_dynamic_calc,270293,"460-999仙魂副本6波Boss",0,250,1000,0,15000,0,0,0,0})
?C(270294, {c_dynamic_calc,270294,"460-999仙魂副本召唤神兽",0,250,1000,0,2000,0,0,0,0})
?C(270301, {c_dynamic_calc,270301,"仙侣副本第1波怪",0,120,1000,0,1200,0,1000,200,0})
?C(270302, {c_dynamic_calc,270302,"仙侣副本第2波怪",0,120,1000,0,1800,0,1250,200,0})
?C(270303, {c_dynamic_calc,270303,"仙侣副本第3波怪",0,120,1000,0,2400,0,1500,200,0})
?C(270304, {c_dynamic_calc,270304,"仙侣副本Boss",0,120,1000,0,40000,0,3750,200,0})
?C(270305, {c_dynamic_calc,270305,"仙侣副本Buff物件（小）",0,120,1000,0,500,0,0,0,0})
?C(270306, {c_dynamic_calc,270306,"仙侣副本Buff物件（大）",0,120,1000,0,25000,0,0,0,0})
?C(290200, {c_dynamic_calc,290200,"抢亲仙灵",0,120,1000,0,60000,0,7500,200,0})
?C(292001, {c_dynamic_calc,292001,"逍遥神坛",0,1,1000,0,4500,0,800,200,0})
?C(292002, {c_dynamic_calc,292002,"逍遥神坛",0,1,1000,0,4500,0,800,200,0})
?C(292003, {c_dynamic_calc,292003,"逍遥神坛",0,1,1000,0,4500,0,800,200,0})
?C(291020, {c_dynamic_calc,291020,"魔域BOSS",0,100,1000,0,100800,0,8000,200,0})
?C(291021, {c_dynamic_calc,291021,"魔域BOSS",0,100,1000,0,100800,0,8000,200,0})
?C(291022, {c_dynamic_calc,291022,"魔域BOSS",0,100,1000,0,100800,0,8000,200,0})
?CFG_E.