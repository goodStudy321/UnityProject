--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_role_handbook_resolve_toc_pb')

M_ROLE_HANDBOOK_RESOLVE_TOC = protobuf.Descriptor();
M_ROLE_HANDBOOK_RESOLVE_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_ROLE_HANDBOOK_RESOLVE_TOC_GET_ESSENCE_FIELD = protobuf.FieldDescriptor();

M_ROLE_HANDBOOK_RESOLVE_TOC_ERR_CODE_FIELD.name = "err_code"
M_ROLE_HANDBOOK_RESOLVE_TOC_ERR_CODE_FIELD.full_name = ".m_role_handbook_resolve_toc.err_code"
M_ROLE_HANDBOOK_RESOLVE_TOC_ERR_CODE_FIELD.number = 1
M_ROLE_HANDBOOK_RESOLVE_TOC_ERR_CODE_FIELD.index = 0
M_ROLE_HANDBOOK_RESOLVE_TOC_ERR_CODE_FIELD.label = 1
M_ROLE_HANDBOOK_RESOLVE_TOC_ERR_CODE_FIELD.has_default_value = true
M_ROLE_HANDBOOK_RESOLVE_TOC_ERR_CODE_FIELD.default_value = 0
M_ROLE_HANDBOOK_RESOLVE_TOC_ERR_CODE_FIELD.type = 5
M_ROLE_HANDBOOK_RESOLVE_TOC_ERR_CODE_FIELD.cpp_type = 1

M_ROLE_HANDBOOK_RESOLVE_TOC_GET_ESSENCE_FIELD.name = "get_essence"
M_ROLE_HANDBOOK_RESOLVE_TOC_GET_ESSENCE_FIELD.full_name = ".m_role_handbook_resolve_toc.get_essence"
M_ROLE_HANDBOOK_RESOLVE_TOC_GET_ESSENCE_FIELD.number = 2
M_ROLE_HANDBOOK_RESOLVE_TOC_GET_ESSENCE_FIELD.index = 1
M_ROLE_HANDBOOK_RESOLVE_TOC_GET_ESSENCE_FIELD.label = 1
M_ROLE_HANDBOOK_RESOLVE_TOC_GET_ESSENCE_FIELD.has_default_value = true
M_ROLE_HANDBOOK_RESOLVE_TOC_GET_ESSENCE_FIELD.default_value = 0
M_ROLE_HANDBOOK_RESOLVE_TOC_GET_ESSENCE_FIELD.type = 5
M_ROLE_HANDBOOK_RESOLVE_TOC_GET_ESSENCE_FIELD.cpp_type = 1

M_ROLE_HANDBOOK_RESOLVE_TOC.name = "m_role_handbook_resolve_toc"
M_ROLE_HANDBOOK_RESOLVE_TOC.full_name = ".m_role_handbook_resolve_toc"
M_ROLE_HANDBOOK_RESOLVE_TOC.nested_types = {}
M_ROLE_HANDBOOK_RESOLVE_TOC.enum_types = {}
M_ROLE_HANDBOOK_RESOLVE_TOC.fields = {M_ROLE_HANDBOOK_RESOLVE_TOC_ERR_CODE_FIELD, M_ROLE_HANDBOOK_RESOLVE_TOC_GET_ESSENCE_FIELD}
M_ROLE_HANDBOOK_RESOLVE_TOC.is_extendable = false
M_ROLE_HANDBOOK_RESOLVE_TOC.extensions = {}

m_role_handbook_resolve_toc = protobuf.Message(M_ROLE_HANDBOOK_RESOLVE_TOC)
