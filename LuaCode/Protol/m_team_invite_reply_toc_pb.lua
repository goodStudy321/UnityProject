--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_team_invite_reply_toc_pb')

M_TEAM_INVITE_REPLY_TOC = protobuf.Descriptor();
M_TEAM_INVITE_REPLY_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_TEAM_INVITE_REPLY_TOC_OP_TYPE_FIELD = protobuf.FieldDescriptor();
M_TEAM_INVITE_REPLY_TOC_REPLY_ROLE_ID_FIELD = protobuf.FieldDescriptor();
M_TEAM_INVITE_REPLY_TOC_REPLY_ROLE_NAME_FIELD = protobuf.FieldDescriptor();

M_TEAM_INVITE_REPLY_TOC_ERR_CODE_FIELD.name = "err_code"
M_TEAM_INVITE_REPLY_TOC_ERR_CODE_FIELD.full_name = ".m_team_invite_reply_toc.err_code"
M_TEAM_INVITE_REPLY_TOC_ERR_CODE_FIELD.number = 1
M_TEAM_INVITE_REPLY_TOC_ERR_CODE_FIELD.index = 0
M_TEAM_INVITE_REPLY_TOC_ERR_CODE_FIELD.label = 1
M_TEAM_INVITE_REPLY_TOC_ERR_CODE_FIELD.has_default_value = true
M_TEAM_INVITE_REPLY_TOC_ERR_CODE_FIELD.default_value = 0
M_TEAM_INVITE_REPLY_TOC_ERR_CODE_FIELD.type = 5
M_TEAM_INVITE_REPLY_TOC_ERR_CODE_FIELD.cpp_type = 1

M_TEAM_INVITE_REPLY_TOC_OP_TYPE_FIELD.name = "op_type"
M_TEAM_INVITE_REPLY_TOC_OP_TYPE_FIELD.full_name = ".m_team_invite_reply_toc.op_type"
M_TEAM_INVITE_REPLY_TOC_OP_TYPE_FIELD.number = 2
M_TEAM_INVITE_REPLY_TOC_OP_TYPE_FIELD.index = 1
M_TEAM_INVITE_REPLY_TOC_OP_TYPE_FIELD.label = 1
M_TEAM_INVITE_REPLY_TOC_OP_TYPE_FIELD.has_default_value = true
M_TEAM_INVITE_REPLY_TOC_OP_TYPE_FIELD.default_value = 0
M_TEAM_INVITE_REPLY_TOC_OP_TYPE_FIELD.type = 5
M_TEAM_INVITE_REPLY_TOC_OP_TYPE_FIELD.cpp_type = 1

M_TEAM_INVITE_REPLY_TOC_REPLY_ROLE_ID_FIELD.name = "reply_role_id"
M_TEAM_INVITE_REPLY_TOC_REPLY_ROLE_ID_FIELD.full_name = ".m_team_invite_reply_toc.reply_role_id"
M_TEAM_INVITE_REPLY_TOC_REPLY_ROLE_ID_FIELD.number = 3
M_TEAM_INVITE_REPLY_TOC_REPLY_ROLE_ID_FIELD.index = 2
M_TEAM_INVITE_REPLY_TOC_REPLY_ROLE_ID_FIELD.label = 1
M_TEAM_INVITE_REPLY_TOC_REPLY_ROLE_ID_FIELD.has_default_value = true
M_TEAM_INVITE_REPLY_TOC_REPLY_ROLE_ID_FIELD.default_value = 0
M_TEAM_INVITE_REPLY_TOC_REPLY_ROLE_ID_FIELD.type = 3
M_TEAM_INVITE_REPLY_TOC_REPLY_ROLE_ID_FIELD.cpp_type = 2

M_TEAM_INVITE_REPLY_TOC_REPLY_ROLE_NAME_FIELD.name = "reply_role_name"
M_TEAM_INVITE_REPLY_TOC_REPLY_ROLE_NAME_FIELD.full_name = ".m_team_invite_reply_toc.reply_role_name"
M_TEAM_INVITE_REPLY_TOC_REPLY_ROLE_NAME_FIELD.number = 4
M_TEAM_INVITE_REPLY_TOC_REPLY_ROLE_NAME_FIELD.index = 3
M_TEAM_INVITE_REPLY_TOC_REPLY_ROLE_NAME_FIELD.label = 1
M_TEAM_INVITE_REPLY_TOC_REPLY_ROLE_NAME_FIELD.has_default_value = false
M_TEAM_INVITE_REPLY_TOC_REPLY_ROLE_NAME_FIELD.default_value = ""
M_TEAM_INVITE_REPLY_TOC_REPLY_ROLE_NAME_FIELD.type = 9
M_TEAM_INVITE_REPLY_TOC_REPLY_ROLE_NAME_FIELD.cpp_type = 9

M_TEAM_INVITE_REPLY_TOC.name = "m_team_invite_reply_toc"
M_TEAM_INVITE_REPLY_TOC.full_name = ".m_team_invite_reply_toc"
M_TEAM_INVITE_REPLY_TOC.nested_types = {}
M_TEAM_INVITE_REPLY_TOC.enum_types = {}
M_TEAM_INVITE_REPLY_TOC.fields = {M_TEAM_INVITE_REPLY_TOC_ERR_CODE_FIELD, M_TEAM_INVITE_REPLY_TOC_OP_TYPE_FIELD, M_TEAM_INVITE_REPLY_TOC_REPLY_ROLE_ID_FIELD, M_TEAM_INVITE_REPLY_TOC_REPLY_ROLE_NAME_FIELD}
M_TEAM_INVITE_REPLY_TOC.is_extendable = false
M_TEAM_INVITE_REPLY_TOC.extensions = {}

m_team_invite_reply_toc = protobuf.Message(M_TEAM_INVITE_REPLY_TOC)

