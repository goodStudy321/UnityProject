--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_act_rank_reward_tos_pb')

M_ACT_RANK_REWARD_TOS = protobuf.Descriptor();
M_ACT_RANK_REWARD_TOS_ID_FIELD = protobuf.FieldDescriptor();
M_ACT_RANK_REWARD_TOS_TYPE_FIELD = protobuf.FieldDescriptor();

M_ACT_RANK_REWARD_TOS_ID_FIELD.name = "id"
M_ACT_RANK_REWARD_TOS_ID_FIELD.full_name = ".m_act_rank_reward_tos.id"
M_ACT_RANK_REWARD_TOS_ID_FIELD.number = 1
M_ACT_RANK_REWARD_TOS_ID_FIELD.index = 0
M_ACT_RANK_REWARD_TOS_ID_FIELD.label = 1
M_ACT_RANK_REWARD_TOS_ID_FIELD.has_default_value = true
M_ACT_RANK_REWARD_TOS_ID_FIELD.default_value = 0
M_ACT_RANK_REWARD_TOS_ID_FIELD.type = 5
M_ACT_RANK_REWARD_TOS_ID_FIELD.cpp_type = 1

M_ACT_RANK_REWARD_TOS_TYPE_FIELD.name = "type"
M_ACT_RANK_REWARD_TOS_TYPE_FIELD.full_name = ".m_act_rank_reward_tos.type"
M_ACT_RANK_REWARD_TOS_TYPE_FIELD.number = 2
M_ACT_RANK_REWARD_TOS_TYPE_FIELD.index = 1
M_ACT_RANK_REWARD_TOS_TYPE_FIELD.label = 1
M_ACT_RANK_REWARD_TOS_TYPE_FIELD.has_default_value = true
M_ACT_RANK_REWARD_TOS_TYPE_FIELD.default_value = 0
M_ACT_RANK_REWARD_TOS_TYPE_FIELD.type = 5
M_ACT_RANK_REWARD_TOS_TYPE_FIELD.cpp_type = 1

M_ACT_RANK_REWARD_TOS.name = "m_act_rank_reward_tos"
M_ACT_RANK_REWARD_TOS.full_name = ".m_act_rank_reward_tos"
M_ACT_RANK_REWARD_TOS.nested_types = {}
M_ACT_RANK_REWARD_TOS.enum_types = {}
M_ACT_RANK_REWARD_TOS.fields = {M_ACT_RANK_REWARD_TOS_ID_FIELD, M_ACT_RANK_REWARD_TOS_TYPE_FIELD}
M_ACT_RANK_REWARD_TOS.is_extendable = false
M_ACT_RANK_REWARD_TOS.extensions = {}

m_act_rank_reward_tos = protobuf.Message(M_ACT_RANK_REWARD_TOS)

