--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_item_i_pb = require("Protol.p_item_i_pb")
local p_kvt_pb = require("Protol.p_kvt_pb")
module('Protol.m_bg_trevi_fountain_draw_toc_pb')

M_BG_TREVI_FOUNTAIN_DRAW_TOC = protobuf.Descriptor();
M_BG_TREVI_FOUNTAIN_DRAW_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_BG_TREVI_FOUNTAIN_DRAW_TOC_INTEGRAL_FIELD = protobuf.FieldDescriptor();
M_BG_TREVI_FOUNTAIN_DRAW_TOC_REWARD_FIELD = protobuf.FieldDescriptor();
M_BG_TREVI_FOUNTAIN_DRAW_TOC_TIMES_FIELD = protobuf.FieldDescriptor();
M_BG_TREVI_FOUNTAIN_DRAW_TOC_BLESS_FIELD = protobuf.FieldDescriptor();
M_BG_TREVI_FOUNTAIN_DRAW_TOC_PRECIOUS_EXIST_FIELD = protobuf.FieldDescriptor();
M_BG_TREVI_FOUNTAIN_DRAW_TOC_UPDATE_LIST_FIELD = protobuf.FieldDescriptor();

M_BG_TREVI_FOUNTAIN_DRAW_TOC_ERR_CODE_FIELD.name = "err_code"
M_BG_TREVI_FOUNTAIN_DRAW_TOC_ERR_CODE_FIELD.full_name = ".m_bg_trevi_fountain_draw_toc.err_code"
M_BG_TREVI_FOUNTAIN_DRAW_TOC_ERR_CODE_FIELD.number = 1
M_BG_TREVI_FOUNTAIN_DRAW_TOC_ERR_CODE_FIELD.index = 0
M_BG_TREVI_FOUNTAIN_DRAW_TOC_ERR_CODE_FIELD.label = 1
M_BG_TREVI_FOUNTAIN_DRAW_TOC_ERR_CODE_FIELD.has_default_value = true
M_BG_TREVI_FOUNTAIN_DRAW_TOC_ERR_CODE_FIELD.default_value = 0
M_BG_TREVI_FOUNTAIN_DRAW_TOC_ERR_CODE_FIELD.type = 5
M_BG_TREVI_FOUNTAIN_DRAW_TOC_ERR_CODE_FIELD.cpp_type = 1

M_BG_TREVI_FOUNTAIN_DRAW_TOC_INTEGRAL_FIELD.name = "integral"
M_BG_TREVI_FOUNTAIN_DRAW_TOC_INTEGRAL_FIELD.full_name = ".m_bg_trevi_fountain_draw_toc.integral"
M_BG_TREVI_FOUNTAIN_DRAW_TOC_INTEGRAL_FIELD.number = 2
M_BG_TREVI_FOUNTAIN_DRAW_TOC_INTEGRAL_FIELD.index = 1
M_BG_TREVI_FOUNTAIN_DRAW_TOC_INTEGRAL_FIELD.label = 1
M_BG_TREVI_FOUNTAIN_DRAW_TOC_INTEGRAL_FIELD.has_default_value = true
M_BG_TREVI_FOUNTAIN_DRAW_TOC_INTEGRAL_FIELD.default_value = 0
M_BG_TREVI_FOUNTAIN_DRAW_TOC_INTEGRAL_FIELD.type = 5
M_BG_TREVI_FOUNTAIN_DRAW_TOC_INTEGRAL_FIELD.cpp_type = 1

M_BG_TREVI_FOUNTAIN_DRAW_TOC_REWARD_FIELD.name = "reward"
M_BG_TREVI_FOUNTAIN_DRAW_TOC_REWARD_FIELD.full_name = ".m_bg_trevi_fountain_draw_toc.reward"
M_BG_TREVI_FOUNTAIN_DRAW_TOC_REWARD_FIELD.number = 3
M_BG_TREVI_FOUNTAIN_DRAW_TOC_REWARD_FIELD.index = 2
M_BG_TREVI_FOUNTAIN_DRAW_TOC_REWARD_FIELD.label = 3
M_BG_TREVI_FOUNTAIN_DRAW_TOC_REWARD_FIELD.has_default_value = false
M_BG_TREVI_FOUNTAIN_DRAW_TOC_REWARD_FIELD.default_value = {}
M_BG_TREVI_FOUNTAIN_DRAW_TOC_REWARD_FIELD.message_type = p_item_i_pb.P_ITEM_I
M_BG_TREVI_FOUNTAIN_DRAW_TOC_REWARD_FIELD.type = 11
M_BG_TREVI_FOUNTAIN_DRAW_TOC_REWARD_FIELD.cpp_type = 10

M_BG_TREVI_FOUNTAIN_DRAW_TOC_TIMES_FIELD.name = "times"
M_BG_TREVI_FOUNTAIN_DRAW_TOC_TIMES_FIELD.full_name = ".m_bg_trevi_fountain_draw_toc.times"
M_BG_TREVI_FOUNTAIN_DRAW_TOC_TIMES_FIELD.number = 4
M_BG_TREVI_FOUNTAIN_DRAW_TOC_TIMES_FIELD.index = 3
M_BG_TREVI_FOUNTAIN_DRAW_TOC_TIMES_FIELD.label = 1
M_BG_TREVI_FOUNTAIN_DRAW_TOC_TIMES_FIELD.has_default_value = true
M_BG_TREVI_FOUNTAIN_DRAW_TOC_TIMES_FIELD.default_value = 0
M_BG_TREVI_FOUNTAIN_DRAW_TOC_TIMES_FIELD.type = 5
M_BG_TREVI_FOUNTAIN_DRAW_TOC_TIMES_FIELD.cpp_type = 1

