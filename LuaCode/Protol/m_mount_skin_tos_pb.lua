--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_mount_skin_tos_pb')

M_MOUNT_SKIN_TOS = protobuf.Descriptor();
M_MOUNT_SKIN_TOS_SKIN_ID_FIELD = protobuf.FieldDescriptor();

M_MOUNT_SKIN_TOS_SKIN_ID_FIELD.name = "skin_id"
M_MOUNT_SKIN_TOS_SKIN_ID_FIELD.full_name = ".m_mount_skin_tos.skin_id"
M_MOUNT_SKIN_TOS_SKIN_ID_FIELD.number = 1
M_MOUNT_SKIN_TOS_SKIN_ID_FIELD.index = 0
M_MOUNT_SKIN_TOS_SKIN_ID_FIELD.label = 1
M_MOUNT_SKIN_TOS_SKIN_ID_FIELD.has_default_value = true
M_MOUNT_SKIN_TOS_SKIN_ID_FIELD.default_value = 0
M_MOUNT_SKIN_TOS_SKIN_ID_FIELD.type = 5
M_MOUNT_SKIN_TOS_SKIN_ID_FIELD.cpp_type = 1

M_MOUNT_SKIN_TOS.name = "m_mount_skin_tos"
M_MOUNT_SKIN_TOS.full_name = ".m_mount_skin_tos"
M_MOUNT_SKIN_TOS.nested_types = {}
M_MOUNT_SKIN_TOS.enum_types = {}
M_MOUNT_SKIN_TOS.fields = {M_MOUNT_SKIN_TOS_SKIN_ID_FIELD}
M_MOUNT_SKIN_TOS.is_extendable = false
M_MOUNT_SKIN_TOS.extensions = {}

m_mount_skin_tos = protobuf.Message(M_MOUNT_SKIN_TOS)

