--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_pet_level_up_tos_pb')

M_PET_LEVEL_UP_TOS = protobuf.Descriptor();
M_PET_LEVEL_UP_TOS_GOODS_LIST_FIELD = protobuf.FieldDescriptor();

M_PET_LEVEL_UP_TOS_GOODS_LIST_FIELD.name = "goods_list"
M_PET_LEVEL_UP_TOS_GOODS_LIST_FIELD.full_name = ".m_pet_level_up_tos.goods_list"
M_PET_LEVEL_UP_TOS_GOODS_LIST_FIELD.number = 1
M_PET_LEVEL_UP_TOS_GOODS_LIST_FIELD.index = 0
M_PET_LEVEL_UP_TOS_GOODS_LIST_FIELD.label = 3
M_PET_LEVEL_UP_TOS_GOODS_LIST_FIELD.has_default_value = false
M_PET_LEVEL_UP_TOS_GOODS_LIST_FIELD.default_value = {}
M_PET_LEVEL_UP_TOS_GOODS_LIST_FIELD.type = 5
M_PET_LEVEL_UP_TOS_GOODS_LIST_FIELD.cpp_type = 1

M_PET_LEVEL_UP_TOS.name = "m_pet_level_up_tos"
M_PET_LEVEL_UP_TOS.full_name = ".m_pet_level_up_tos"
M_PET_LEVEL_UP_TOS.nested_types = {}
M_PET_LEVEL_UP_TOS.enum_types = {}
M_PET_LEVEL_UP_TOS.fields = {M_PET_LEVEL_UP_TOS_GOODS_LIST_FIELD}
M_PET_LEVEL_UP_TOS.is_extendable = false
M_PET_LEVEL_UP_TOS.extensions = {}

m_pet_level_up_tos = protobuf.Message(M_PET_LEVEL_UP_TOS)

