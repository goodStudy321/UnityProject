--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_solo_match_tos_pb')

M_SOLO_MATCH_TOS = protobuf.Descriptor();
M_SOLO_MATCH_TOS_TYPE_FIELD = protobuf.FieldDescriptor();

M_SOLO_MATCH_TOS_TYPE_FIELD.name = "type"
M_SOLO_MATCH_TOS_TYPE_FIELD.full_name = ".m_solo_match_tos.type"
M_SOLO_MATCH_TOS_TYPE_FIELD.number = 1
M_SOLO_MATCH_TOS_TYPE_FIELD.index = 0
M_SOLO_MATCH_TOS_TYPE_FIELD.label = 1
M_SOLO_MATCH_TOS_TYPE_FIELD.has_default_value = true
M_SOLO_MATCH_TOS_TYPE_FIELD.default_value = 0
M_SOLO_MATCH_TOS_TYPE_FIELD.type = 5
M_SOLO_MATCH_TOS_TYPE_FIELD.cpp_type = 1

M_SOLO_MATCH_TOS.name = "m_solo_match_tos"
M_SOLO_MATCH_TOS.full_name = ".m_solo_match_tos"
M_SOLO_MATCH_TOS.nested_types = {}
M_SOLO_MATCH_TOS.enum_types = {}
M_SOLO_MATCH_TOS.fields = {M_SOLO_MATCH_TOS_TYPE_FIELD}
M_SOLO_MATCH_TOS.is_extendable = false
M_SOLO_MATCH_TOS.extensions = {}

m_solo_match_tos = protobuf.Message(M_SOLO_MATCH_TOS)
