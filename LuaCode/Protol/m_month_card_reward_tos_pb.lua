--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_month_card_reward_tos_pb')

M_MONTH_CARD_REWARD_TOS = protobuf.Descriptor();
M_MONTH_CARD_REWARD_TOS_DAYS_FIELD = protobuf.FieldDescriptor();

M_MONTH_CARD_REWARD_TOS_DAYS_FIELD.name = "days"
M_MONTH_CARD_REWARD_TOS_DAYS_FIELD.full_name = ".m_month_card_reward_tos.days"
M_MONTH_CARD_REWARD_TOS_DAYS_FIELD.number = 1
M_MONTH_CARD_REWARD_TOS_DAYS_FIELD.index = 0
M_MONTH_CARD_REWARD_TOS_DAYS_FIELD.label = 1
M_MONTH_CARD_REWARD_TOS_DAYS_FIELD.has_default_value = true
M_MONTH_CARD_REWARD_TOS_DAYS_FIELD.default_value = 0
M_MONTH_CARD_REWARD_TOS_DAYS_FIELD.type = 5
M_MONTH_CARD_REWARD_TOS_DAYS_FIELD.cpp_type = 1

M_MONTH_CARD_REWARD_TOS.name = "m_month_card_reward_tos"
M_MONTH_CARD_REWARD_TOS.full_name = ".m_month_card_reward_tos"
M_MONTH_CARD_REWARD_TOS.nested_types = {}
M_MONTH_CARD_REWARD_TOS.enum_types = {}
M_MONTH_CARD_REWARD_TOS.fields = {M_MONTH_CARD_REWARD_TOS_DAYS_FIELD}
M_MONTH_CARD_REWARD_TOS.is_extendable = false
M_MONTH_CARD_REWARD_TOS.extensions = {}

m_month_card_reward_tos = protobuf.Message(M_MONTH_CARD_REWARD_TOS)
