--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_team_match_tos_pb')

M_TEAM_MATCH_TOS = protobuf.Descriptor();
M_TEAM_MATCH_TOS_COPY_ID_FIELD = protobuf.FieldDescriptor();
M_TEAM_MATCH_TOS_MATCHING_FIELD = protobuf.FieldDescriptor();

M_TEAM_MATCH_TOS_COPY_ID_FIELD.name = "copy_id"
M_TEAM_MATCH_TOS_COPY_ID_FIELD.full_name = ".m_team_match_tos.copy_id"
M_TEAM_MATCH_TOS_COPY_ID_FIELD.number = 1
M_TEAM_MATCH_TOS_COPY_ID_FIELD.index = 0
M_TEAM_MATCH_TOS_COPY_ID_FIELD.label = 1
M_TEAM_MATCH_TOS_COPY_ID_FIELD.has_default_value = true
M_TEAM_MATCH_TOS_COPY_ID_FIELD.default_value = 0
M_TEAM_MATCH_TOS_COPY_ID_FIELD.type = 5
M_TEAM_MATCH_TOS_COPY_ID_FIELD.cpp_type = 1

M_TEAM_MATCH_TOS_MATCHING_FIELD.name = "matching"
M_TEAM_MATCH_TOS_MATCHING_FIELD.full_name = ".m_team_match_tos.matching"
M_TEAM_MATCH_TOS_MATCHING_FIELD.number = 2
M_TEAM_MATCH_TOS_MATCHING_FIELD.index = 1
M_TEAM_MATCH_TOS_MATCHING_FIELD.label = 1
M_TEAM_MATCH_TOS_MATCHING_FIELD.has_default_value = true
M_TEAM_MATCH_TOS_MATCHING_FIELD.default_value = true
M_TEAM_MATCH_TOS_MATCHING_FIELD.type = 8
M_TEAM_MATCH_TOS_MATCHING_FIELD.cpp_type = 7

M_TEAM_MATCH_TOS.name = "m_team_match_tos"
M_TEAM_MATCH_TOS.full_name = ".m_team_match_tos"
M_TEAM_MATCH_TOS.nested_types = {}
M_TEAM_MATCH_TOS.enum_types = {}
M_TEAM_MATCH_TOS.fields = {M_TEAM_MATCH_TOS_COPY_ID_FIELD, M_TEAM_MATCH_TOS_MATCHING_FIELD}
M_TEAM_MATCH_TOS.is_extendable = false
M_TEAM_MATCH_TOS.extensions = {}

m_team_match_tos = protobuf.Message(M_TEAM_MATCH_TOS)

