--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_role_addict_auth_tos_pb')

M_ROLE_ADDICT_AUTH_TOS = protobuf.Descriptor();
M_ROLE_ADDICT_AUTH_TOS_ID_CARD_FIELD = protobuf.FieldDescriptor();
M_ROLE_ADDICT_AUTH_TOS_REAL_NAME_FIELD = protobuf.FieldDescriptor();

M_ROLE_ADDICT_AUTH_TOS_ID_CARD_FIELD.name = "id_card"
M_ROLE_ADDICT_AUTH_TOS_ID_CARD_FIELD.full_name = ".m_role_addict_auth_tos.id_card"
M_ROLE_ADDICT_AUTH_TOS_ID_CARD_FIELD.number = 1
M_ROLE_ADDICT_AUTH_TOS_ID_CARD_FIELD.index = 0
M_ROLE_ADDICT_AUTH_TOS_ID_CARD_FIELD.label = 1
M_ROLE_ADDICT_AUTH_TOS_ID_CARD_FIELD.has_default_value = false
M_ROLE_ADDICT_AUTH_TOS_ID_CARD_FIELD.default_value = ""
M_ROLE_ADDICT_AUTH_TOS_ID_CARD_FIELD.type = 9
M_ROLE_ADDICT_AUTH_TOS_ID_CARD_FIELD.cpp_type = 9

M_ROLE_ADDICT_AUTH_TOS_REAL_NAME_FIELD.name = "real_name"
M_ROLE_ADDICT_AUTH_TOS_REAL_NAME_FIELD.full_name = ".m_role_addict_auth_tos.real_name"
M_ROLE_ADDICT_AUTH_TOS_REAL_NAME_FIELD.number = 2
M_ROLE_ADDICT_AUTH_TOS_REAL_NAME_FIELD.index = 1
M_ROLE_ADDICT_AUTH_TOS_REAL_NAME_FIELD.label = 1
M_ROLE_ADDICT_AUTH_TOS_REAL_NAME_FIELD.has_default_value = false
M_ROLE_ADDICT_AUTH_TOS_REAL_NAME_FIELD.default_value = ""
M_ROLE_ADDICT_AUTH_TOS_REAL_NAME_FIELD.type = 9
M_ROLE_ADDICT_AUTH_TOS_REAL_NAME_FIELD.cpp_type = 9

M_ROLE_ADDICT_AUTH_TOS.name = "m_role_addict_auth_tos"
M_ROLE_ADDICT_AUTH_TOS.full_name = ".m_role_addict_auth_tos"
M_ROLE_ADDICT_AUTH_TOS.nested_types = {}
M_ROLE_ADDICT_AUTH_TOS.enum_types = {}
M_ROLE_ADDICT_AUTH_TOS.fields = {M_ROLE_ADDICT_AUTH_TOS_ID_CARD_FIELD, M_ROLE_ADDICT_AUTH_TOS_REAL_NAME_FIELD}
M_ROLE_ADDICT_AUTH_TOS.is_extendable = false
M_ROLE_ADDICT_AUTH_TOS.extensions = {}

m_role_addict_auth_tos = protobuf.Message(M_ROLE_ADDICT_AUTH_TOS)

