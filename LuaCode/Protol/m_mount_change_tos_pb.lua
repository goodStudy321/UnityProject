--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_mount_change_tos_pb')

M_MOUNT_CHANGE_TOS = protobuf.Descriptor();
M_MOUNT_CHANGE_TOS_CUR_ID_FIELD = protobuf.FieldDescriptor();

M_MOUNT_CHANGE_TOS_CUR_ID_FIELD.name = "cur_id"
M_MOUNT_CHANGE_TOS_CUR_ID_FIELD.full_name = ".m_mount_change_tos.cur_id"
M_MOUNT_CHANGE_TOS_CUR_ID_FIELD.number = 1
M_MOUNT_CHANGE_TOS_CUR_ID_FIELD.index = 0
M_MOUNT_CHANGE_TOS_CUR_ID_FIELD.label = 1
M_MOUNT_CHANGE_TOS_CUR_ID_FIELD.has_default_value = true
M_MOUNT_CHANGE_TOS_CUR_ID_FIELD.default_value = 0
M_MOUNT_CHANGE_TOS_CUR_ID_FIELD.type = 5
M_MOUNT_CHANGE_TOS_CUR_ID_FIELD.cpp_type = 1

M_MOUNT_CHANGE_TOS.name = "m_mount_change_tos"
M_MOUNT_CHANGE_TOS.full_name = ".m_mount_change_tos"
M_MOUNT_CHANGE_TOS.nested_types = {}
M_MOUNT_CHANGE_TOS.enum_types = {}
M_MOUNT_CHANGE_TOS.fields = {M_MOUNT_CHANGE_TOS_CUR_ID_FIELD}
M_MOUNT_CHANGE_TOS.is_extendable = false
M_MOUNT_CHANGE_TOS.extensions = {}

m_mount_change_tos = protobuf.Message(M_MOUNT_CHANGE_TOS)

