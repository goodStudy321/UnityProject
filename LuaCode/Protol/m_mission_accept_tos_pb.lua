--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_mission_accept_tos_pb')

M_MISSION_ACCEPT_TOS = protobuf.Descriptor();
M_MISSION_ACCEPT_TOS_MISSION_ID_FIELD = protobuf.FieldDescriptor();

M_MISSION_ACCEPT_TOS_MISSION_ID_FIELD.name = "mission_id"
M_MISSION_ACCEPT_TOS_MISSION_ID_FIELD.full_name = ".m_mission_accept_tos.mission_id"
M_MISSION_ACCEPT_TOS_MISSION_ID_FIELD.number = 1
M_MISSION_ACCEPT_TOS_MISSION_ID_FIELD.index = 0
M_MISSION_ACCEPT_TOS_MISSION_ID_FIELD.label = 1
M_MISSION_ACCEPT_TOS_MISSION_ID_FIELD.has_default_value = true
M_MISSION_ACCEPT_TOS_MISSION_ID_FIELD.default_value = 0
M_MISSION_ACCEPT_TOS_MISSION_ID_FIELD.type = 5
M_MISSION_ACCEPT_TOS_MISSION_ID_FIELD.cpp_type = 1

M_MISSION_ACCEPT_TOS.name = "m_mission_accept_tos"
M_MISSION_ACCEPT_TOS.full_name = ".m_mission_accept_tos"
M_MISSION_ACCEPT_TOS.nested_types = {}
M_MISSION_ACCEPT_TOS.enum_types = {}
M_MISSION_ACCEPT_TOS.fields = {M_MISSION_ACCEPT_TOS_MISSION_ID_FIELD}
M_MISSION_ACCEPT_TOS.is_extendable = false
M_MISSION_ACCEPT_TOS.extensions = {}

m_mission_accept_tos = protobuf.Message(M_MISSION_ACCEPT_TOS)

