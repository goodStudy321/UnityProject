--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_bg_act_pb = require("Protol.p_bg_act_pb")
module('Protol.m_role_bg_rrank_toc_pb')

M_ROLE_BG_RRANK_TOC = protobuf.Descriptor();
M_ROLE_BG_RRANK_TOC_INFO_FIELD = protobuf.FieldDescriptor();
M_ROLE_BG_RRANK_TOC_MY_USE_FIELD = protobuf.FieldDescriptor();

M_ROLE_BG_RRANK_TOC_INFO_FIELD.name = "info"
M_ROLE_BG_RRANK_TOC_INFO_FIELD.full_name = ".m_role_bg_rrank_toc.info"
M_ROLE_BG_RRANK_TOC_INFO_FIELD.number = 1
M_ROLE_BG_RRANK_TOC_INFO_FIELD.index = 0
M_ROLE_BG_RRANK_TOC_INFO_FIELD.label = 1
M_ROLE_BG_RRANK_TOC_INFO_FIELD.has_default_value = false
M_ROLE_BG_RRANK_TOC_INFO_FIELD.default_value = nil
M_ROLE_BG_RRANK_TOC_INFO_FIELD.message_type = p_bg_act_pb.P_BG_ACT
M_ROLE_BG_RRANK_TOC_INFO_FIELD.type = 11
M_ROLE_BG_RRANK_TOC_INFO_FIELD.cpp_type = 10

M_ROLE_BG_RRANK_TOC_MY_USE_FIELD.name = "my_use"
M_ROLE_BG_RRANK_TOC_MY_USE_FIELD.full_name = ".m_role_bg_rrank_toc.my_use"
M_ROLE_BG_RRANK_TOC_MY_USE_FIELD.number = 2
M_ROLE_BG_RRANK_TOC_MY_USE_FIELD.index = 1
M_ROLE_BG_RRANK_TOC_MY_USE_FIELD.label = 1
M_ROLE_BG_RRANK_TOC_MY_USE_FIELD.has_default_value = true
M_ROLE_BG_RRANK_TOC_MY_USE_FIELD.default_value = 0
M_ROLE_BG_RRANK_TOC_MY_USE_FIELD.type = 5
M_ROLE_BG_RRANK_TOC_MY_USE_FIELD.cpp_type = 1

M_ROLE_BG_RRANK_TOC.name = "m_role_bg_rrank_toc"
M_ROLE_BG_RRANK_TOC.full_name = ".m_role_bg_rrank_toc"
M_ROLE_BG_RRANK_TOC.nested_types = {}
M_ROLE_BG_RRANK_TOC.enum_types = {}
M_ROLE_BG_RRANK_TOC.fields = {M_ROLE_BG_RRANK_TOC_INFO_FIELD, M_ROLE_BG_RRANK_TOC_MY_USE_FIELD}
M_ROLE_BG_RRANK_TOC.is_extendable = false
M_ROLE_BG_RRANK_TOC.extensions = {}

m_role_bg_rrank_toc = protobuf.Message(M_ROLE_BG_RRANK_TOC)
