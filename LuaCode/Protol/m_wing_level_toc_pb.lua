--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_wing_level_toc_pb')

M_WING_LEVEL_TOC = protobuf.Descriptor();
M_WING_LEVEL_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_WING_LEVEL_TOC_NEW_LEVEL_FIELD = protobuf.FieldDescriptor();
M_WING_LEVEL_TOC_NEW_EXP_FIELD = protobuf.FieldDescriptor();

M_WING_LEVEL_TOC_ERR_CODE_FIELD.name = "err_code"
M_WING_LEVEL_TOC_ERR_CODE_FIELD.full_name = ".m_wing_level_toc.err_code"
M_WING_LEVEL_TOC_ERR_CODE_FIELD.number = 1
M_WING_LEVEL_TOC_ERR_CODE_FIELD.index = 0
M_WING_LEVEL_TOC_ERR_CODE_FIELD.label = 1
M_WING_LEVEL_TOC_ERR_CODE_FIELD.has_default_value = true
M_WING_LEVEL_TOC_ERR_CODE_FIELD.default_value = 0
M_WING_LEVEL_TOC_ERR_CODE_FIELD.type = 5
M_WING_LEVEL_TOC_ERR_CODE_FIELD.cpp_type = 1

M_WING_LEVEL_TOC_NEW_LEVEL_FIELD.name = "new_level"
M_WING_LEVEL_TOC_NEW_LEVEL_FIELD.full_name = ".m_wing_level_toc.new_level"
M_WING_LEVEL_TOC_NEW_LEVEL_FIELD.number = 2
M_WING_LEVEL_TOC_NEW_LEVEL_FIELD.index = 1
M_WING_LEVEL_TOC_NEW_LEVEL_FIELD.label = 1
M_WING_LEVEL_TOC_NEW_LEVEL_FIELD.has_default_value = true
M_WING_LEVEL_TOC_NEW_LEVEL_FIELD.default_value = 0
M_WING_LEVEL_TOC_NEW_LEVEL_FIELD.type = 5
M_WING_LEVEL_TOC_NEW_LEVEL_FIELD.cpp_type = 1

M_WING_LEVEL_TOC_NEW_EXP_FIELD.name = "new_exp"
M_WING_LEVEL_TOC_NEW_EXP_FIELD.full_name = ".m_wing_level_toc.new_exp"
M_WING_LEVEL_TOC_NEW_EXP_FIELD.number = 3
M_WING_LEVEL_TOC_NEW_EXP_FIELD.index = 2
M_WING_LEVEL_TOC_NEW_EXP_FIELD.label = 1
M_WING_LEVEL_TOC_NEW_EXP_FIELD.has_default_value = true
M_WING_LEVEL_TOC_NEW_EXP_FIELD.default_value = 0
M_WING_LEVEL_TOC_NEW_EXP_FIELD.type = 5
M_WING_LEVEL_TOC_NEW_EXP_FIELD.cpp_type = 1

M_WING_LEVEL_TOC.name = "m_wing_level_toc"
M_WING_LEVEL_TOC.full_name = ".m_wing_level_toc"
M_WING_LEVEL_TOC.nested_types = {}
M_WING_LEVEL_TOC.enum_types = {}
M_WING_LEVEL_TOC.fields = {M_WING_LEVEL_TOC_ERR_CODE_FIELD, M_WING_LEVEL_TOC_NEW_LEVEL_FIELD, M_WING_LEVEL_TOC_NEW_EXP_FIELD}
M_WING_LEVEL_TOC.is_extendable = false
M_WING_LEVEL_TOC.extensions = {}

m_wing_level_toc = protobuf.Message(M_WING_LEVEL_TOC)

