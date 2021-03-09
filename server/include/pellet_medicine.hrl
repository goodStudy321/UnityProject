%%%-------------------------------------------------------------------
%%% @author huangxiangrui
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. 七月 2019 20:40
%%%-------------------------------------------------------------------
-author("huangxiangrui").

-ifndef(PELLET_MEDICINE).
-define(PELLET_MEDICINE, pellet_medicine).

-define(PELLET_MEDICINE_TYPE, 1). % 类型，限时

-record(c_pellet_medicine, {
    id,
    type,
    effective_time,         % 有效时间
    confine,                % 境界控制
    upper_limit,            % 上限
    attr1,
    attr2,
    attr3,
    attr4,
    attr5
}).

-endif.