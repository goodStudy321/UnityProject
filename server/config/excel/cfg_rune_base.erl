-module(cfg_rune_base).
-include("config.hrl").
-export[find/1].
?CFG_H

?C(80100001, {c_rune_base,80100001,"符文精华",[1],1,[0]})
?C(80100002, {c_rune_base,80100002,"符文精华",[1],2,[0]})
?C(80100003, {c_rune_base,80100003,"符文精华",[1],3,[0]})
?C(80100004, {c_rune_base,80100004,"符文精华",[1],4,[0]})
?C(80100005, {c_rune_base,80100005,"符文精华",[1],5,[0]})
?C(80100006, {c_rune_base,80100006,"符文精华",[1],5,[0]})
?C(80100011, {c_rune_base,80100011,"攻击符文",[2],1,[0]})
?C(80100012, {c_rune_base,80100012,"攻击符文",[2],2,[0]})
?C(80100013, {c_rune_base,80100013,"攻击符文",[2],3,[0]})
?C(80100014, {c_rune_base,80100014,"攻击符文",[2],4,[0]})
?C(80100015, {c_rune_base,80100015,"攻击符文",[2],5,[0]})
?C(80100021, {c_rune_base,80100021,"防御符文",[3],1,[0]})
?C(80100022, {c_rune_base,80100022,"防御符文",[3],2,[0]})
?C(80100023, {c_rune_base,80100023,"防御符文",[3],3,[0]})
?C(80100024, {c_rune_base,80100024,"防御符文",[3],4,[0]})
?C(80100025, {c_rune_base,80100025,"防御符文",[3],5,[0]})
?C(80100031, {c_rune_base,80100031,"生命符文",[4],1,[0]})
?C(80100032, {c_rune_base,80100032,"生命符文",[4],2,[0]})
?C(80100033, {c_rune_base,80100033,"生命符文",[4],3,[0]})
?C(80100034, {c_rune_base,80100034,"生命符文",[4],4,[0]})
?C(80100035, {c_rune_base,80100035,"生命符文",[4],5,[0]})
?C(80100041, {c_rune_base,80100041,"破甲符文",[5],1,[0]})
?C(80100042, {c_rune_base,80100042,"破甲符文",[5],2,[0]})
?C(80100043, {c_rune_base,80100043,"破甲符文",[5],3,[0]})
?C(80100044, {c_rune_base,80100044,"破甲符文",[5],4,[0]})
?C(80100045, {c_rune_base,80100045,"破甲符文",[5],5,[0]})
?C(80100051, {c_rune_base,80100051,"打怪经验",[6],1,[0]})
?C(80100052, {c_rune_base,80100052,"打怪经验",[6],2,[0]})
?C(80100053, {c_rune_base,80100053,"打怪经验",[6],3,[0]})
?C(80100054, {c_rune_base,80100054,"打怪经验",[6],4,[0]})
?C(80100055, {c_rune_base,80100055,"打怪经验",[6],5,[0]})
?C(80100061, {c_rune_base,80100061,"闪避符文",[7],1,[0]})
?C(80100062, {c_rune_base,80100062,"闪避符文",[7],2,[0]})
?C(80100063, {c_rune_base,80100063,"闪避符文",[7],3,[0]})
?C(80100064, {c_rune_base,80100064,"闪避符文",[7],4,[0]})
?C(80100065, {c_rune_base,80100065,"闪避符文",[7],5,[0]})
?C(80100071, {c_rune_base,80100071,"防具生命",[8],1,[0]})
?C(80100072, {c_rune_base,80100072,"防具生命",[8],2,[0]})
?C(80100073, {c_rune_base,80100073,"防具生命",[8],3,[0]})
?C(80100074, {c_rune_base,80100074,"防具生命",[8],4,[0]})
?C(80100075, {c_rune_base,80100075,"防具生命",[8],5,[0]})
?C(80100081, {c_rune_base,80100081,"命中符文",[9],1,[0]})
?C(80100082, {c_rune_base,80100082,"命中符文",[9],2,[0]})
?C(80100083, {c_rune_base,80100083,"命中符文",[9],3,[0]})
?C(80100084, {c_rune_base,80100084,"命中符文",[9],4,[0]})
?C(80100085, {c_rune_base,80100085,"命中符文",[9],5,[0]})
?C(80100091, {c_rune_base,80100091,"防具防御",[10],1,[0]})
?C(80100092, {c_rune_base,80100092,"防具防御",[10],2,[0]})
?C(80100093, {c_rune_base,80100093,"防具防御",[10],3,[0]})
?C(80100094, {c_rune_base,80100094,"防具防御",[10],4,[0]})
?C(80100095, {c_rune_base,80100095,"防具防御",[10],5,[0]})
?C(80100101, {c_rune_base,80100101,"武器破甲",[11],1,[0]})
?C(80100102, {c_rune_base,80100102,"武器破甲",[11],2,[0]})
?C(80100103, {c_rune_base,80100103,"武器破甲",[11],3,[0]})
?C(80100104, {c_rune_base,80100104,"武器破甲",[11],4,[0]})
?C(80100105, {c_rune_base,80100105,"武器破甲",[11],5,[0]})
?C(80100111, {c_rune_base,80100111,"武器攻击",[12],1,[0]})
?C(80100112, {c_rune_base,80100112,"武器攻击",[12],2,[0]})
?C(80100113, {c_rune_base,80100113,"武器攻击",[12],3,[0]})
?C(80100114, {c_rune_base,80100114,"武器攻击",[12],4,[0]})
?C(80100115, {c_rune_base,80100115,"武器攻击",[12],5,[0]})
?C(80100121, {c_rune_base,80100121,"仙器攻击",[13],1,[0]})
?C(80100122, {c_rune_base,80100122,"仙器攻击",[13],2,[0]})
?C(80100123, {c_rune_base,80100123,"仙器攻击",[13],3,[0]})
?C(80100124, {c_rune_base,80100124,"仙器攻击",[13],4,[0]})
?C(80100125, {c_rune_base,80100125,"仙器攻击",[13],5,[0]})
?C(80100131, {c_rune_base,80100131,"基础破甲",[14],1,[0]})
?C(80100132, {c_rune_base,80100132,"基础破甲",[14],2,[0]})
?C(80100133, {c_rune_base,80100133,"基础破甲",[14],3,[0]})
?C(80100134, {c_rune_base,80100134,"基础破甲",[14],4,[0]})
?C(80100135, {c_rune_base,80100135,"基础破甲",[14],5,[0]})
?C(80100141, {c_rune_base,80100141,"基础生命",[15],1,[0]})
?C(80100142, {c_rune_base,80100142,"基础生命",[15],2,[0]})
?C(80100143, {c_rune_base,80100143,"基础生命",[15],3,[0]})
?C(80100144, {c_rune_base,80100144,"基础生命",[15],4,[0]})
?C(80100145, {c_rune_base,80100145,"基础生命",[15],5,[0]})
?C(80100151, {c_rune_base,80100151,"基础防御",[16],1,[0]})
?C(80100152, {c_rune_base,80100152,"基础防御",[16],2,[0]})
?C(80100153, {c_rune_base,80100153,"基础防御",[16],3,[0]})
?C(80100154, {c_rune_base,80100154,"基础防御",[16],4,[0]})
?C(80100155, {c_rune_base,80100155,"基础防御",[16],5,[0]})
?C(80100161, {c_rune_base,80100161,"基础攻击",[17],1,[0]})
?C(80100162, {c_rune_base,80100162,"基础攻击",[17],2,[0]})
?C(80100163, {c_rune_base,80100163,"基础攻击",[17],3,[0]})
?C(80100164, {c_rune_base,80100164,"基础攻击",[17],4,[0]})
?C(80100165, {c_rune_base,80100165,"基础攻击",[17],5,[0]})
?C(80100174, {c_rune_base,80100174,"仙佑符文",[6,13],4,[0]})
?C(80100175, {c_rune_base,80100175,"仙佑符文",[6,13],5,[0]})
?C(80100184, {c_rune_base,80100184,"长生符文",[4,8],4,[0]})
?C(80100185, {c_rune_base,80100185,"长生符文",[4,8],5,[0]})
?C(80100194, {c_rune_base,80100194,"金刚符文",[3,10],4,[0]})
?C(80100195, {c_rune_base,80100195,"金刚符文",[3,10],5,[0]})
?C(80100204, {c_rune_base,80100204,"灵巧符文",[7,9],4,[0]})
?C(80100205, {c_rune_base,80100205,"灵巧符文",[7,9],5,[0]})
?C(80100214, {c_rune_base,80100214,"杀戮符文",[2,12],4,[0]})
?C(80100215, {c_rune_base,80100215,"杀戮符文",[2,12],5,[0]})
?C(80100224, {c_rune_base,80100224,"粉碎符文",[5,11],4,[0]})
?C(80100225, {c_rune_base,80100225,"粉碎符文",[5,11],5,[0]})
?C(80100234, {c_rune_base,80100234,"圣元符文",[15,16],4,[0]})
?C(80100235, {c_rune_base,80100235,"圣元符文",[15,16],5,[0]})
?C(80100244, {c_rune_base,80100244,"毁灭符文",[14,17],4,[0]})
?C(80100245, {c_rune_base,80100245,"毁灭符文",[14,17],5,[0]})
?C(80100254, {c_rune_base,80100254,"绝对闪避",[18],4,[9]})
?C(80100255, {c_rune_base,80100255,"绝对闪避",[18],5,[9]})
?C(80100264, {c_rune_base,80100264,"绝命一击",[19],4,[10]})
?C(80100265, {c_rune_base,80100265,"绝命一击",[19],5,[10]})
?CFG_E.