--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_mount_surface_step_tos_pb')

M_MOUNT_SURFACE_STEP_TOS = protobuf.Descriptor();
M_MOUNT_SURFACE_STEP_TOS_BASE_ID_FIELD = protobuf.FieldDescriptor();
M_MOUNT_SURFACE_STEP_TOS_ITEM_ID_FIELD = protobuf.FieldDescriptor();
M_MOUNT_SURFACE_STEP_TOS_ITEM_NUM_FIELD = protobuf.FieldDescriptor();

M_MOUNT_SURFACE_STEP_TOS_BASE_ID_FIELD.name = "base_id"
M_MOUNT_SURFACE_STEP_TOS_BASE_ID_FIELD.full_name = ".m_mount_surface_step_tos.base_id"
M_MOUNT_SURFACE_STEP_TOS_BASE_ID_FIELD.number = 1
M_MOUNT_SURFACE_STEP_TOS_BASE_ID_FIELD.index = 0
M_MOUNT_SURFACE_STEP_TOS_BASE_ID_FIELD.label = 1
M_MOUNT_SURFACE_STEP_TOS_BASE_ID_FIELD.has_default_value = true
M_MOUNT_SURFACE_STEP_TOS_BASE_ID_FIELD.default_value = 0
M_MOUNT_SURFACE_STEP_TOS_BASE_ID_FIELD.type = 5
M_MOUNT_SURFACE_STEP_TOS_BASE_ID_FIELD.cpp_type = 1

M_MOUNT_SURFACE_STEP_TOS_ITEM_ID_FIELD.name = "item_id"
M_MOUNT_SURFACE_STEP_TOS_ITEM_ID_FIELD.full_name = ".m_mount_surface_step_tos.item_id"
M_MOUNT_SURFACE_STEP_TOS_ITEM_ID_FIELD.number = 2
M_MOUNT_SURFACE_STEP_TOS_ITEM_ID_FIELD.index = 1
M_MOUNT_SURFACE_STEP_TOS_ITEM_ID_FIELD.label = 1
M_MOUNT_SURFACE_STEP_TOS_ITEM_ID_FIELD.has_default_value = true
M_MOUNT_SURFACE_STEP_TOS_ITEM_ID_FIELD.default_value = 0
M_MOUNT_SURFACE_STEP_TOS_ITEM_ID_FIELD.type = 5
M_MOUNT_SURFACE_STEP_TOS_ITEM_ID_FIELD.cpp_type = 1

M_MOUNT_SURFACE_STEP_TOS_ITEM_NUM_FIELD.name = "item_num"
M_MOUNT_SURFACE_STEP_TOS_ITEM_NUM_FIELD.full_name = ".m_mount_surface_step_tos.item_num"
M_MOUNT_SURFACE_STEP_TOS_ITEM_NUM_FIELD.number = 3
M_MOUNT_SURFACE_STEP_TOS_ITEM_NUM_FIELD.index = 2
M_MOUNT_SURFACE_STEP_TOS_ITEM_NUM_FIELD.label = 1
M_MOUNT_SURFACE_STEP_TOS_ITEM_NUM_FIELD.has_default_value = true
M_MOUNT_SURFACE_STEP_TOS_ITEM_NUM_FIELD.default_value = 0
M_MOUNT_SURFACE_STEP_TOS_ITEM_NUM_FIELD.type = 5
M_MOUNT_SURFACE_STEP_TOS_ITEM_NUM_FIELD.cpp_type = 1

M_MOUNT_SURFACE_STEP_TOS.name = "m_mount_surface_step_tos"
M_MOUNT_SURFACE_STEP_TOS.full_name = ".m_mount_surface_step_tos"
M_MOUNT_SURFACE_STEP_TOS.nested_types = {}
M_MOUNT_SURFACE_STEP_TOS.enum_types = {}
M_MOUNT_SURFACE_STEP_TOS.fields = {M_MOUNT_SURFACE_STEP_TOS_BASE_ID_FIELD, M_MOUNT_SURFACE_STEP_TOS_ITEM_ID_FIELD, M_MOUNT_SURFACE_STEP_TOS_ITEM_NUM_FIELD}
M_MOUNT_SURFACE_STEP_TOS.is_extendable = false
M_MOUNT_SURFACE_STEP_TOS.extensions = {}

m_mount_surface_step_tos = protobuf.Message(M_MOUNT_SURFACE_STEP_TOS)

