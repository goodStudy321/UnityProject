--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_bg_act_reward_tos_pb')

M_BG_ACT_REWARD_TOS = protobuf.Descriptor();
M_BG_ACT_REWARD_TOS_ID_FIELD = protobuf.FieldDescriptor();
M_BG_ACT_REWARD_TOS_ENTRY_FIELD = protobuf.FieldDescriptor();

M_BG_ACT_REWARD_TOS_ID_FIELD.name = "id"
M_BG_ACT_REWARD_TOS_ID_FIELD.full_name = ".m_bg_act_reward_tos.id"
M_BG_ACT_REWARD_TOS_ID_FIELD.number = 1
M_BG_ACT_REWARD_TOS_ID_FIELD.index = 0
M_BG_ACT_REWARD_TOS_ID_FIELD.label = 1
M_BG_ACT_REWARD_TOS_ID_FIELD.has_default_value = true
M_BG_ACT_REWARD_TOS_ID_FIELD.default_value = 0
M_BG_ACT_REWARD_TOS_ID_FIELD.type = 5
M_BG_ACT_REWARD_TOS_ID_FIELD.cpp_type = 1

M_BG_ACT_REWARD_TOS_ENTRY_FIELD.name = "entry"
M_BG_ACT_REWARD_TOS_ENTRY_FIELD.full_name = ".m_bg_act_reward_tos.entry"
M_BG_ACT_REWARD_TOS_ENTRY_FIELD.number = 2
M_BG_ACT_REWARD_TOS_ENTRY_FIELD.index = 1
M_BG_ACT_REWARD_TOS_ENTRY_FIELD.label = 1
M_BG_ACT_REWARD_TOS_ENTRY_FIELD.has_default_value = true
M_BG_ACT_REWARD_TOS_ENTRY_FIELD.default_value = 0
M_BG_ACT_REWARD_TOS_ENTRY_FIELD.type = 5
M_BG_ACT_REWARD_TOS_ENTRY_FIELD.cpp_type = 1

M_BG_ACT_REWARD_TOS.name = "m_bg_act_reward_tos"
M_BG_ACT_REWARD_TOS.full_name = ".m_bg_act_reward_tos"
M_BG_ACT_REWARD_TOS.nested_types = {}
M_BG_ACT_REWARD_TOS.enum_types = {}
M_BG_ACT_REWARD_TOS.fields = {M_BG_ACT_REWARD_TOS_ID_FIELD, M_BG_ACT_REWARD_TOS_ENTRY_FIELD}
M_BG_ACT_REWARD_TOS.is_extendable = false
M_BG_ACT_REWARD_TOS.extensions = {}

m_bg_act_reward_tos = protobuf.Message(M_BG_ACT_REWARD_TOS)
