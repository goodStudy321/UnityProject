--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_mythical_equip_status_tos_pb')

M_MYTHICAL_EQUIP_STATUS_TOS = protobuf.Descriptor();
M_MYTHICAL_EQUIP_STATUS_TOS_SOUL_ID_FIELD = protobuf.FieldDescriptor();
M_MYTHICAL_EQUIP_STATUS_TOS_STATUS_FIELD = protobuf.FieldDescriptor();

M_MYTHICAL_EQUIP_STATUS_TOS_SOUL_ID_FIELD.name = "soul_id"
M_MYTHICAL_EQUIP_STATUS_TOS_SOUL_ID_FIELD.full_name = ".m_mythical_equip_status_tos.soul_id"
M_MYTHICAL_EQUIP_STATUS_TOS_SOUL_ID_FIELD.number = 1
M_MYTHICAL_EQUIP_STATUS_TOS_SOUL_ID_FIELD.index = 0
M_MYTHICAL_EQUIP_STATUS_TOS_SOUL_ID_FIELD.label = 1
M_MYTHICAL_EQUIP_STATUS_TOS_SOUL_ID_FIELD.has_default_value = true
M_MYTHICAL_EQUIP_STATUS_TOS_SOUL_ID_FIELD.default_value = 0
M_MYTHICAL_EQUIP_STATUS_TOS_SOUL_ID_FIELD.type = 5
M_MYTHICAL_EQUIP_STATUS_TOS_SOUL_ID_FIELD.cpp_type = 1

M_MYTHICAL_EQUIP_STATUS_TOS_STATUS_FIELD.name = "status"
M_MYTHICAL_EQUIP_STATUS_TOS_STATUS_FIELD.full_name = ".m_mythical_equip_status_tos.status"
M_MYTHICAL_EQUIP_STATUS_TOS_STATUS_FIELD.number = 2
M_MYTHICAL_EQUIP_STATUS_TOS_STATUS_FIELD.index = 1
M_MYTHICAL_EQUIP_STATUS_TOS_STATUS_FIELD.label = 1
M_MYTHICAL_EQUIP_STATUS_TOS_STATUS_FIELD.has_default_value = true
M_MYTHICAL_EQUIP_STATUS_TOS_STATUS_FIELD.default_value = 0
M_MYTHICAL_EQUIP_STATUS_TOS_STATUS_FIELD.type = 5
M_MYTHICAL_EQUIP_STATUS_TOS_STATUS_FIELD.cpp_type = 1

M_MYTHICAL_EQUIP_STATUS_TOS.name = "m_mythical_equip_status_tos"
M_MYTHICAL_EQUIP_STATUS_TOS.full_name = ".m_mythical_equip_status_tos"
M_MYTHICAL_EQUIP_STATUS_TOS.nested_types = {}
M_MYTHICAL_EQUIP_STATUS_TOS.enum_types = {}
M_MYTHICAL_EQUIP_STATUS_TOS.fields = {M_MYTHICAL_EQUIP_STATUS_TOS_SOUL_ID_FIELD, M_MYTHICAL_EQUIP_STATUS_TOS_STATUS_FIELD}
M_MYTHICAL_EQUIP_STATUS_TOS.is_extendable = false
M_MYTHICAL_EQUIP_STATUS_TOS.extensions = {}

m_mythical_equip_status_tos = protobuf.Message(M_MYTHICAL_EQUIP_STATUS_TOS)
