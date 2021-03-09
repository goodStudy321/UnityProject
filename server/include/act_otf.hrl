%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 四月 2019 16:29
%%%-------------------------------------------------------------------
-author("WZP").
-ifndef(ACT_OTF_HRL).
-define(ACT_OTF_HRL, act_otf_hrl).

-record(c_otf_reward, {
    score,      %% 灵力
    reward      %% 奖励
}).

-record(c_otf_mission, {
    id,          %%
    score,       %%仙力
    type,        %%任务类型
    param,       %%完成参数
    level,       %%开启等级
    times        %%可完成次数
}).


-endif.