M_BG_TREVI_FOUNTAIN_DRAW_TOC_BLESS_FIELD.name = "bless"
M_BG_TREVI_FOUNTAIN_DRAW_TOC_BLESS_FIELD.full_name = ".m_bg_trevi_fountain_draw_toc.bless"
M_BG_TREVI_FOUNTAIN_DRAW_TOC_BLESS_FIELD.number = 5
M_BG_TREVI_FOUNTAIN_DRAW_TOC_BLESS_FIELD.index = 4
M_BG_TREVI_FOUNTAIN_DRAW_TOC_BLESS_FIELD.label = 1
M_BG_TREVI_FOUNTAIN_DRAW_TOC_BLESS_FIELD.has_default_value = true
M_BG_TREVI_FOUNTAIN_DRAW_TOC_BLESS_FIELD.default_value = 0
M_BG_TREVI_FOUNTAIN_DRAW_TOC_BLESS_FIELD.type = 5
M_BG_TREVI_FOUNTAIN_DRAW_TOC_BLESS_FIELD.cpp_type = 1

M_BG_TREVI_FOUNTAIN_DRAW_TOC_PRECIOUS_EXIST_FIELD.name = "precious_exist"
M_BG_TREVI_FOUNTAIN_DRAW_TOC_PRECIOUS_EXIST_FIELD.full_name = ".m_bg_trevi_fountain_draw_toc.precious_exist"
M_BG_TREVI_FOUNTAIN_DRAW_TOC_PRECIOUS_EXIST_FIELD.number = 6
M_BG_TREVI_FOUNTAIN_DRAW_TOC_PRECIOUS_EXIST_FIELD.index = 5
M_BG_TREVI_FOUNTAIN_DRAW_TOC_PRECIOUS_EXIST_FIELD.label = 1
M_BG_TREVI_FOUNTAIN_DRAW_TOC_PRECIOUS_EXIST_FIELD.has_default_value = true
M_BG_TREVI_FOUNTAIN_DRAW_TOC_PRECIOUS_EXIST_FIELD.default_value = true
M_BG_TREVI_FOUNTAIN_DRAW_TOC_PRECIOUS_EXIST_FIELD.type = 8
M_BG_TREVI_FOUNTAIN_DRAW_TOC_PRECIOUS_EXIST_FIELD.cpp_type = 7

M_BG_TREVI_FOUNTAIN_DRAW_TOC_UPDATE_LIST_FIELD.name = "update_list"
M_BG_TREVI_FOUNTAIN_DRAW_TOC_UPDATE_LIST_FIELD.full_name = ".m_bg_trevi_fountain_draw_toc.update_list"
M_BG_TREVI_FOUNTAIN_DRAW_TOC_UPDATE_LIST_FIELD.number = 7
M_BG_TREVI_FOUNTAIN_DRAW_TOC_UPDATE_LIST_FIELD.index = 6
M_BG_TREVI_FOUNTAIN_DRAW_TOC_UPDATE_LIST_FIELD.label = 3
M_BG_TREVI_FOUNTAIN_DRAW_TOC_UPDATE_LIST_FIELD.has_default_value = false
M_BG_TREVI_FOUNTAIN_DRAW_TOC_UPDATE_LIST_FIELD.default_value = {}
M_BG_TREVI_FOUNTAIN_DRAW_TOC_UPDATE_LIST_FIELD.message_type = p_kvt_pb.P_KVT
M_BG_TREVI_FOUNTAIN_DRAW_TOC_UPDATE_LIST_FIELD.type = 11
M_BG_TREVI_FOUNTAIN_DRAW_TOC_UPDATE_LIST_FIELD.cpp_type = 10

M_BG_TREVI_FOUNTAIN_DRAW_TOC.name = "m_bg_trevi_fountain_draw_toc"
M_BG_TREVI_FOUNTAIN_DRAW_TOC.full_name = ".m_bg_trevi_fountain_draw_toc"
M_BG_TREVI_FOUNTAIN_DRAW_TOC.nested_types = {}
M_BG_TREVI_FOUNTAIN_DRAW_TOC.enum_types = {}
M_BG_TREVI_FOUNTAIN_DRAW_TOC.fields = {M_BG_TREVI_FOUNTAIN_DRAW_TOC_ERR_CODE_FIELD, M_BG_TREVI_FOUNTAIN_DRAW_TOC_INTEGRAL_FIELD, M_BG_TREVI_FOUNTAIN_DRAW_TOC_REWARD_FIELD, M_BG_TREVI_FOUNTAIN_DRAW_TOC_TIMES_FIELD, M_BG_TREVI_FOUNTAIN_DRAW_TOC_BLESS_FIELD, M_BG_TREVI_FOUNTAIN_DRAW_TOC_PRECIOUS_EXIST_FIELD, M_BG_TREVI_FOUNTAIN_DRAW_TOC_UPDATE_LIST_FIELD}
M_BG_TREVI_FOUNTAIN_DRAW_TOC.is_extendable = false
M_BG_TREVI_FOUNTAIN_DRAW_TOC.extensions = {}

m_bg_trevi_fountain_draw_toc = protobuf.Message(M_BG_TREVI_FOUNTAIN_DRAW_TOC)
