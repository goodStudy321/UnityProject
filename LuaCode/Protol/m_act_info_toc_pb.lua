--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_act_pb = require("Protol.p_act_pb")
module('Protol.m_act_info_toc_pb')

M_ACT_INFO_TOC = protobuf.Descriptor();
M_ACT_INFO_TOC_ACT_LIST_FIELD = protobuf.FieldDescriptor();

M_ACT_INFO_TOC_ACT_LIST_FIELD.name = "act_list"
M_ACT_INFO_TOC_ACT_LIST_FIELD.full_name = ".m_act_info_toc.act_list"
M_ACT_INFO_TOC_ACT_LIST_FIELD.number = 1
M_ACT_INFO_TOC_ACT_LIST_FIELD.index = 0
M_ACT_INFO_TOC_ACT_LIST_FIELD.label = 3
M_ACT_INFO_TOC_ACT_LIST_FIELD.has_default_value = false
M_ACT_INFO_TOC_ACT_LIST_FIELD.default_value = {}
M_ACT_INFO_TOC_ACT_LIST_FIELD.message_type = p_act_pb.P_ACT
M_ACT_INFO_TOC_ACT_LIST_FIELD.type = 11
M_ACT_INFO_TOC_ACT_LIST_FIELD.cpp_type = 10

M_ACT_INFO_TOC.name = "m_act_info_toc"
M_ACT_INFO_TOC.full_name = ".m_act_info_toc"
M_ACT_INFO_TOC.nested_types = {}
M_ACT_INFO_TOC.enum_types = {}
M_ACT_INFO_TOC.fields = {M_ACT_INFO_TOC_ACT_LIST_FIELD}
M_ACT_INFO_TOC.is_extendable = false
M_ACT_INFO_TOC.extensions = {}

m_act_info_toc = protobuf.Message(M_ACT_INFO_TOC)

