--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_family_rename_toc_pb')

M_FAMILY_RENAME_TOC = protobuf.Descriptor();
M_FAMILY_RENAME_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_FAMILY_RENAME_TOC_FAMILY_NAME_FIELD = protobuf.FieldDescriptor();

M_FAMILY_RENAME_TOC_ERR_CODE_FIELD.name = "err_code"
M_FAMILY_RENAME_TOC_ERR_CODE_FIELD.full_name = ".m_family_rename_toc.err_code"
M_FAMILY_RENAME_TOC_ERR_CODE_FIELD.number = 1
M_FAMILY_RENAME_TOC_ERR_CODE_FIELD.index = 0
M_FAMILY_RENAME_TOC_ERR_CODE_FIELD.label = 1
M_FAMILY_RENAME_TOC_ERR_CODE_FIELD.has_default_value = true
M_FAMILY_RENAME_TOC_ERR_CODE_FIELD.default_value = 0
M_FAMILY_RENAME_TOC_ERR_CODE_FIELD.type = 5
M_FAMILY_RENAME_TOC_ERR_CODE_FIELD.cpp_type = 1

M_FAMILY_RENAME_TOC_FAMILY_NAME_FIELD.name = "family_name"
M_FAMILY_RENAME_TOC_FAMILY_NAME_FIELD.full_name = ".m_family_rename_toc.family_name"
M_FAMILY_RENAME_TOC_FAMILY_NAME_FIELD.number = 2
M_FAMILY_RENAME_TOC_FAMILY_NAME_FIELD.index = 1
M_FAMILY_RENAME_TOC_FAMILY_NAME_FIELD.label = 1
M_FAMILY_RENAME_TOC_FAMILY_NAME_FIELD.has_default_value = false
M_FAMILY_RENAME_TOC_FAMILY_NAME_FIELD.default_value = ""
M_FAMILY_RENAME_TOC_FAMILY_NAME_FIELD.type = 9
M_FAMILY_RENAME_TOC_FAMILY_NAME_FIELD.cpp_type = 9

M_FAMILY_RENAME_TOC.name = "m_family_rename_toc"
M_FAMILY_RENAME_TOC.full_name = ".m_family_rename_toc"
M_FAMILY_RENAME_TOC.nested_types = {}
M_FAMILY_RENAME_TOC.enum_types = {}
M_FAMILY_RENAME_TOC.fields = {M_FAMILY_RENAME_TOC_ERR_CODE_FIELD, M_FAMILY_RENAME_TOC_FAMILY_NAME_FIELD}
M_FAMILY_RENAME_TOC.is_extendable = false
M_FAMILY_RENAME_TOC.extensions = {}

m_family_rename_toc = protobuf.Message(M_FAMILY_RENAME_TOC)

