--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_market_down_shelf_tos_pb')

M_MARKET_DOWN_SHELF_TOS = protobuf.Descriptor();
M_MARKET_DOWN_SHELF_TOS_ID_FIELD = protobuf.FieldDescriptor();
M_MARKET_DOWN_SHELF_TOS_MARKET_TYPE_FIELD = protobuf.FieldDescriptor();

M_MARKET_DOWN_SHELF_TOS_ID_FIELD.name = "id"
M_MARKET_DOWN_SHELF_TOS_ID_FIELD.full_name = ".m_market_down_shelf_tos.id"
M_MARKET_DOWN_SHELF_TOS_ID_FIELD.number = 1
M_MARKET_DOWN_SHELF_TOS_ID_FIELD.index = 0
M_MARKET_DOWN_SHELF_TOS_ID_FIELD.label = 1
M_MARKET_DOWN_SHELF_TOS_ID_FIELD.has_default_value = true
M_MARKET_DOWN_SHELF_TOS_ID_FIELD.default_value = 0
M_MARKET_DOWN_SHELF_TOS_ID_FIELD.type = 5
M_MARKET_DOWN_SHELF_TOS_ID_FIELD.cpp_type = 1

M_MARKET_DOWN_SHELF_TOS_MARKET_TYPE_FIELD.name = "market_type"
M_MARKET_DOWN_SHELF_TOS_MARKET_TYPE_FIELD.full_name = ".m_market_down_shelf_tos.market_type"
M_MARKET_DOWN_SHELF_TOS_MARKET_TYPE_FIELD.number = 2
M_MARKET_DOWN_SHELF_TOS_MARKET_TYPE_FIELD.index = 1
M_MARKET_DOWN_SHELF_TOS_MARKET_TYPE_FIELD.label = 1
M_MARKET_DOWN_SHELF_TOS_MARKET_TYPE_FIELD.has_default_value = true
M_MARKET_DOWN_SHELF_TOS_MARKET_TYPE_FIELD.default_value = 0
M_MARKET_DOWN_SHELF_TOS_MARKET_TYPE_FIELD.type = 5
M_MARKET_DOWN_SHELF_TOS_MARKET_TYPE_FIELD.cpp_type = 1

M_MARKET_DOWN_SHELF_TOS.name = "m_market_down_shelf_tos"
M_MARKET_DOWN_SHELF_TOS.full_name = ".m_market_down_shelf_tos"
M_MARKET_DOWN_SHELF_TOS.nested_types = {}
M_MARKET_DOWN_SHELF_TOS.enum_types = {}
M_MARKET_DOWN_SHELF_TOS.fields = {M_MARKET_DOWN_SHELF_TOS_ID_FIELD, M_MARKET_DOWN_SHELF_TOS_MARKET_TYPE_FIELD}
M_MARKET_DOWN_SHELF_TOS.is_extendable = false
M_MARKET_DOWN_SHELF_TOS.extensions = {}

m_market_down_shelf_tos = protobuf.Message(M_MARKET_DOWN_SHELF_TOS)

