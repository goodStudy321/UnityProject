--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_kv_pb = require("Protol.p_kv_pb")
module('Protol.m_act_family_create_condition_toc_pb')

M_ACT_FAMILY_CREATE_CONDITION_TOC = protobuf.Descriptor();
M_ACT_FAMILY_CREATE_CONDITION_TOC_CONDITION_FIELD = protobuf.FieldDescriptor();

M_ACT_FAMILY_CREATE_CONDITION_TOC_CONDITION_FIELD.name = "condition"
M_ACT_FAMILY_CREATE_CONDITION_TOC_CONDITION_FIELD.full_name = ".m_act_family_create_condition_toc.condition"
M_ACT_FAMILY_CREATE_CONDITION_TOC_CONDITION_FIELD.number = 1
M_ACT_FAMILY_CREATE_CONDITION_TOC_CONDITION_FIELD.index = 0
M_ACT_FAMILY_CREATE_CONDITION_TOC_CONDITION_FIELD.label = 1
M_ACT_FAMILY_CREATE_CONDITION_TOC_CONDITION_FIELD.has_default_value = false
M_ACT_FAMILY_CREATE_CONDITION_TOC_CONDITION_FIELD.default_value = nil
M_ACT_FAMILY_CREATE_CONDITION_TOC_CONDITION_FIELD.message_type = p_kv_pb.P_KV
M_ACT_FAMILY_CREATE_CONDITION_TOC_CONDITION_FIELD.type = 11
M_ACT_FAMILY_CREATE_CONDITION_TOC_CONDITION_FIELD.cpp_type = 10

M_ACT_FAMILY_CREATE_CONDITION_TOC.name = "m_act_family_create_condition_toc"
M_ACT_FAMILY_CREATE_CONDITION_TOC.full_name = ".m_act_family_create_condition_toc"
M_ACT_FAMILY_CREATE_CONDITION_TOC.nested_types = {}
M_ACT_FAMILY_CREATE_CONDITION_TOC.enum_types = {}
M_ACT_FAMILY_CREATE_CONDITION_TOC.fields = {M_ACT_FAMILY_CREATE_CONDITION_TOC_CONDITION_FIELD}
M_ACT_FAMILY_CREATE_CONDITION_TOC.is_extendable = false
M_ACT_FAMILY_CREATE_CONDITION_TOC.extensions = {}

m_act_family_create_condition_toc = protobuf.Message(M_ACT_FAMILY_CREATE_CONDITION_TOC)
