--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_mission_one_key_tos_pb')

M_MISSION_ONE_KEY_TOS = protobuf.Descriptor();
M_MISSION_ONE_KEY_TOS_TYPE_FIELD = protobuf.FieldDescriptor();

M_MISSION_ONE_KEY_TOS_TYPE_FIELD.name = "type"
M_MISSION_ONE_KEY_TOS_TYPE_FIELD.full_name = ".m_mission_one_key_tos.type"
M_MISSION_ONE_KEY_TOS_TYPE_FIELD.number = 1
M_MISSION_ONE_KEY_TOS_TYPE_FIELD.index = 0
M_MISSION_ONE_KEY_TOS_TYPE_FIELD.label = 1
M_MISSION_ONE_KEY_TOS_TYPE_FIELD.has_default_value = true
M_MISSION_ONE_KEY_TOS_TYPE_FIELD.default_value = 0
M_MISSION_ONE_KEY_TOS_TYPE_FIELD.type = 5
M_MISSION_ONE_KEY_TOS_TYPE_FIELD.cpp_type = 1

M_MISSION_ONE_KEY_TOS.name = "m_mission_one_key_tos"
M_MISSION_ONE_KEY_TOS.full_name = ".m_mission_one_key_tos"
M_MISSION_ONE_KEY_TOS.nested_types = {}
M_MISSION_ONE_KEY_TOS.enum_types = {}
M_MISSION_ONE_KEY_TOS.fields = {M_MISSION_ONE_KEY_TOS_TYPE_FIELD}
M_MISSION_ONE_KEY_TOS.is_extendable = false
M_MISSION_ONE_KEY_TOS.extensions = {}

m_mission_one_key_tos = protobuf.Message(M_MISSION_ONE_KEY_TOS)
