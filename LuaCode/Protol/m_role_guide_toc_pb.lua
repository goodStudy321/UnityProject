--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_role_guide_toc_pb')

M_ROLE_GUIDE_TOC = protobuf.Descriptor();
M_ROLE_GUIDE_TOC_GUIDE_ID_LIST_FIELD = protobuf.FieldDescriptor();

M_ROLE_GUIDE_TOC_GUIDE_ID_LIST_FIELD.name = "guide_id_list"
M_ROLE_GUIDE_TOC_GUIDE_ID_LIST_FIELD.full_name = ".m_role_guide_toc.guide_id_list"
M_ROLE_GUIDE_TOC_GUIDE_ID_LIST_FIELD.number = 1
M_ROLE_GUIDE_TOC_GUIDE_ID_LIST_FIELD.index = 0
M_ROLE_GUIDE_TOC_GUIDE_ID_LIST_FIELD.label = 3
M_ROLE_GUIDE_TOC_GUIDE_ID_LIST_FIELD.has_default_value = false
M_ROLE_GUIDE_TOC_GUIDE_ID_LIST_FIELD.default_value = {}
M_ROLE_GUIDE_TOC_GUIDE_ID_LIST_FIELD.type = 5
M_ROLE_GUIDE_TOC_GUIDE_ID_LIST_FIELD.cpp_type = 1

M_ROLE_GUIDE_TOC.name = "m_role_guide_toc"
M_ROLE_GUIDE_TOC.full_name = ".m_role_guide_toc"
M_ROLE_GUIDE_TOC.nested_types = {}
M_ROLE_GUIDE_TOC.enum_types = {}
M_ROLE_GUIDE_TOC.fields = {M_ROLE_GUIDE_TOC_GUIDE_ID_LIST_FIELD}
M_ROLE_GUIDE_TOC.is_extendable = false
M_ROLE_GUIDE_TOC.extensions = {}

m_role_guide_toc = protobuf.Message(M_ROLE_GUIDE_TOC)

