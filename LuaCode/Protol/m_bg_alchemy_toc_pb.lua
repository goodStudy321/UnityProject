--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_bg_act_pb = require("Protol.p_bg_act_pb")
local p_item_i_pb = require("Protol.p_item_i_pb")
module('Protol.m_bg_alchemy_toc_pb')

M_BG_ALCHEMY_TOC = protobuf.Descriptor();
M_BG_ALCHEMY_TOC_INFO_FIELD = protobuf.FieldDescriptor();
M_BG_ALCHEMY_TOC_PRICE_FIELD = protobuf.FieldDescriptor();
M_BG_ALCHEMY_TOC_MONEY_FIELD = protobuf.FieldDescriptor();
M_BG_ALCHEMY_TOC_LUCKY_FIELD = protobuf.FieldDescriptor();
M_BG_ALCHEMY_TOC_FULL_LUCKY_FIELD = protobuf.FieldDescriptor();
M_BG_ALCHEMY_TOC_TIPS_FIELD = protobuf.FieldDescriptor();
M_BG_ALCHEMY_TOC_PICTURE_TIPS_FIELD = protobuf.FieldDescriptor();
M_BG_ALCHEMY_TOC_COMMON_REWARD_FIELD = protobuf.FieldDescriptor();
M_BG_ALCHEMY_TOC_PRECIOUS_REWARD_FIELD = protobuf.FieldDescriptor();

M_BG_ALCHEMY_TOC_INFO_FIELD.name = "info"
M_BG_ALCHEMY_TOC_INFO_FIELD.full_name = ".m_bg_alchemy_toc.info"
M_BG_ALCHEMY_TOC_INFO_FIELD.number = 1
M_BG_ALCHEMY_TOC_INFO_FIELD.index = 0
M_BG_ALCHEMY_TOC_INFO_FIELD.label = 1
M_BG_ALCHEMY_TOC_INFO_FIELD.has_default_value = false
M_BG_ALCHEMY_TOC_INFO_FIELD.default_value = nil
M_BG_ALCHEMY_TOC_INFO_FIELD.message_type = p_bg_act_pb.P_BG_ACT
M_BG_ALCHEMY_TOC_INFO_FIELD.type = 11
M_BG_ALCHEMY_TOC_INFO_FIELD.cpp_type = 10

M_BG_ALCHEMY_TOC_PRICE_FIELD.name = "price"
M_BG_ALCHEMY_TOC_PRICE_FIELD.full_name = ".m_bg_alchemy_toc.price"
M_BG_ALCHEMY_TOC_PRICE_FIELD.number = 2
M_BG_ALCHEMY_TOC_PRICE_FIELD.index = 1
M_BG_ALCHEMY_TOC_PRICE_FIELD.label = 1
M_BG_ALCHEMY_TOC_PRICE_FIELD.has_default_value = true
M_BG_ALCHEMY_TOC_PRICE_FIELD.default_value = 0
M_BG_ALCHEMY_TOC_PRICE_FIELD.type = 5
M_BG_ALCHEMY_TOC_PRICE_FIELD.cpp_type = 1

M_BG_ALCHEMY_TOC_MONEY_FIELD.name = "money"
M_BG_ALCHEMY_TOC_MONEY_FIELD.full_name = ".m_bg_alchemy_toc.money"
M_BG_ALCHEMY_TOC_MONEY_FIELD.number = 3
M_BG_ALCHEMY_TOC_MONEY_FIELD.index = 2
M_BG_ALCHEMY_TOC_MONEY_FIELD.label = 1
M_BG_ALCHEMY_TOC_MONEY_FIELD.has_default_value = true
M_BG_ALCHEMY_TOC_MONEY_FIELD.default_value = 0
M_BG_ALCHEMY_TOC_MONEY_FIELD.type = 5
M_BG_ALCHEMY_TOC_MONEY_FIELD.cpp_type = 1

M_BG_ALCHEMY_TOC_LUCKY_FIELD.name = "lucky"
M_BG_ALCHEMY_TOC_LUCKY_FIELD.full_name = ".m_bg_alchemy_toc.lucky"
M_BG_ALCHEMY_TOC_LUCKY_FIELD.number = 4
M_BG_ALCHEMY_TOC_LUCKY_FIELD.index = 3
M_BG_ALCHEMY_TOC_LUCKY_FIELD.label = 1
M_BG_ALCHEMY_TOC_LUCKY_FIELD.has_default_value = true
M_BG_ALCHEMY_TOC_LUCKY_FIELD.default_value = 0
M_BG_ALCHEMY_TOC_LUCKY_FIELD.type = 5
M_BG_ALCHEMY_TOC_LUCKY_FIELD.cpp_type = 1

M_BG_ALCHEMY_TOC_FULL_LUCKY_FIELD.name = "full_lucky"
M_BG_ALCHEMY_TOC_FULL_LUCKY_FIELD.full_name = ".m_bg_alchemy_toc.full_lucky"
M_BG_ALCHEMY_TOC_FULL_LUCKY_FIELD.number = 5
M_BG_ALCHEMY_TOC_FULL_LUCKY_FIELD.index = 4
M_BG_ALCHEMY_TOC_FULL_LUCKY_FIELD.label = 1
M_BG_ALCHEMY_TOC_FULL_LUCKY_FIELD.has_default_value = true
M_BG_ALCHEMY_TOC_FULL_LUCKY_FIELD.default_value = 0
M_BG_ALCHEMY_TOC_FULL_LUCKY_FIELD.type = 5
M_BG_ALCHEMY_TOC_FULL_LUCKY_FIELD.cpp_type = 1

