--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_bg_act_pb = require("Protol.p_bg_act_pb")
local p_goods_pb = require("Protol.p_goods_pb")
module('Protol.m_role_bg_ttb_toc_pb')

M_ROLE_BG_TTB_TOC = protobuf.Descriptor();
M_ROLE_BG_TTB_TOC_INFO_FIELD = protobuf.FieldDescriptor();
M_ROLE_BG_TTB_TOC_CHECK_POINT_FIELD = protobuf.FieldDescriptor();
M_ROLE_BG_TTB_TOC_ALL_CHECK_POINT_FIELD = protobuf.FieldDescriptor();
M_ROLE_BG_TTB_TOC_BOSS_FIELD = protobuf.FieldDescriptor();
M_ROLE_BG_TTB_TOC_REWARD_FIELD = protobuf.FieldDescriptor();

M_ROLE_BG_TTB_TOC_INFO_FIELD.name = "info"
M_ROLE_BG_TTB_TOC_INFO_FIELD.full_name = ".m_role_bg_ttb_toc.info"
M_ROLE_BG_TTB_TOC_INFO_FIELD.number = 1
M_ROLE_BG_TTB_TOC_INFO_FIELD.index = 0
M_ROLE_BG_TTB_TOC_INFO_FIELD.label = 1
M_ROLE_BG_TTB_TOC_INFO_FIELD.has_default_value = false
M_ROLE_BG_TTB_TOC_INFO_FIELD.default_value = nil
M_ROLE_BG_TTB_TOC_INFO_FIELD.message_type = p_bg_act_pb.P_BG_ACT
M_ROLE_BG_TTB_TOC_INFO_FIELD.type = 11
M_ROLE_BG_TTB_TOC_INFO_FIELD.cpp_type = 10

M_ROLE_BG_TTB_TOC_CHECK_POINT_FIELD.name = "check_point"
M_ROLE_BG_TTB_TOC_CHECK_POINT_FIELD.full_name = ".m_role_bg_ttb_toc.check_point"
M_ROLE_BG_TTB_TOC_CHECK_POINT_FIELD.number = 2
M_ROLE_BG_TTB_TOC_CHECK_POINT_FIELD.index = 1
M_ROLE_BG_TTB_TOC_CHECK_POINT_FIELD.label = 1
M_ROLE_BG_TTB_TOC_CHECK_POINT_FIELD.has_default_value = true
M_ROLE_BG_TTB_TOC_CHECK_POINT_FIELD.default_value = 0
M_ROLE_BG_TTB_TOC_CHECK_POINT_FIELD.type = 5
M_ROLE_BG_TTB_TOC_CHECK_POINT_FIELD.cpp_type = 1

M_ROLE_BG_TTB_TOC_ALL_CHECK_POINT_FIELD.name = "all_check_point"
M_ROLE_BG_TTB_TOC_ALL_CHECK_POINT_FIELD.full_name = ".m_role_bg_ttb_toc.all_check_point"
M_ROLE_BG_TTB_TOC_ALL_CHECK_POINT_FIELD.number = 3
M_ROLE_BG_TTB_TOC_ALL_CHECK_POINT_FIELD.index = 2
M_ROLE_BG_TTB_TOC_ALL_CHECK_POINT_FIELD.label = 1
M_ROLE_BG_TTB_TOC_ALL_CHECK_POINT_FIELD.has_default_value = true
M_ROLE_BG_TTB_TOC_ALL_CHECK_POINT_FIELD.default_value = 0
M_ROLE_BG_TTB_TOC_ALL_CHECK_POINT_FIELD.type = 5
M_ROLE_BG_TTB_TOC_ALL_CHECK_POINT_FIELD.cpp_type = 1

M_ROLE_BG_TTB_TOC_BOSS_FIELD.name = "boss"
M_ROLE_BG_TTB_TOC_BOSS_FIELD.full_name = ".m_role_bg_ttb_toc.boss"
M_ROLE_BG_TTB_TOC_BOSS_FIELD.number = 4
M_ROLE_BG_TTB_TOC_BOSS_FIELD.index = 3
M_ROLE_BG_TTB_TOC_BOSS_FIELD.label = 1
M_ROLE_BG_TTB_TOC_BOSS_FIELD.has_default_value = true
M_ROLE_BG_TTB_TOC_BOSS_FIELD.default_value = 0
M_ROLE_BG_TTB_TOC_BOSS_FIELD.type = 5
M_ROLE_BG_TTB_TOC_BOSS_FIELD.cpp_type = 1

M_ROLE_BG_TTB_TOC_REWARD_FIELD.name = "reward"
M_ROLE_BG_TTB_TOC_REWARD_FIELD.full_name = ".m_role_bg_ttb_toc.reward"
M_ROLE_BG_TTB_TOC_REWARD_FIELD.number = 5
M_ROLE_BG_TTB_TOC_REWARD_FIELD.index = 4
M_ROLE_BG_TTB_TOC_REWARD_FIELD.label = 3
M_ROLE_BG_TTB_TOC_REWARD_FIELD.has_default_value = false
M_ROLE_BG_TTB_TOC_REWARD_FIELD.default_value = {}
M_ROLE_BG_TTB_TOC_REWARD_FIELD.message_type = p_goods_pb.P_GOODS
M_ROLE_BG_TTB_TOC_REWARD_FIELD.type = 11
M_ROLE_BG_TTB_TOC_REWARD_FIELD.cpp_type = 10

M_ROLE_BG_TTB_TOC.name = "m_role_bg_ttb_toc"
M_ROLE_BG_TTB_TOC.full_name = ".m_role_bg_ttb_toc"
M_ROLE_BG_TTB_TOC.nested_types = {}
M_ROLE_BG_TTB_TOC.enum_types = {}
M_ROLE_BG_TTB_TOC.fields = {M_ROLE_BG_TTB_TOC_INFO_FIELD, M_ROLE_BG_TTB_TOC_CHECK_POINT_FIELD, M_ROLE_BG_TTB_TOC_ALL_CHECK_POINT_FIELD, M_ROLE_BG_TTB_TOC_BOSS_FIELD, M_ROLE_BG_TTB_TOC_REWARD_FIELD}
M_ROLE_BG_TTB_TOC.is_extendable = false
M_ROLE_BG_TTB_TOC.extensions = {}

m_role_bg_ttb_toc = protobuf.Message(M_ROLE_BG_TTB_TOC)
