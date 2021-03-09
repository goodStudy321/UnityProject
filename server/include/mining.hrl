%%%-------------------------------------------------------------------
%%% @author huangxiangrui
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%% 秘境探索（挖矿）
%%% @end
%%% Created : 29. 七月 2019 20:13
%%%-------------------------------------------------------------------
-author("huangxiangrui").

-ifndef(MINING_HRL).
-define(MINING_HRL, mining_hrl).

-define(NULL, null).

-define(MINING_STATUS_ID, 6582). % 挖矿状态id

-define(MINING_TYPE_PLAIN, 1). % 格子类型
-define(MINING_TYPE_BOSS, 2).

-define(DIR_SAME, -1).          % 相同
-define(DIR_NONE,       2#0000).    % 无方向
-define(DIR_LEFT,       2#0001).    % 左
-define(DIR_RIGHT,      2#0010).    % 右
-define(DIR_TOP,        2#0100).    % 上
-define(DIR_BOTTOM,     2#1000).    % 下
-define(DIR_TOPLEFT,    2#0101).    % 左上
-define(DIR_TOPRIGHT,   2#0110).    % 右上
-define(DIR_BOTTOMLEFT, 2#1001).    % 左下
-define(DIR_BOTTOMRIGHT,2#1010).    % 右下

-define(MINING_PLUNDER_FAIL, 0).    % 掠夺失败
-define(MINING_PLUNDER_SUCCESS, 1). % 掠夺成功

-define(MINING_MAX_LEN, 200).   %% 最多200条掠夺记录

-define(UPDATE_GATHER, 1).
-define(UPDATE_SHIFT, 2).
-define(UPDATE_GOODS, 3).

-define(IS_ROLE_MINING(MingRoleID), (MingRoleID =/= undefined)).

-define(INSPIRE_UPDATE_TYPE_RESET, 1).  %% 每日鼓舞次数重置更新

%% 当前用的方向
-define(TODAY_APPLY, [?DIR_LEFT, ?DIR_TOP, ?DIR_RIGHT, ?DIR_BOTTOM]).

-record(c_mining_lattice,{
    id,
    type,
    quality,                % 品质
    collection_num,         % 采集次数
    collection_time,        % 采集时长
    resource,               % 资源
    chance,                 % 权重
    power,                  % 标准战力
    family_addition         % 道庭加成
}).

-endif.