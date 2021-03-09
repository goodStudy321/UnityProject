--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_bg_act_pb = require("Protol.p_bg_act_pb")
module('Protol.m_bg_recharge_toc_pb')

M_BG_RECHARGE_TOC = protobuf.Descriptor();
M_BG_RECHARGE_TOC_INFO_FIELD = protobuf.FieldDescriptor();
M_BG_RECHARGE_TOC_MODEL_FIELD = protobuf.FieldDescriptor();
M_BG_RECHARGE_TOC_FIGHT_FIELD = protobuf.FieldDescriptor();
M_BG_RECHARGE_TOC_SIGH_TITLE_FIELD = protobuf.FieldDescriptor();
M_BG_RECHARGE_TOC_MOD_IMG_FIELD = protobuf.FieldDescriptor();

M_BG_RECHARGE_TOC_INFO_FIELD.name = "info"
M_BG_RECHARGE_TOC_INFO_FIELD.full_name = ".m_bg_recharge_toc.info"
M_BG_RECHARGE_TOC_INFO_FIELD.number = 1
M_BG_RECHARGE_TOC_INFO_FIELD.index = 0
M_BG_RECHARGE_TOC_INFO_FIELD.label = 1
M_BG_RECHARGE_TOC_INFO_FIELD.has_default_value = false
M_BG_RECHARGE_TOC_INFO_FIELD.default_value = nil
M_BG_RECHARGE_TOC_INFO_FIELD.message_type = p_bg_act_pb.P_BG_ACT
M_BG_RECHARGE_TOC_INFO_FIELD.type = 11
M_BG_RECHARGE_TOC_INFO_FIELD.cpp_type = 10

M_BG_RECHARGE_TOC_MODEL_FIELD.name = "model"
M_BG_RECHARGE_TOC_MODEL_FIELD.full_name = ".m_bg_recharge_toc.model"
M_BG_RECHARGE_TOC_MODEL_FIELD.number = 2
M_BG_RECHARGE_TOC_MODEL_FIELD.index = 1
M_BG_RECHARGE_TOC_MODEL_FIELD.label = 1
M_BG_RECHARGE_TOC_MODEL_FIELD.has_default_value = true
M_BG_RECHARGE_TOC_MODEL_FIELD.default_value = 0
M_BG_RECHARGE_TOC_MODEL_FIELD.type = 5
M_BG_RECHARGE_TOC_MODEL_FIELD.cpp_type = 1

M_BG_RECHARGE_TOC_FIGHT_FIELD.name = "fight"
M_BG_RECHARGE_TOC_FIGHT_FIELD.full_name = ".m_bg_recharge_toc.fight"
M_BG_RECHARGE_TOC_FIGHT_FIELD.number = 3
M_BG_RECHARGE_TOC_FIGHT_FIELD.index = 2
M_BG_RECHARGE_TOC_FIGHT_FIELD.label = 1
M_BG_RECHARGE_TOC_FIGHT_FIELD.has_default_value = true
M_BG_RECHARGE_TOC_FIGHT_FIELD.default_value = 0
M_BG_RECHARGE_TOC_FIGHT_FIELD.type = 5
M_BG_RECHARGE_TOC_FIGHT_FIELD.cpp_type = 1

M_BG_RECHARGE_TOC_SIGH_TITLE_FIELD.name = "sigh_title"
M_BG_RECHARGE_TOC_SIGH_TITLE_FIELD.full_name = ".m_bg_recharge_toc.sigh_title"
M_BG_RECHARGE_TOC_SIGH_TITLE_FIELD.number = 4
M_BG_RECHARGE_TOC_SIGH_TITLE_FIELD.index = 3
M_BG_RECHARGE_TOC_SIGH_TITLE_FIELD.label = 1
M_BG_RECHARGE_TOC_SIGH_TITLE_FIELD.has_default_value = false
M_BG_RECHARGE_TOC_SIGH_TITLE_FIELD.default_value = ""
M_BG_RECHARGE_TOC_SIGH_TITLE_FIELD.type = 9
M_BG_RECHARGE_TOC_SIGH_TITLE_FIELD.cpp_type = 9

M_BG_RECHARGE_TOC_MOD_IMG_FIELD.name = "mod_img"
M_BG_RECHARGE_TOC_MOD_IMG_FIELD.full_name = ".m_bg_recharge_toc.mod_img"
M_BG_RECHARGE_TOC_MOD_IMG_FIELD.number = 5
M_BG_RECHARGE_TOC_MOD_IMG_FIELD.index = 4
M_BG_RECHARGE_TOC_MOD_IMG_FIELD.label = 1
M_BG_RECHARGE_TOC_MOD_IMG_FIELD.has_default_value = false
M_BG_RECHARGE_TOC_MOD_IMG_FIELD.default_value = ""
M_BG_RECHARGE_TOC_MOD_IMG_FIELD.type = 9
M_BG_RECHARGE_TOC_MOD_IMG_FIELD.cpp_type = 9

M_BG_RECHARGE_TOC.name = "m_bg_recharge_toc"
M_BG_RECHARGE_TOC.full_name = ".m_bg_recharge_toc"
M_BG_RECHARGE_TOC.nested_types = {}
M_BG_RECHARGE_TOC.enum_types = {}
M_BG_RECHARGE_TOC.fields = {M_BG_RECHARGE_TOC_INFO_FIELD, M_BG_RECHARGE_TOC_MODEL_FIELD, M_BG_RECHARGE_TOC_FIGHT_FIELD, M_BG_RECHARGE_TOC_SIGH_TITLE_FIELD, M_BG_RECHARGE_TOC_MOD_IMG_FIELD}
M_BG_RECHARGE_TOC.is_extendable = false
M_BG_RECHARGE_TOC.extensions = {}

m_bg_recharge_toc = protobuf.Message(M_BG_RECHARGE_TOC)

