--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_role_bg_tta_choice_toc_pb')

M_ROLE_BG_TTA_CHOICE_TOC = protobuf.Descriptor();
M_ROLE_BG_TTA_CHOICE_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_ROLE_BG_TTA_CHOICE_TOC_LIST_FIELD = protobuf.FieldDescriptor();
M_ROLE_BG_TTA_CHOICE_TOC_LAYER_FIELD = protobuf.FieldDescriptor();

M_ROLE_BG_TTA_CHOICE_TOC_ERR_CODE_FIELD.name = "err_code"
M_ROLE_BG_TTA_CHOICE_TOC_ERR_CODE_FIELD.full_name = ".m_role_bg_tta_choice_toc.err_code"
M_ROLE_BG_TTA_CHOICE_TOC_ERR_CODE_FIELD.number = 1
M_ROLE_BG_TTA_CHOICE_TOC_ERR_CODE_FIELD.index = 0
M_ROLE_BG_TTA_CHOICE_TOC_ERR_CODE_FIELD.label = 1
M_ROLE_BG_TTA_CHOICE_TOC_ERR_CODE_FIELD.has_default_value = true
M_ROLE_BG_TTA_CHOICE_TOC_ERR_CODE_FIELD.default_value = 0
M_ROLE_BG_TTA_CHOICE_TOC_ERR_CODE_FIELD.type = 5
M_ROLE_BG_TTA_CHOICE_TOC_ERR_CODE_FIELD.cpp_type = 1

M_ROLE_BG_TTA_CHOICE_TOC_LIST_FIELD.name = "list"
M_ROLE_BG_TTA_CHOICE_TOC_LIST_FIELD.full_name = ".m_role_bg_tta_choice_toc.list"
M_ROLE_BG_TTA_CHOICE_TOC_LIST_FIELD.number = 2
M_ROLE_BG_TTA_CHOICE_TOC_LIST_FIELD.index = 1
M_ROLE_BG_TTA_CHOICE_TOC_LIST_FIELD.label = 3
M_ROLE_BG_TTA_CHOICE_TOC_LIST_FIELD.has_default_value = false
M_ROLE_BG_TTA_CHOICE_TOC_LIST_FIELD.default_value = {}
M_ROLE_BG_TTA_CHOICE_TOC_LIST_FIELD.type = 5
M_ROLE_BG_TTA_CHOICE_TOC_LIST_FIELD.cpp_type = 1

M_ROLE_BG_TTA_CHOICE_TOC_LAYER_FIELD.name = "layer"
M_ROLE_BG_TTA_CHOICE_TOC_LAYER_FIELD.full_name = ".m_role_bg_tta_choice_toc.layer"
M_ROLE_BG_TTA_CHOICE_TOC_LAYER_FIELD.number = 3
M_ROLE_BG_TTA_CHOICE_TOC_LAYER_FIELD.index = 2
M_ROLE_BG_TTA_CHOICE_TOC_LAYER_FIELD.label = 1
M_ROLE_BG_TTA_CHOICE_TOC_LAYER_FIELD.has_default_value = true
M_ROLE_BG_TTA_CHOICE_TOC_LAYER_FIELD.default_value = 0
M_ROLE_BG_TTA_CHOICE_TOC_LAYER_FIELD.type = 5
M_ROLE_BG_TTA_CHOICE_TOC_LAYER_FIELD.cpp_type = 1

M_ROLE_BG_TTA_CHOICE_TOC.name = "m_role_bg_tta_choice_toc"
M_ROLE_BG_TTA_CHOICE_TOC.full_name = ".m_role_bg_tta_choice_toc"
M_ROLE_BG_TTA_CHOICE_TOC.nested_types = {}
M_ROLE_BG_TTA_CHOICE_TOC.enum_types = {}
M_ROLE_BG_TTA_CHOICE_TOC.fields = {M_ROLE_BG_TTA_CHOICE_TOC_ERR_CODE_FIELD, M_ROLE_BG_TTA_CHOICE_TOC_LIST_FIELD, M_ROLE_BG_TTA_CHOICE_TOC_LAYER_FIELD}
M_ROLE_BG_TTA_CHOICE_TOC.is_extendable = false
M_ROLE_BG_TTA_CHOICE_TOC.extensions = {}

m_role_bg_tta_choice_toc = protobuf.Message(M_ROLE_BG_TTA_CHOICE_TOC)

