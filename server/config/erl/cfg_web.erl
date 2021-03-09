-module(cfg_web).
-include("config.hrl").
-export([find/1]).
?CFG_H
%% ============= 配置内容start ===========
%% 用于路径映射对应的处理模块
%% ?C(Action, {Mod, Method}). %%旧的path
?C("get_db_info", {mod_web_role, get_db_info})                      %% 获取数据库数据
?C("get_role_info", {mod_web_role, get_role_info})                  %% 获取玩家信息
?C("ban_role", {mod_web_role, ban_role})                            %% 玩家封禁相关
?C("ban_words", {mod_web_role, ban_words})                          %% 敏感词禁言
?C("filter_words", {mod_web_role, filter_words})                    %% 屏蔽词
?C("ban_ip_imei", {mod_web_role, ban_ip_imei})                      %% ip、设备封禁相关
?C("mark_insider", {mod_web_role, mark_insider})                    %% 设置内部号
?C("copy_role", {mod_web_role, copy_role})                          %% 拷贝数据copy_role
?C("ban_account", {mod_web_role, ban_account})                      %% 绑定帐号
?C("rename_role", {mod_web_role, rename_role})                      %% 玩家重命名
?C("kick_role", {mod_web_role, kick_role})                      	%% 踢玩家下线

?C("send_role_letter", {mod_web_letter, send_role_letter})          %% 发送玩家信件
?C("send_all_letter", {mod_web_letter, send_all_letter})            %% 发送全服信件
?C("del_letter", {mod_web_letter, del_letter})                      %% 删除全服信件

?C("chat_ban_chat_config", {mod_web_chat, chat_ban_chat_config})    %% 聊天设置
?C("chat_ban_key_word", {mod_web_chat, chat_ban_key_word})          %% 关键词
?C("chat_ban_series", {mod_web_chat, chat_ban_series})              %% 连续发言封禁
?C("chat_ban_private", {mod_web_chat, chat_ban_private})            %% 连续私聊封禁

?C("dismiss_family", {mod_web_family, dismiss_family})              %% 解散仙盟
?C("change_family_notice", {mod_web_family, change_family_notice})  %% 修改仙盟公告
?C("rename_family", {mod_web_family, rename_family})                %% 重命名道庭

?C("update_bg_act", {world_bg_act_server, bg_update_bg_act})                %% 更新后台活动
?C("add_bg_act", {world_bg_act_server, bg_add_bg_act})                      %% 增加后台活动
?C("delete_bg_act", {world_bg_act_server, bg_delete_bg_act})                %% 删除后台活动

?C("info", {mod_web_common, info})                                  %% 请求当前服务器部分状态
?C("reload_common_config", {mod_web_common, reload_common_config})  %% 重新加载common_config的配置
?C("send_notice", {mod_web_common, send_notice})                    %% 发送公告
?C("send_open_notices", {mod_web_common, send_open_notices})        %% 发送开服公告
?C("del_notice", {mod_web_common, del_notice})                      %% 删除公告
?C("set_addict_state", {mod_web_common, set_addict_state})          %% 设置防沉迷状态
?C("send_survey", {mod_web_common, send_survey})                    %% 发送问卷
?C("stop_survey", {mod_web_common, stop_survey})                    %% 停止问卷
?C("auth_switch", {mod_web_common, auth_switch})                    %% 注册开关状态
?C("send_junhai_gift", {mod_web_common, send_junhai_gift})          %% 发放君海礼包
?C("send_support_info", {mod_web_common, send_support_info})        %% 扶持号推送
?C("send_merge_info", {mod_web_common, send_merge_info})            %% 推送合服映射
?C("ban_rename_action", {mod_web_common, ban_rename_action})        %% 禁止重名行为

?C("pay", {mod_web_pay, pay})                                       %% 充值
?C("gm_pay_gold", {mod_web_pay, gm_pay_gold})                       %% GM赠送充值元宝
?C("simulate_pay", {mod_web_pay, simulate_pay})                     %% 模拟充值接口


?C(andriod_pay_url, "/index/Junhai/paidCallBack")                   %% 君海安卓-支付回调地址
?C(ios_pay_url, "/index/Junhai/iosPaidCallBack")                    %% 君海IOS-支付回调地址
?C(iqiyi_ios_pay_url, "/index/Iqiyi/paidCallBack")                  %% 爱奇艺IOS-支付回调地址
?C(sq_ios_pay_url, "/index/Shenqi/paidCallBack")                    %% 神起IOS-支付回调地址
?C(mushao_ios_pay_url, "/index/Mushao/paidCallBack")                %% 木勺IOS-支付回调地址
?C(youjing_ios_pay_url, "/index/Quicksdk/yjPaidCallBack")           %% 游境IOS-支付回调地址
?C(zhangyou_ios_pay_url, "/index/Quicksdk/zyPaidCallBack")          %% 掌游IOS-支付回调地址

?C(init_data_url, "/index/index/chatInitialize")                    %% 初始化关键字、敏感词接口
?C(init_merge_server_url, "/index/index/mergeInitialize")           %% 合服数据初始化接口
?C(activation_code_url, "/index/ActivationCode/get")                %% 激活码地址
?C(bg_act_url, "/index/index/activity")                             %% 后台活动调用接口
?C(topology_url, "/index/index/regionIp")                           %% 获取IP拓扑接口
?C(chat_upload_url, "/index/Ban/autoban")                           %% 封禁调用接口
?C(sms_url, "/index/index/sendGameSms")                             %% 短信接口
?C(become_insider_url, "/index/index/becomeinsider")                %% 成为内部号
?C(equipment_tourist_time_url, "/index/index/tourist")              %% 防沉迷游客设备时间
?C(banRole_url, "/index/index/banRole")                             %% 推送因聊天敏感词被禁言的玩家给后台

?C(es_auth, {"elastic", "sTVzRShsfYFFEM9QJA23"})

%% 发送预警短信的手机号码，以,分隔
?C(sms_phone_list, "13650738784")

%% ============== 配置内容end =============
?CFG_E.
