--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_team_invite_reply_tos_pb')

M_TEAM_INVITE_REPLY_TOS = protobuf.Descriptor();
M_TEAM_INVITE_REPLY_TOS_OP_TYPE_FIELD = protobuf.FieldDescriptor();
M_TEAM_INVITE_REPLY_TOS_TEAM_ID_FIELD = protobuf.FieldDescriptor();
M_TEAM_INVITE_REPLY_TOS_ROLE_ID_FIELD = protobuf.FieldDescriptor();

M_TEAM_INVITE_REPLY_TOS_OP_TYPE_FIELD.name = "op_type"
M_TEAM_INVITE_REPLY_TOS_OP_TYPE_FIELD.full_name = ".m_team_invite_reply_tos.op_type"
M_TEAM_INVITE_REPLY_TOS_OP_TYPE_FIELD.number = 1
M_TEAM_INVITE_REPLY_TOS_OP_TYPE_FIELD.index = 0
M_TEAM_INVITE_REPLY_TOS_OP_TYPE_FIELD.label = 1
M_TEAM_INVITE_REPLY_TOS_OP_TYPE_FIELD.has_default_value = true
M_TEAM_INVITE_REPLY_TOS_OP_TYPE_FIELD.default_value = 0
M_TEAM_INVITE_REPLY_TOS_OP_TYPE_FIELD.type = 5
M_TEAM_INVITE_REPLY_TOS_OP_TYPE_FIELD.cpp_type = 1

M_TEAM_INVITE_REPLY_TOS_TEAM_ID_FIELD.name = "team_id"
M_TEAM_INVITE_REPLY_TOS_TEAM_ID_FIELD.full_name = ".m_team_invite_reply_tos.team_id"
M_TEAM_INVITE_REPLY_TOS_TEAM_ID_FIELD.number = 2
M_TEAM_INVITE_REPLY_TOS_TEAM_ID_FIELD.index = 1
M_TEAM_INVITE_REPLY_TOS_TEAM_ID_FIELD.label = 1
M_TEAM_INVITE_REPLY_TOS_TEAM_ID_FIELD.has_default_value = true
M_TEAM_INVITE_REPLY_TOS_TEAM_ID_FIELD.default_value = 0
M_TEAM_INVITE_REPLY_TOS_TEAM_ID_FIELD.type = 5
M_TEAM_INVITE_REPLY_TOS_TEAM_ID_FIELD.cpp_type = 1

M_TEAM_INVITE_REPLY_TOS_ROLE_ID_FIELD.name = "role_id"
M_TEAM_INVITE_REPLY_TOS_ROLE_ID_FIELD.full_name = ".m_team_invite_reply_tos.role_id"
M_TEAM_INVITE_REPLY_TOS_ROLE_ID_FIELD.number = 3
M_TEAM_INVITE_REPLY_TOS_ROLE_ID_FIELD.index = 2
M_TEAM_INVITE_REPLY_TOS_ROLE_ID_FIELD.label = 1
M_TEAM_INVITE_REPLY_TOS_ROLE_ID_FIELD.has_default_value = true
M_TEAM_INVITE_REPLY_TOS_ROLE_ID_FIELD.default_value = 0
M_TEAM_INVITE_REPLY_TOS_ROLE_ID_FIELD.type = 3
M_TEAM_INVITE_REPLY_TOS_ROLE_ID_FIELD.cpp_type = 2

M_TEAM_INVITE_REPLY_TOS.name = "m_team_invite_reply_tos"
M_TEAM_INVITE_REPLY_TOS.full_name = ".m_team_invite_reply_tos"
M_TEAM_INVITE_REPLY_TOS.nested_types = {}
M_TEAM_INVITE_REPLY_TOS.enum_types = {}
M_TEAM_INVITE_REPLY_TOS.fields = {M_TEAM_INVITE_REPLY_TOS_OP_TYPE_FIELD, M_TEAM_INVITE_REPLY_TOS_TEAM_ID_FIELD, M_TEAM_INVITE_REPLY_TOS_ROLE_ID_FIELD}
M_TEAM_INVITE_REPLY_TOS.is_extendable = false
M_TEAM_INVITE_REPLY_TOS.extensions = {}

m_team_invite_reply_tos = protobuf.Message(M_TEAM_INVITE_REPLY_TOS)

