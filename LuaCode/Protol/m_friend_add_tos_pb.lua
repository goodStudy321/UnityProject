--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_friend_add_tos_pb')

M_FRIEND_ADD_TOS = protobuf.Descriptor();
M_FRIEND_ADD_TOS_ROLE_ID_FIELD = protobuf.FieldDescriptor();

M_FRIEND_ADD_TOS_ROLE_ID_FIELD.name = "role_id"
M_FRIEND_ADD_TOS_ROLE_ID_FIELD.full_name = ".m_friend_add_tos.role_id"
M_FRIEND_ADD_TOS_ROLE_ID_FIELD.number = 1
M_FRIEND_ADD_TOS_ROLE_ID_FIELD.index = 0
M_FRIEND_ADD_TOS_ROLE_ID_FIELD.label = 1
M_FRIEND_ADD_TOS_ROLE_ID_FIELD.has_default_value = true
M_FRIEND_ADD_TOS_ROLE_ID_FIELD.default_value = 0
M_FRIEND_ADD_TOS_ROLE_ID_FIELD.type = 3
M_FRIEND_ADD_TOS_ROLE_ID_FIELD.cpp_type = 2

M_FRIEND_ADD_TOS.name = "m_friend_add_tos"
M_FRIEND_ADD_TOS.full_name = ".m_friend_add_tos"
M_FRIEND_ADD_TOS.nested_types = {}
M_FRIEND_ADD_TOS.enum_types = {}
M_FRIEND_ADD_TOS.fields = {M_FRIEND_ADD_TOS_ROLE_ID_FIELD}
M_FRIEND_ADD_TOS.is_extendable = false
M_FRIEND_ADD_TOS.extensions = {}

m_friend_add_tos = protobuf.Message(M_FRIEND_ADD_TOS)

