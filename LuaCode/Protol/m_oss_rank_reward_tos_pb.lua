--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_oss_rank_reward_tos_pb')

M_OSS_RANK_REWARD_TOS = protobuf.Descriptor();
M_OSS_RANK_REWARD_TOS_TYPE_FIELD = protobuf.FieldDescriptor();
M_OSS_RANK_REWARD_TOS_TYPE_I_FIELD = protobuf.FieldDescriptor();
M_OSS_RANK_REWARD_TOS_ID_FIELD = protobuf.FieldDescriptor();

M_OSS_RANK_REWARD_TOS_TYPE_FIELD.name = "type"
M_OSS_RANK_REWARD_TOS_TYPE_FIELD.full_name = ".m_oss_rank_reward_tos.type"
M_OSS_RANK_REWARD_TOS_TYPE_FIELD.number = 1
M_OSS_RANK_REWARD_TOS_TYPE_FIELD.index = 0
M_OSS_RANK_REWARD_TOS_TYPE_FIELD.label = 1
M_OSS_RANK_REWARD_TOS_TYPE_FIELD.has_default_value = true
M_OSS_RANK_REWARD_TOS_TYPE_FIELD.default_value = 0
M_OSS_RANK_REWARD_TOS_TYPE_FIELD.type = 5
M_OSS_RANK_REWARD_TOS_TYPE_FIELD.cpp_type = 1

M_OSS_RANK_REWARD_TOS_TYPE_I_FIELD.name = "type_i"
M_OSS_RANK_REWARD_TOS_TYPE_I_FIELD.full_name = ".m_oss_rank_reward_tos.type_i"
M_OSS_RANK_REWARD_TOS_TYPE_I_FIELD.number = 2
M_OSS_RANK_REWARD_TOS_TYPE_I_FIELD.index = 1
M_OSS_RANK_REWARD_TOS_TYPE_I_FIELD.label = 1
M_OSS_RANK_REWARD_TOS_TYPE_I_FIELD.has_default_value = true
M_OSS_RANK_REWARD_TOS_TYPE_I_FIELD.default_value = 0
M_OSS_RANK_REWARD_TOS_TYPE_I_FIELD.type = 5
M_OSS_RANK_REWARD_TOS_TYPE_I_FIELD.cpp_type = 1

M_OSS_RANK_REWARD_TOS_ID_FIELD.name = "id"
M_OSS_RANK_REWARD_TOS_ID_FIELD.full_name = ".m_oss_rank_reward_tos.id"
M_OSS_RANK_REWARD_TOS_ID_FIELD.number = 3
M_OSS_RANK_REWARD_TOS_ID_FIELD.index = 2
M_OSS_RANK_REWARD_TOS_ID_FIELD.label = 1
M_OSS_RANK_REWARD_TOS_ID_FIELD.has_default_value = true
M_OSS_RANK_REWARD_TOS_ID_FIELD.default_value = 0
M_OSS_RANK_REWARD_TOS_ID_FIELD.type = 5
M_OSS_RANK_REWARD_TOS_ID_FIELD.cpp_type = 1

M_OSS_RANK_REWARD_TOS.name = "m_oss_rank_reward_tos"
M_OSS_RANK_REWARD_TOS.full_name = ".m_oss_rank_reward_tos"
M_OSS_RANK_REWARD_TOS.nested_types = {}
M_OSS_RANK_REWARD_TOS.enum_types = {}
M_OSS_RANK_REWARD_TOS.fields = {M_OSS_RANK_REWARD_TOS_TYPE_FIELD, M_OSS_RANK_REWARD_TOS_TYPE_I_FIELD, M_OSS_RANK_REWARD_TOS_ID_FIELD}
M_OSS_RANK_REWARD_TOS.is_extendable = false
M_OSS_RANK_REWARD_TOS.extensions = {}

m_oss_rank_reward_tos = protobuf.Message(M_OSS_RANK_REWARD_TOS)

