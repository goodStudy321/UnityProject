--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_kv_pb = require("Protol.p_kv_pb")
module('Protol.m_act_family_create_reward_update_toc_pb')

M_ACT_FAMILY_CREATE_REWARD_UPDATE_TOC = protobuf.Descriptor();
M_ACT_FAMILY_CREATE_REWARD_UPDATE_TOC_REWARD_FIELD = protobuf.FieldDescriptor();

M_ACT_FAMILY_CREATE_REWARD_UPDATE_TOC_REWARD_FIELD.name = "reward"
M_ACT_FAMILY_CREATE_REWARD_UPDATE_TOC_REWARD_FIELD.full_name = ".m_act_family_create_reward_update_toc.reward"
M_ACT_FAMILY_CREATE_REWARD_UPDATE_TOC_REWARD_FIELD.number = 1
M_ACT_FAMILY_CREATE_REWARD_UPDATE_TOC_REWARD_FIELD.index = 0
M_ACT_FAMILY_CREATE_REWARD_UPDATE_TOC_REWARD_FIELD.label = 1
M_ACT_FAMILY_CREATE_REWARD_UPDATE_TOC_REWARD_FIELD.has_default_value = false
M_ACT_FAMILY_CREATE_REWARD_UPDATE_TOC_REWARD_FIELD.default_value = nil
M_ACT_FAMILY_CREATE_REWARD_UPDATE_TOC_REWARD_FIELD.message_type = p_kv_pb.P_KV
M_ACT_FAMILY_CREATE_REWARD_UPDATE_TOC_REWARD_FIELD.type = 11
M_ACT_FAMILY_CREATE_REWARD_UPDATE_TOC_REWARD_FIELD.cpp_type = 10

M_ACT_FAMILY_CREATE_REWARD_UPDATE_TOC.name = "m_act_family_create_reward_update_toc"
M_ACT_FAMILY_CREATE_REWARD_UPDATE_TOC.full_name = ".m_act_family_create_reward_update_toc"
M_ACT_FAMILY_CREATE_REWARD_UPDATE_TOC.nested_types = {}
M_ACT_FAMILY_CREATE_REWARD_UPDATE_TOC.enum_types = {}
M_ACT_FAMILY_CREATE_REWARD_UPDATE_TOC.fields = {M_ACT_FAMILY_CREATE_REWARD_UPDATE_TOC_REWARD_FIELD}
M_ACT_FAMILY_CREATE_REWARD_UPDATE_TOC.is_extendable = false
M_ACT_FAMILY_CREATE_REWARD_UPDATE_TOC.extensions = {}

m_act_family_create_reward_update_toc = protobuf.Message(M_ACT_FAMILY_CREATE_REWARD_UPDATE_TOC)
