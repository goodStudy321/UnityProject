--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_kv_pb = require("Protol.p_kv_pb")
module('Protol.m_role_escort_status_toc_pb')

M_ROLE_ESCORT_STATUS_TOC = protobuf.Descriptor();
M_ROLE_ESCORT_STATUS_TOC_VALUE_FIELD = protobuf.FieldDescriptor();

M_ROLE_ESCORT_STATUS_TOC_VALUE_FIELD.name = "value"
M_ROLE_ESCORT_STATUS_TOC_VALUE_FIELD.full_name = ".m_role_escort_status_toc.value"
M_ROLE_ESCORT_STATUS_TOC_VALUE_FIELD.number = 1
M_ROLE_ESCORT_STATUS_TOC_VALUE_FIELD.index = 0
M_ROLE_ESCORT_STATUS_TOC_VALUE_FIELD.label = 3
M_ROLE_ESCORT_STATUS_TOC_VALUE_FIELD.has_default_value = false
M_ROLE_ESCORT_STATUS_TOC_VALUE_FIELD.default_value = {}
M_ROLE_ESCORT_STATUS_TOC_VALUE_FIELD.message_type = p_kv_pb.P_KV
M_ROLE_ESCORT_STATUS_TOC_VALUE_FIELD.type = 11
M_ROLE_ESCORT_STATUS_TOC_VALUE_FIELD.cpp_type = 10

M_ROLE_ESCORT_STATUS_TOC.name = "m_role_escort_status_toc"
M_ROLE_ESCORT_STATUS_TOC.full_name = ".m_role_escort_status_toc"
M_ROLE_ESCORT_STATUS_TOC.nested_types = {}
M_ROLE_ESCORT_STATUS_TOC.enum_types = {}
M_ROLE_ESCORT_STATUS_TOC.fields = {M_ROLE_ESCORT_STATUS_TOC_VALUE_FIELD}
M_ROLE_ESCORT_STATUS_TOC.is_extendable = false
M_ROLE_ESCORT_STATUS_TOC.extensions = {}

m_role_escort_status_toc = protobuf.Message(M_ROLE_ESCORT_STATUS_TOC)

