--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_fashion_suit_tos_pb')

M_FASHION_SUIT_TOS = protobuf.Descriptor();
M_FASHION_SUIT_TOS_SUIT_ID_FIELD = protobuf.FieldDescriptor();
M_FASHION_SUIT_TOS_ACTIVE_NUM_FIELD = protobuf.FieldDescriptor();

M_FASHION_SUIT_TOS_SUIT_ID_FIELD.name = "suit_id"
M_FASHION_SUIT_TOS_SUIT_ID_FIELD.full_name = ".m_fashion_suit_tos.suit_id"
M_FASHION_SUIT_TOS_SUIT_ID_FIELD.number = 1
M_FASHION_SUIT_TOS_SUIT_ID_FIELD.index = 0
M_FASHION_SUIT_TOS_SUIT_ID_FIELD.label = 1
M_FASHION_SUIT_TOS_SUIT_ID_FIELD.has_default_value = true
M_FASHION_SUIT_TOS_SUIT_ID_FIELD.default_value = 0
M_FASHION_SUIT_TOS_SUIT_ID_FIELD.type = 5
M_FASHION_SUIT_TOS_SUIT_ID_FIELD.cpp_type = 1

M_FASHION_SUIT_TOS_ACTIVE_NUM_FIELD.name = "active_num"
M_FASHION_SUIT_TOS_ACTIVE_NUM_FIELD.full_name = ".m_fashion_suit_tos.active_num"
M_FASHION_SUIT_TOS_ACTIVE_NUM_FIELD.number = 2
M_FASHION_SUIT_TOS_ACTIVE_NUM_FIELD.index = 1
M_FASHION_SUIT_TOS_ACTIVE_NUM_FIELD.label = 1
M_FASHION_SUIT_TOS_ACTIVE_NUM_FIELD.has_default_value = true
M_FASHION_SUIT_TOS_ACTIVE_NUM_FIELD.default_value = 0
M_FASHION_SUIT_TOS_ACTIVE_NUM_FIELD.type = 5
M_FASHION_SUIT_TOS_ACTIVE_NUM_FIELD.cpp_type = 1

M_FASHION_SUIT_TOS.name = "m_fashion_suit_tos"
M_FASHION_SUIT_TOS.full_name = ".m_fashion_suit_tos"
M_FASHION_SUIT_TOS.nested_types = {}
M_FASHION_SUIT_TOS.enum_types = {}
M_FASHION_SUIT_TOS.fields = {M_FASHION_SUIT_TOS_SUIT_ID_FIELD, M_FASHION_SUIT_TOS_ACTIVE_NUM_FIELD}
M_FASHION_SUIT_TOS.is_extendable = false
M_FASHION_SUIT_TOS.extensions = {}

m_fashion_suit_tos = protobuf.Message(M_FASHION_SUIT_TOS)
