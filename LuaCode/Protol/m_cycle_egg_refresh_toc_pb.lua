--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_egg_pb = require("Protol.p_egg_pb")
module('Protol.m_cycle_egg_refresh_toc_pb')

M_CYCLE_EGG_REFRESH_TOC = protobuf.Descriptor();
M_CYCLE_EGG_REFRESH_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_CYCLE_EGG_REFRESH_TOC_EGGS_FIELD = protobuf.FieldDescriptor();
M_CYCLE_EGG_REFRESH_TOC_CAN_REFRESH_FIELD = protobuf.FieldDescriptor();

M_CYCLE_EGG_REFRESH_TOC_ERR_CODE_FIELD.name = "err_code"
M_CYCLE_EGG_REFRESH_TOC_ERR_CODE_FIELD.full_name = ".m_cycle_egg_refresh_toc.err_code"
M_CYCLE_EGG_REFRESH_TOC_ERR_CODE_FIELD.number = 1
M_CYCLE_EGG_REFRESH_TOC_ERR_CODE_FIELD.index = 0
M_CYCLE_EGG_REFRESH_TOC_ERR_CODE_FIELD.label = 1
M_CYCLE_EGG_REFRESH_TOC_ERR_CODE_FIELD.has_default_value = true
M_CYCLE_EGG_REFRESH_TOC_ERR_CODE_FIELD.default_value = 0
M_CYCLE_EGG_REFRESH_TOC_ERR_CODE_FIELD.type = 5
M_CYCLE_EGG_REFRESH_TOC_ERR_CODE_FIELD.cpp_type = 1

M_CYCLE_EGG_REFRESH_TOC_EGGS_FIELD.name = "eggs"
M_CYCLE_EGG_REFRESH_TOC_EGGS_FIELD.full_name = ".m_cycle_egg_refresh_toc.eggs"
M_CYCLE_EGG_REFRESH_TOC_EGGS_FIELD.number = 2
M_CYCLE_EGG_REFRESH_TOC_EGGS_FIELD.index = 1
M_CYCLE_EGG_REFRESH_TOC_EGGS_FIELD.label = 3
M_CYCLE_EGG_REFRESH_TOC_EGGS_FIELD.has_default_value = false
M_CYCLE_EGG_REFRESH_TOC_EGGS_FIELD.default_value = {}
M_CYCLE_EGG_REFRESH_TOC_EGGS_FIELD.message_type = p_egg_pb.P_EGG
M_CYCLE_EGG_REFRESH_TOC_EGGS_FIELD.type = 11
M_CYCLE_EGG_REFRESH_TOC_EGGS_FIELD.cpp_type = 10

M_CYCLE_EGG_REFRESH_TOC_CAN_REFRESH_FIELD.name = "can_refresh"
M_CYCLE_EGG_REFRESH_TOC_CAN_REFRESH_FIELD.full_name = ".m_cycle_egg_refresh_toc.can_refresh"
M_CYCLE_EGG_REFRESH_TOC_CAN_REFRESH_FIELD.number = 3
M_CYCLE_EGG_REFRESH_TOC_CAN_REFRESH_FIELD.index = 2
M_CYCLE_EGG_REFRESH_TOC_CAN_REFRESH_FIELD.label = 1
M_CYCLE_EGG_REFRESH_TOC_CAN_REFRESH_FIELD.has_default_value = true
M_CYCLE_EGG_REFRESH_TOC_CAN_REFRESH_FIELD.default_value = true
M_CYCLE_EGG_REFRESH_TOC_CAN_REFRESH_FIELD.type = 8
M_CYCLE_EGG_REFRESH_TOC_CAN_REFRESH_FIELD.cpp_type = 7

M_CYCLE_EGG_REFRESH_TOC.name = "m_cycle_egg_refresh_toc"
M_CYCLE_EGG_REFRESH_TOC.full_name = ".m_cycle_egg_refresh_toc"
M_CYCLE_EGG_REFRESH_TOC.nested_types = {}
M_CYCLE_EGG_REFRESH_TOC.enum_types = {}
M_CYCLE_EGG_REFRESH_TOC.fields = {M_CYCLE_EGG_REFRESH_TOC_ERR_CODE_FIELD, M_CYCLE_EGG_REFRESH_TOC_EGGS_FIELD, M_CYCLE_EGG_REFRESH_TOC_CAN_REFRESH_FIELD}
M_CYCLE_EGG_REFRESH_TOC.is_extendable = false
M_CYCLE_EGG_REFRESH_TOC.extensions = {}

m_cycle_egg_refresh_toc = protobuf.Message(M_CYCLE_EGG_REFRESH_TOC)

