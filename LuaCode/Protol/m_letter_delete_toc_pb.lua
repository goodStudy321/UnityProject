--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_letter_delete_toc_pb')

M_LETTER_DELETE_TOC = protobuf.Descriptor();
M_LETTER_DELETE_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_LETTER_DELETE_TOC_OP_TYPE_FIELD = protobuf.FieldDescriptor();
M_LETTER_DELETE_TOC_ID_LIST_FIELD = protobuf.FieldDescriptor();

M_LETTER_DELETE_TOC_ERR_CODE_FIELD.name = "err_code"
M_LETTER_DELETE_TOC_ERR_CODE_FIELD.full_name = ".m_letter_delete_toc.err_code"
M_LETTER_DELETE_TOC_ERR_CODE_FIELD.number = 1
M_LETTER_DELETE_TOC_ERR_CODE_FIELD.index = 0
M_LETTER_DELETE_TOC_ERR_CODE_FIELD.label = 1
M_LETTER_DELETE_TOC_ERR_CODE_FIELD.has_default_value = true
M_LETTER_DELETE_TOC_ERR_CODE_FIELD.default_value = 0
M_LETTER_DELETE_TOC_ERR_CODE_FIELD.type = 5
M_LETTER_DELETE_TOC_ERR_CODE_FIELD.cpp_type = 1

M_LETTER_DELETE_TOC_OP_TYPE_FIELD.name = "op_type"
M_LETTER_DELETE_TOC_OP_TYPE_FIELD.full_name = ".m_letter_delete_toc.op_type"
M_LETTER_DELETE_TOC_OP_TYPE_FIELD.number = 2
M_LETTER_DELETE_TOC_OP_TYPE_FIELD.index = 1
M_LETTER_DELETE_TOC_OP_TYPE_FIELD.label = 1
M_LETTER_DELETE_TOC_OP_TYPE_FIELD.has_default_value = true
M_LETTER_DELETE_TOC_OP_TYPE_FIELD.default_value = 0
M_LETTER_DELETE_TOC_OP_TYPE_FIELD.type = 5
M_LETTER_DELETE_TOC_OP_TYPE_FIELD.cpp_type = 1

M_LETTER_DELETE_TOC_ID_LIST_FIELD.name = "id_list"
M_LETTER_DELETE_TOC_ID_LIST_FIELD.full_name = ".m_letter_delete_toc.id_list"
M_LETTER_DELETE_TOC_ID_LIST_FIELD.number = 3
M_LETTER_DELETE_TOC_ID_LIST_FIELD.index = 2
M_LETTER_DELETE_TOC_ID_LIST_FIELD.label = 3
M_LETTER_DELETE_TOC_ID_LIST_FIELD.has_default_value = false
M_LETTER_DELETE_TOC_ID_LIST_FIELD.default_value = {}
M_LETTER_DELETE_TOC_ID_LIST_FIELD.type = 5
M_LETTER_DELETE_TOC_ID_LIST_FIELD.cpp_type = 1

M_LETTER_DELETE_TOC.name = "m_letter_delete_toc"
M_LETTER_DELETE_TOC.full_name = ".m_letter_delete_toc"
M_LETTER_DELETE_TOC.nested_types = {}
M_LETTER_DELETE_TOC.enum_types = {}
M_LETTER_DELETE_TOC.fields = {M_LETTER_DELETE_TOC_ERR_CODE_FIELD, M_LETTER_DELETE_TOC_OP_TYPE_FIELD, M_LETTER_DELETE_TOC_ID_LIST_FIELD}
M_LETTER_DELETE_TOC.is_extendable = false
M_LETTER_DELETE_TOC.extensions = {}

m_letter_delete_toc = protobuf.Message(M_LETTER_DELETE_TOC)

