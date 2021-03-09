%%%-------------------------------------------------------------------
%%% @author chenqinyong
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 八月 2019 20:25
%%%-------------------------------------------------------------------
-author("chenqinyong").

-record(c_equip_collect_info,{
    id,      %% id
    step ,   %% 当前阶数
    quality,            %% 品质
    star,               %% 星级
    item_id,
    suit_num,
    suit_props1,
    suit_props2,
    suit_props3,
    suit_props4,
    skill_reward  %% 技能奖励
}).
