--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_kvl_pb = require("Protol.p_kvl_pb")
module('Protol.m_bg_act_info_toc_pb')

M_BG_ACT_INFO_TOC = protobuf.Descriptor();
M_BG_ACT_INFO_TOC_UPDATE_LIST_FIELD = protobuf.FieldDescriptor();

M_BG_ACT_INFO_TOC_UPDATE_LIST_FIELD.name = "update_list"
M_BG_ACT_INFO_TOC_UPDATE_LIST_FIELD.full_name = ".m_bg_act_info_toc.update_list"
M_BG_ACT_INFO_TOC_UPDATE_LIST_FIELD.number = 1
M_BG_ACT_INFO_TOC_UPDATE_LIST_FIELD.index = 0
M_BG_ACT_INFO_TOC_UPDATE_LIST_FIELD.label = 3
M_BG_ACT_INFO_TOC_UPDATE_LIST_FIELD.has_default_value = false
M_BG_ACT_INFO_TOC_UPDATE_LIST_FIELD.default_value = {}
M_BG_ACT_INFO_TOC_UPDATE_LIST_FIELD.message_type = p_kvl_pb.P_KVL
M_BG_ACT_INFO_TOC_UPDATE_LIST_FIELD.type = 11
M_BG_ACT_INFO_TOC_UPDATE_LIST_FIELD.cpp_type = 10

M_BG_ACT_INFO_TOC.name = "m_bg_act_info_toc"
M_BG_ACT_INFO_TOC.full_name = ".m_bg_act_info_toc"
M_BG_ACT_INFO_TOC.nested_types = {}
M_BG_ACT_INFO_TOC.enum_types = {}
M_BG_ACT_INFO_TOC.fields = {M_BG_ACT_INFO_TOC_UPDATE_LIST_FIELD}
M_BG_ACT_INFO_TOC.is_extendable = false
M_BG_ACT_INFO_TOC.extensions = {}

m_bg_act_info_toc = protobuf.Message(M_BG_ACT_INFO_TOC)

