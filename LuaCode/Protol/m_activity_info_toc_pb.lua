--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_activity_pb = require("Protol.p_activity_pb")
module('Protol.m_activity_info_toc_pb')

M_ACTIVITY_INFO_TOC = protobuf.Descriptor();
M_ACTIVITY_INFO_TOC_ACTIVITY_LIST_FIELD = protobuf.FieldDescriptor();

M_ACTIVITY_INFO_TOC_ACTIVITY_LIST_FIELD.name = "activity_list"
M_ACTIVITY_INFO_TOC_ACTIVITY_LIST_FIELD.full_name = ".m_activity_info_toc.activity_list"
M_ACTIVITY_INFO_TOC_ACTIVITY_LIST_FIELD.number = 1
M_ACTIVITY_INFO_TOC_ACTIVITY_LIST_FIELD.index = 0
M_ACTIVITY_INFO_TOC_ACTIVITY_LIST_FIELD.label = 3
M_ACTIVITY_INFO_TOC_ACTIVITY_LIST_FIELD.has_default_value = false
M_ACTIVITY_INFO_TOC_ACTIVITY_LIST_FIELD.default_value = {}
M_ACTIVITY_INFO_TOC_ACTIVITY_LIST_FIELD.message_type = p_activity_pb.P_ACTIVITY
M_ACTIVITY_INFO_TOC_ACTIVITY_LIST_FIELD.type = 11
M_ACTIVITY_INFO_TOC_ACTIVITY_LIST_FIELD.cpp_type = 10

M_ACTIVITY_INFO_TOC.name = "m_activity_info_toc"
M_ACTIVITY_INFO_TOC.full_name = ".m_activity_info_toc"
M_ACTIVITY_INFO_TOC.nested_types = {}
M_ACTIVITY_INFO_TOC.enum_types = {}
M_ACTIVITY_INFO_TOC.fields = {M_ACTIVITY_INFO_TOC_ACTIVITY_LIST_FIELD}
M_ACTIVITY_INFO_TOC.is_extendable = false
M_ACTIVITY_INFO_TOC.extensions = {}

m_activity_info_toc = protobuf.Message(M_ACTIVITY_INFO_TOC)
