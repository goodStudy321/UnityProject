--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_kv_pb = require("Protol.p_kv_pb")
module('Protol.m_daily_liveness_toc_pb')

M_DAILY_LIVENESS_TOC = protobuf.Descriptor();
M_DAILY_LIVENESS_TOC_LIVENESS_FIELD = protobuf.FieldDescriptor();
M_DAILY_LIVENESS_TOC_LIST_FIELD = protobuf.FieldDescriptor();

M_DAILY_LIVENESS_TOC_LIVENESS_FIELD.name = "liveness"
M_DAILY_LIVENESS_TOC_LIVENESS_FIELD.full_name = ".m_daily_liveness_toc.liveness"
M_DAILY_LIVENESS_TOC_LIVENESS_FIELD.number = 1
M_DAILY_LIVENESS_TOC_LIVENESS_FIELD.index = 0
M_DAILY_LIVENESS_TOC_LIVENESS_FIELD.label = 1
M_DAILY_LIVENESS_TOC_LIVENESS_FIELD.has_default_value = true
M_DAILY_LIVENESS_TOC_LIVENESS_FIELD.default_value = 0
M_DAILY_LIVENESS_TOC_LIVENESS_FIELD.type = 5
M_DAILY_LIVENESS_TOC_LIVENESS_FIELD.cpp_type = 1

M_DAILY_LIVENESS_TOC_LIST_FIELD.name = "list"
M_DAILY_LIVENESS_TOC_LIST_FIELD.full_name = ".m_daily_liveness_toc.list"
M_DAILY_LIVENESS_TOC_LIST_FIELD.number = 2
M_DAILY_LIVENESS_TOC_LIST_FIELD.index = 1
M_DAILY_LIVENESS_TOC_LIST_FIELD.label = 3
M_DAILY_LIVENESS_TOC_LIST_FIELD.has_default_value = false
M_DAILY_LIVENESS_TOC_LIST_FIELD.default_value = {}
M_DAILY_LIVENESS_TOC_LIST_FIELD.message_type = p_kv_pb.P_KV
M_DAILY_LIVENESS_TOC_LIST_FIELD.type = 11
M_DAILY_LIVENESS_TOC_LIST_FIELD.cpp_type = 10

M_DAILY_LIVENESS_TOC.name = "m_daily_liveness_toc"
M_DAILY_LIVENESS_TOC.full_name = ".m_daily_liveness_toc"
M_DAILY_LIVENESS_TOC.nested_types = {}
M_DAILY_LIVENESS_TOC.enum_types = {}
M_DAILY_LIVENESS_TOC.fields = {M_DAILY_LIVENESS_TOC_LIVENESS_FIELD, M_DAILY_LIVENESS_TOC_LIST_FIELD}
M_DAILY_LIVENESS_TOC.is_extendable = false
M_DAILY_LIVENESS_TOC.extensions = {}

m_daily_liveness_toc = protobuf.Message(M_DAILY_LIVENESS_TOC)

