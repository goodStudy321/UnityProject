--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_kv_pb = require("Protol.p_kv_pb")
module('Protol.m_act_level_update_toc_pb')

M_ACT_LEVEL_UPDATE_TOC = protobuf.Descriptor();
M_ACT_LEVEL_UPDATE_TOC_ACT_LEVEL_FIELD = protobuf.FieldDescriptor();

M_ACT_LEVEL_UPDATE_TOC_ACT_LEVEL_FIELD.name = "act_level"
M_ACT_LEVEL_UPDATE_TOC_ACT_LEVEL_FIELD.full_name = ".m_act_level_update_toc.act_level"
M_ACT_LEVEL_UPDATE_TOC_ACT_LEVEL_FIELD.number = 1
M_ACT_LEVEL_UPDATE_TOC_ACT_LEVEL_FIELD.index = 0
M_ACT_LEVEL_UPDATE_TOC_ACT_LEVEL_FIELD.label = 1
M_ACT_LEVEL_UPDATE_TOC_ACT_LEVEL_FIELD.has_default_value = false
M_ACT_LEVEL_UPDATE_TOC_ACT_LEVEL_FIELD.default_value = nil
M_ACT_LEVEL_UPDATE_TOC_ACT_LEVEL_FIELD.message_type = p_kv_pb.P_KV
M_ACT_LEVEL_UPDATE_TOC_ACT_LEVEL_FIELD.type = 11
M_ACT_LEVEL_UPDATE_TOC_ACT_LEVEL_FIELD.cpp_type = 10

M_ACT_LEVEL_UPDATE_TOC.name = "m_act_level_update_toc"
M_ACT_LEVEL_UPDATE_TOC.full_name = ".m_act_level_update_toc"
M_ACT_LEVEL_UPDATE_TOC.nested_types = {}
M_ACT_LEVEL_UPDATE_TOC.enum_types = {}
M_ACT_LEVEL_UPDATE_TOC.fields = {M_ACT_LEVEL_UPDATE_TOC_ACT_LEVEL_FIELD}
M_ACT_LEVEL_UPDATE_TOC.is_extendable = false
M_ACT_LEVEL_UPDATE_TOC.extensions = {}

m_act_level_update_toc = protobuf.Message(M_ACT_LEVEL_UPDATE_TOC)

