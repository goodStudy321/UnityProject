--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_item_i_pb = require("Protol.p_item_i_pb")
module('Protol.m_bg_alchemy_draw_toc_pb')

M_BG_ALCHEMY_DRAW_TOC = protobuf.Descriptor();
M_BG_ALCHEMY_DRAW_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_BG_ALCHEMY_DRAW_TOC_LUCKY_FIELD = protobuf.FieldDescriptor();
M_BG_ALCHEMY_DRAW_TOC_PRECIOUS_REWARD_FIELD = protobuf.FieldDescriptor();

M_BG_ALCHEMY_DRAW_TOC_ERR_CODE_FIELD.name = "err_code"
M_BG_ALCHEMY_DRAW_TOC_ERR_CODE_FIELD.full_name = ".m_bg_alchemy_draw_toc.err_code"
M_BG_ALCHEMY_DRAW_TOC_ERR_CODE_FIELD.number = 1
M_BG_ALCHEMY_DRAW_TOC_ERR_CODE_FIELD.index = 0
M_BG_ALCHEMY_DRAW_TOC_ERR_CODE_FIELD.label = 1
M_BG_ALCHEMY_DRAW_TOC_ERR_CODE_FIELD.has_default_value = true
M_BG_ALCHEMY_DRAW_TOC_ERR_CODE_FIELD.default_value = 0
M_BG_ALCHEMY_DRAW_TOC_ERR_CODE_FIELD.type = 5
M_BG_ALCHEMY_DRAW_TOC_ERR_CODE_FIELD.cpp_type = 1

M_BG_ALCHEMY_DRAW_TOC_LUCKY_FIELD.name = "lucky"
M_BG_ALCHEMY_DRAW_TOC_LUCKY_FIELD.full_name = ".m_bg_alchemy_draw_toc.lucky"
M_BG_ALCHEMY_DRAW_TOC_LUCKY_FIELD.number = 2
M_BG_ALCHEMY_DRAW_TOC_LUCKY_FIELD.index = 1
M_BG_ALCHEMY_DRAW_TOC_LUCKY_FIELD.label = 1
M_BG_ALCHEMY_DRAW_TOC_LUCKY_FIELD.has_default_value = true
M_BG_ALCHEMY_DRAW_TOC_LUCKY_FIELD.default_value = 0
M_BG_ALCHEMY_DRAW_TOC_LUCKY_FIELD.type = 5
M_BG_ALCHEMY_DRAW_TOC_LUCKY_FIELD.cpp_type = 1

M_BG_ALCHEMY_DRAW_TOC_PRECIOUS_REWARD_FIELD.name = "precious_reward"
M_BG_ALCHEMY_DRAW_TOC_PRECIOUS_REWARD_FIELD.full_name = ".m_bg_alchemy_draw_toc.precious_reward"
M_BG_ALCHEMY_DRAW_TOC_PRECIOUS_REWARD_FIELD.number = 3
M_BG_ALCHEMY_DRAW_TOC_PRECIOUS_REWARD_FIELD.index = 2
M_BG_ALCHEMY_DRAW_TOC_PRECIOUS_REWARD_FIELD.label = 1
M_BG_ALCHEMY_DRAW_TOC_PRECIOUS_REWARD_FIELD.has_default_value = false
M_BG_ALCHEMY_DRAW_TOC_PRECIOUS_REWARD_FIELD.default_value = nil
M_BG_ALCHEMY_DRAW_TOC_PRECIOUS_REWARD_FIELD.message_type = p_item_i_pb.P_ITEM_I
M_BG_ALCHEMY_DRAW_TOC_PRECIOUS_REWARD_FIELD.type = 11
M_BG_ALCHEMY_DRAW_TOC_PRECIOUS_REWARD_FIELD.cpp_type = 10

M_BG_ALCHEMY_DRAW_TOC.name = "m_bg_alchemy_draw_toc"
M_BG_ALCHEMY_DRAW_TOC.full_name = ".m_bg_alchemy_draw_toc"
M_BG_ALCHEMY_DRAW_TOC.nested_types = {}
M_BG_ALCHEMY_DRAW_TOC.enum_types = {}
M_BG_ALCHEMY_DRAW_TOC.fields = {M_BG_ALCHEMY_DRAW_TOC_ERR_CODE_FIELD, M_BG_ALCHEMY_DRAW_TOC_LUCKY_FIELD, M_BG_ALCHEMY_DRAW_TOC_PRECIOUS_REWARD_FIELD}
M_BG_ALCHEMY_DRAW_TOC.is_extendable = false
M_BG_ALCHEMY_DRAW_TOC.extensions = {}

m_bg_alchemy_draw_toc = protobuf.Message(M_BG_ALCHEMY_DRAW_TOC)

