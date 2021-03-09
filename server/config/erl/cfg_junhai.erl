-module(cfg_junhai).
-include("config.hrl").
-export([find/1]).
?CFG_H
%% ============= 配置内容start ===========
?C(game_id, 175)

?C(game_channel_id, 104287)

?C(app_id, 100000385)

?C(app_key, "0ef5712c419e1ba02bba0d62432e4f49")

?C(app_secret, "8bd6c2c4f139e42a2d520ea41b630d70")

?C(node, "https://agent1.ijunhai.com")

?C(pay_sign, "32f59ae5b8016a388a89ecba5d3cb0cd")

%% 君海防沉迷接口
?C(addict_url, "http://agent.ijunhai.com/user/authUserCertification")

%% 国内数据上报地址
?C(data_url, "http://cp-data.ijunhai.com/")

%% 国外数据上报地址
?C(overseas_data_url, "http://overseas-cp-data.itrigirls.com/")

%% ============== 配置内容end =============
?CFG_E.
