--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_kv_pb = require("Protol.p_kv_pb")
module('Protol.m_copy_info_update_toc_pb')

M_COPY_INFO_UPDATE_TOC = protobuf.Descriptor();
M_COPY_INFO_UPDATE_TOC_KV_LIST_FIELD = protobuf.FieldDescriptor();

M_COPY_INFO_UPDATE_TOC_KV_LIST_FIELD.name = "kv_list"
M_COPY_INFO_UPDATE_TOC_KV_LIST_FIELD.full_name = ".m_copy_info_update_toc.kv_list"
M_COPY_INFO_UPDATE_TOC_KV_LIST_FIELD.number = 1
M_COPY_INFO_UPDATE_TOC_KV_LIST_FIELD.index = 0
M_COPY_INFO_UPDATE_TOC_KV_LIST_FIELD.label = 3
M_COPY_INFO_UPDATE_TOC_KV_LIST_FIELD.has_default_value = false
M_COPY_INFO_UPDATE_TOC_KV_LIST_FIELD.default_value = {}
M_COPY_INFO_UPDATE_TOC_KV_LIST_FIELD.message_type = p_kv_pb.P_KV
M_COPY_INFO_UPDATE_TOC_KV_LIST_FIELD.type = 11
M_COPY_INFO_UPDATE_TOC_KV_LIST_FIELD.cpp_type = 10

M_COPY_INFO_UPDATE_TOC.name = "m_copy_info_update_toc"
M_COPY_INFO_UPDATE_TOC.full_name = ".m_copy_info_update_toc"
M_COPY_INFO_UPDATE_TOC.nested_types = {}
M_COPY_INFO_UPDATE_TOC.enum_types = {}
M_COPY_INFO_UPDATE_TOC.fields = {M_COPY_INFO_UPDATE_TOC_KV_LIST_FIELD}
M_COPY_INFO_UPDATE_TOC.is_extendable = false
M_COPY_INFO_UPDATE_TOC.extensions = {}

m_copy_info_update_toc = protobuf.Message(M_COPY_INFO_UPDATE_TOC)