M_BG_ALCHEMY_TOC_TIPS_FIELD.name = "tips"
M_BG_ALCHEMY_TOC_TIPS_FIELD.full_name = ".m_bg_alchemy_toc.tips"
M_BG_ALCHEMY_TOC_TIPS_FIELD.number = 6
M_BG_ALCHEMY_TOC_TIPS_FIELD.index = 5
M_BG_ALCHEMY_TOC_TIPS_FIELD.label = 1
M_BG_ALCHEMY_TOC_TIPS_FIELD.has_default_value = false
M_BG_ALCHEMY_TOC_TIPS_FIELD.default_value = ""
M_BG_ALCHEMY_TOC_TIPS_FIELD.type = 9
M_BG_ALCHEMY_TOC_TIPS_FIELD.cpp_type = 9

M_BG_ALCHEMY_TOC_PICTURE_TIPS_FIELD.name = "picture_tips"
M_BG_ALCHEMY_TOC_PICTURE_TIPS_FIELD.full_name = ".m_bg_alchemy_toc.picture_tips"
M_BG_ALCHEMY_TOC_PICTURE_TIPS_FIELD.number = 7
M_BG_ALCHEMY_TOC_PICTURE_TIPS_FIELD.index = 6
M_BG_ALCHEMY_TOC_PICTURE_TIPS_FIELD.label = 1
M_BG_ALCHEMY_TOC_PICTURE_TIPS_FIELD.has_default_value = false
M_BG_ALCHEMY_TOC_PICTURE_TIPS_FIELD.default_value = ""
M_BG_ALCHEMY_TOC_PICTURE_TIPS_FIELD.type = 9
M_BG_ALCHEMY_TOC_PICTURE_TIPS_FIELD.cpp_type = 9

M_BG_ALCHEMY_TOC_COMMON_REWARD_FIELD.name = "common_reward"
M_BG_ALCHEMY_TOC_COMMON_REWARD_FIELD.full_name = ".m_bg_alchemy_toc.common_reward"
M_BG_ALCHEMY_TOC_COMMON_REWARD_FIELD.number = 8
M_BG_ALCHEMY_TOC_COMMON_REWARD_FIELD.index = 7
M_BG_ALCHEMY_TOC_COMMON_REWARD_FIELD.label = 3
M_BG_ALCHEMY_TOC_COMMON_REWARD_FIELD.has_default_value = false
M_BG_ALCHEMY_TOC_COMMON_REWARD_FIELD.default_value = {}
M_BG_ALCHEMY_TOC_COMMON_REWARD_FIELD.message_type = p_item_i_pb.P_ITEM_I
M_BG_ALCHEMY_TOC_COMMON_REWARD_FIELD.type = 11
M_BG_ALCHEMY_TOC_COMMON_REWARD_FIELD.cpp_type = 10

M_BG_ALCHEMY_TOC_PRECIOUS_REWARD_FIELD.name = "precious_reward"
M_BG_ALCHEMY_TOC_PRECIOUS_REWARD_FIELD.full_name = ".m_bg_alchemy_toc.precious_reward"
M_BG_ALCHEMY_TOC_PRECIOUS_REWARD_FIELD.number = 9
M_BG_ALCHEMY_TOC_PRECIOUS_REWARD_FIELD.index = 8
M_BG_ALCHEMY_TOC_PRECIOUS_REWARD_FIELD.label = 1
M_BG_ALCHEMY_TOC_PRECIOUS_REWARD_FIELD.has_default_value = false
M_BG_ALCHEMY_TOC_PRECIOUS_REWARD_FIELD.default_value = nil
M_BG_ALCHEMY_TOC_PRECIOUS_REWARD_FIELD.message_type = p_item_i_pb.P_ITEM_I
M_BG_ALCHEMY_TOC_PRECIOUS_REWARD_FIELD.type = 11
M_BG_ALCHEMY_TOC_PRECIOUS_REWARD_FIELD.cpp_type = 10

M_BG_ALCHEMY_TOC.name = "m_bg_alchemy_toc"
M_BG_ALCHEMY_TOC.full_name = ".m_bg_alchemy_toc"
M_BG_ALCHEMY_TOC.nested_types = {}
M_BG_ALCHEMY_TOC.enum_types = {}
M_BG_ALCHEMY_TOC.fields = {M_BG_ALCHEMY_TOC_INFO_FIELD, M_BG_ALCHEMY_TOC_PRICE_FIELD, M_BG_ALCHEMY_TOC_MONEY_FIELD, M_BG_ALCHEMY_TOC_LUCKY_FIELD, M_BG_ALCHEMY_TOC_FULL_LUCKY_FIELD, M_BG_ALCHEMY_TOC_TIPS_FIELD, M_BG_ALCHEMY_TOC_PICTURE_TIPS_FIELD, M_BG_ALCHEMY_TOC_COMMON_REWARD_FIELD, M_BG_ALCHEMY_TOC_PRECIOUS_REWARD_FIELD}
M_BG_ALCHEMY_TOC.is_extendable = false
M_BG_ALCHEMY_TOC.extensions = {}

m_bg_alchemy_toc = protobuf.Message(M_BG_ALCHEMY_TOC)
