--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_goods_pb = require("Protol.p_goods_pb")
module('Protol.m_role_fgb_end_toc_pb')

M_ROLE_FGB_END_TOC = protobuf.Descriptor();
M_ROLE_FGB_END_TOC_ROLE_FIELD = protobuf.FieldDescriptor();
M_ROLE_FGB_END_TOC_FAMILY_FIELD = protobuf.FieldDescriptor();

M_ROLE_FGB_END_TOC_ROLE_FIELD.name = "role"
M_ROLE_FGB_END_TOC_ROLE_FIELD.full_name = ".m_role_fgb_end_toc.role"
M_ROLE_FGB_END_TOC_ROLE_FIELD.number = 1
M_ROLE_FGB_END_TOC_ROLE_FIELD.index = 0
M_ROLE_FGB_END_TOC_ROLE_FIELD.label = 3
M_ROLE_FGB_END_TOC_ROLE_FIELD.has_default_value = false
M_ROLE_FGB_END_TOC_ROLE_FIELD.default_value = {}
M_ROLE_FGB_END_TOC_ROLE_FIELD.message_type = p_goods_pb.P_GOODS
M_ROLE_FGB_END_TOC_ROLE_FIELD.type = 11
M_ROLE_FGB_END_TOC_ROLE_FIELD.cpp_type = 10

M_ROLE_FGB_END_TOC_FAMILY_FIELD.name = "family"
M_ROLE_FGB_END_TOC_FAMILY_FIELD.full_name = ".m_role_fgb_end_toc.family"
M_ROLE_FGB_END_TOC_FAMILY_FIELD.number = 2
M_ROLE_FGB_END_TOC_FAMILY_FIELD.index = 1
M_ROLE_FGB_END_TOC_FAMILY_FIELD.label = 3
M_ROLE_FGB_END_TOC_FAMILY_FIELD.has_default_value = false
M_ROLE_FGB_END_TOC_FAMILY_FIELD.default_value = {}
M_ROLE_FGB_END_TOC_FAMILY_FIELD.message_type = p_goods_pb.P_GOODS
M_ROLE_FGB_END_TOC_FAMILY_FIELD.type = 11
M_ROLE_FGB_END_TOC_FAMILY_FIELD.cpp_type = 10

M_ROLE_FGB_END_TOC.name = "m_role_fgb_end_toc"
M_ROLE_FGB_END_TOC.full_name = ".m_role_fgb_end_toc"
M_ROLE_FGB_END_TOC.nested_types = {}
M_ROLE_FGB_END_TOC.enum_types = {}
M_ROLE_FGB_END_TOC.fields = {M_ROLE_FGB_END_TOC_ROLE_FIELD, M_ROLE_FGB_END_TOC_FAMILY_FIELD}
M_ROLE_FGB_END_TOC.is_extendable = false
M_ROLE_FGB_END_TOC.extensions = {}

m_role_fgb_end_toc = protobuf.Message(M_ROLE_FGB_END_TOC)

