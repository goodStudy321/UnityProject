--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_throne_resolve_toc_pb')

M_THRONE_RESOLVE_TOC = protobuf.Descriptor();
M_THRONE_RESOLVE_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_THRONE_RESOLVE_TOC_TOTAL_ESSENCE_FIELD = protobuf.FieldDescriptor();

M_THRONE_RESOLVE_TOC_ERR_CODE_FIELD.name = "err_code"
M_THRONE_RESOLVE_TOC_ERR_CODE_FIELD.full_name = ".m_throne_resolve_toc.err_code"
M_THRONE_RESOLVE_TOC_ERR_CODE_FIELD.number = 1
M_THRONE_RESOLVE_TOC_ERR_CODE_FIELD.index = 0
M_THRONE_RESOLVE_TOC_ERR_CODE_FIELD.label = 1
M_THRONE_RESOLVE_TOC_ERR_CODE_FIELD.has_default_value = true
M_THRONE_RESOLVE_TOC_ERR_CODE_FIELD.default_value = 0
M_THRONE_RESOLVE_TOC_ERR_CODE_FIELD.type = 5
M_THRONE_RESOLVE_TOC_ERR_CODE_FIELD.cpp_type = 1

M_THRONE_RESOLVE_TOC_TOTAL_ESSENCE_FIELD.name = "total_essence"
M_THRONE_RESOLVE_TOC_TOTAL_ESSENCE_FIELD.full_name = ".m_throne_resolve_toc.total_essence"
M_THRONE_RESOLVE_TOC_TOTAL_ESSENCE_FIELD.number = 2
M_THRONE_RESOLVE_TOC_TOTAL_ESSENCE_FIELD.index = 1
M_THRONE_RESOLVE_TOC_TOTAL_ESSENCE_FIELD.label = 1
M_THRONE_RESOLVE_TOC_TOTAL_ESSENCE_FIELD.has_default_value = true
M_THRONE_RESOLVE_TOC_TOTAL_ESSENCE_FIELD.default_value = 0
M_THRONE_RESOLVE_TOC_TOTAL_ESSENCE_FIELD.type = 5
M_THRONE_RESOLVE_TOC_TOTAL_ESSENCE_FIELD.cpp_type = 1

M_THRONE_RESOLVE_TOC.name = "m_throne_resolve_toc"
M_THRONE_RESOLVE_TOC.full_name = ".m_throne_resolve_toc"
M_THRONE_RESOLVE_TOC.nested_types = {}
M_THRONE_RESOLVE_TOC.enum_types = {}
M_THRONE_RESOLVE_TOC.fields = {M_THRONE_RESOLVE_TOC_ERR_CODE_FIELD, M_THRONE_RESOLVE_TOC_TOTAL_ESSENCE_FIELD}
M_THRONE_RESOLVE_TOC.is_extendable = false
M_THRONE_RESOLVE_TOC.extensions = {}

m_throne_resolve_toc = protobuf.Message(M_THRONE_RESOLVE_TOC)

