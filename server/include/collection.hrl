%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. 六月 2017 15:33
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(COLLECTION_HRL).
-define(COLLECTION_HRL, collection_hrl).
-include("global.hrl").

-define(IS_COLLECT_IS_SHARE(CollectShare), (CollectShare =:= 1)).
-define(IS_FAMILY_AS_CL(Type), (Type =:= 100035)).

-record(c_collection,{
    type_id,
    name,
    collect_time,           %% 采集需要的时间
    dis,                    %% 格子检测范围
    reward,                 %% 采集奖励
    collect_share=0,        %% 采集是否共享
    times=0,                %% 采集次数 0为无限
    broadcast_missions=[]   %% 任务广播过滤
}).

%% 采集物的r结构
-record(r_collection, {
    collect_id,
    collect_name,
    times,                  %% -1为无限制采集
    type_id,
    index_id,               %% 婚礼热度时间到了，会移除对应的采集物
    seq_id,
    born_pos,               %% #r_pos{}
    role_list = []}).

-record(r_collect_role, {
    role_id,                %% role_id
    reduce_rate = 0,        %% 掉血率默认是0(万分比)
    next_reduce_time = 0,   %% 下次掉血时间
    end_time                %% end_time
}).

-endif.