--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_immortal_soul_pb = require("Protol.p_immortal_soul_pb")
module('Protol.m_role_immortal_soul_down_toc_pb')

M_ROLE_IMMORTAL_SOUL_DOWN_TOC = protobuf.Descriptor();
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_POS_FIELD = protobuf.FieldDescriptor();
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_BAG_ADD_FIELD = protobuf.FieldDescriptor();

M_ROLE_IMMORTAL_SOUL_DOWN_TOC_ERR_CODE_FIELD.name = "err_code"
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_ERR_CODE_FIELD.full_name = ".m_role_immortal_soul_down_toc.err_code"
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_ERR_CODE_FIELD.number = 1
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_ERR_CODE_FIELD.index = 0
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_ERR_CODE_FIELD.label = 1
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_ERR_CODE_FIELD.has_default_value = true
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_ERR_CODE_FIELD.default_value = 0
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_ERR_CODE_FIELD.type = 5
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_ERR_CODE_FIELD.cpp_type = 1

M_ROLE_IMMORTAL_SOUL_DOWN_TOC_POS_FIELD.name = "pos"
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_POS_FIELD.full_name = ".m_role_immortal_soul_down_toc.pos"
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_POS_FIELD.number = 2
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_POS_FIELD.index = 1
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_POS_FIELD.label = 1
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_POS_FIELD.has_default_value = true
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_POS_FIELD.default_value = 0
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_POS_FIELD.type = 5
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_POS_FIELD.cpp_type = 1

M_ROLE_IMMORTAL_SOUL_DOWN_TOC_BAG_ADD_FIELD.name = "bag_add"
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_BAG_ADD_FIELD.full_name = ".m_role_immortal_soul_down_toc.bag_add"
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_BAG_ADD_FIELD.number = 3
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_BAG_ADD_FIELD.index = 2
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_BAG_ADD_FIELD.label = 1
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_BAG_ADD_FIELD.has_default_value = false
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_BAG_ADD_FIELD.default_value = nil
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_BAG_ADD_FIELD.message_type = p_immortal_soul_pb.P_IMMORTAL_SOUL
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_BAG_ADD_FIELD.type = 11
M_ROLE_IMMORTAL_SOUL_DOWN_TOC_BAG_ADD_FIELD.cpp_type = 10

M_ROLE_IMMORTAL_SOUL_DOWN_TOC.name = "m_role_immortal_soul_down_toc"
M_ROLE_IMMORTAL_SOUL_DOWN_TOC.full_name = ".m_role_immortal_soul_down_toc"
M_ROLE_IMMORTAL_SOUL_DOWN_TOC.nested_types = {}
M_ROLE_IMMORTAL_SOUL_DOWN_TOC.enum_types = {}
M_ROLE_IMMORTAL_SOUL_DOWN_TOC.fields = {M_ROLE_IMMORTAL_SOUL_DOWN_TOC_ERR_CODE_FIELD, M_ROLE_IMMORTAL_SOUL_DOWN_TOC_POS_FIELD, M_ROLE_IMMORTAL_SOUL_DOWN_TOC_BAG_ADD_FIELD}
M_ROLE_IMMORTAL_SOUL_DOWN_TOC.is_extendable = false
M_ROLE_IMMORTAL_SOUL_DOWN_TOC.extensions = {}

m_role_immortal_soul_down_toc = protobuf.Message(M_ROLE_IMMORTAL_SOUL_DOWN_TOC)

