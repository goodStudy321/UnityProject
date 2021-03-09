-module(cfg_warning).
-include("config.hrl").
-export([find/1]).
?CFG_H

%% 充值屏蔽
?C(pay_ban_product_ids, [])

%% 特定行为日志次数限定
?C({item_action_warning, 10000}, 1000)      %% GM获取
?C({item_action_warning, 10001}, 10000)     %% 拾取掉落获得
?C({item_action_warning, 10002}, 1000)      %% 任务获得
?C({item_action_warning, 10003}, 10000)     %% 商店购买获得
?C({item_action_warning, 10005}, 100)       %% 副本扫荡获得
?C({item_action_warning, 10012}, 100)       %% 爬塔副本通关获得
?C({item_action_warning, 10014}, 100)       %% 通关副本获得
?C({item_action_warning, 10101}, 10000)     %% 替换装备获得
?C({item_action_warning, 10102}, 10000)     %% 装备镶嵌替换灵石获得
?C({item_action_warning, 10103}, 10000)     %% 装备拆卸灵石获得
?C({item_action_warning, 10104}, 1000)      %% 装备合成获得
?C({item_action_warning, 10105}, 1000)      %% 合成获得
?C({item_action_warning, 10106}, 1000)      %% 宝石合成获得
?C({item_action_warning, 10108}, 300)       %% 装备寻宝获得
?C({item_action_warning, 10110}, 100)       %% 成就系统获得
?C({item_action_warning, 10112}, 300)       %% 符文寻宝获得
?C({item_action_warning, 10302}, 300)       %% 开启礼包获得
?C({item_action_warning, 10334}, 300)       %% 市场购买获得
?C({item_action_warning, 10336}, 500)       %% 市场上架超时获得
?C({item_action_warning, 10344}, 100)       %% 渡劫任务
?C({item_action_warning, 10347}, 1000)      %% 云购
?C({item_action_warning, 10350}, 100)       %% 七日目标
?C({item_action_warning, 10358}, 300)       %% 符文寻宝获得
?C({item_action_warning, 10360}, 500)       %% 灵饰分解获得
?C({item_action_warning, 10361}, 500)       %% 许愿池抽奖
?C({item_action_warning, 10370}, 10000)     %% 纹印镶嵌替换获得
?C({item_action_warning, 10371}, 10000)     %% 纹印移除获得
?C({item_action_warning, 10372}, 1000)      %% 纹印合成获得
?C({item_action_warning, 10379}, 500)       %% 活跃抽奖
?C({item_action_warning, 10380}, 100)       %% 世界boss
?C({item_action_warning, 10384}, 500)       %% 套装部件分解返回
?C({item_action_warning, 10394}, 500)       %% 吞噬装备获得
?C({item_action_warning, 10395}, 500)       %% 道庭任务获得
?C({item_action_warning, 10396}, 100)       %% 道庭任务帮助获得
?C({item_action_warning, 10397}, 10000)     %% 战灵灵器卸载
?C({item_action_warning, 10398}, 10000)     %% 道庭宝箱获得
?C({item_action_warning, 10401}, 500)       %% 天机系统天机印替换
?C({item_action_warning, 10402}, 500)       %% 天机系统分解获得
?C({item_action_warning, 10406}, 500)       %% 神秘宝藏
?C({item_action_warning, 10408}, 500)       %% 神秘宝藏多次
?C({item_action_warning, 10414}, 200)       %% 限时商店
?C({item_action_warning, 10416}, 1000)      %% 凡品练丹炉
?C({item_action_warning, 10417}, 500)       %% 五行秘境通关获得
?C({item_action_warning, 10420}, 500)       %% 秘境探索（挖矿）获得
?C({item_action_warning, 10423}, 1000)      %% 天机印合成获得
?C({item_action_warning, 10427}, 10000)     %% 幸运上上签获得
?C({item_action_warning, 10428}, 100)       %% 砸蛋累计
?C({item_action_warning, 10429}, 10000)     %% 砸蛋
?C({item_action_warning, 10431}, 10000)     %% 鉴宝活动普通奖励获取
?C({item_action_warning, 10433}, 10000)     %% 黑市鉴宝活动抽取获取
?C({item_action_warning, 10434}, 1000)      %%  拍卖行下架获得
?C({item_action_warning, 10442}, 200)       %%  欢乐宝箱获得
?C({item_action_warning, 10443}, 500)       %%  全城热恋
?C({item_action_warning, 10452}, 500)       %%  月下情人抽奖获得


?C({item_action_warning, 10500}, 500)       %% 竞拍购买获得
?C({item_action_warning, 10502}, 5000)      %% 竞拍流拍返还


%% 道具获取的行为，默认一天不超过X次
?C({item_action_warning, default}, 50)

%% 道具类型一天获取预计最大数量
?C({item_type_warning, 32009}, 10)
?C({item_type_warning, 32010}, 10)
?C({item_type_warning, 32011}, 10)


%% 货币一天预计获得最大数量
?C({asset_type_warning, 2}, 100000)     %% 元宝
?C({asset_type_warning, 3}, 100000)     %% 绑元

?CFG_E.