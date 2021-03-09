--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_egg_pb = require("Protol.p_egg_pb")
local p_kv_pb = require("Protol.p_kv_pb")
local p_kvs_pb = require("Protol.p_kvs_pb")
module('Protol.m_cycle_egg_toc_pb')

M_CYCLE_EGG_TOC = protobuf.Descriptor();
M_CYCLE_EGG_TOC_EGGS_FIELD = protobuf.FieldDescriptor();
M_CYCLE_EGG_TOC_CAN_REFRESH_FIELD = protobuf.FieldDescriptor();
M_CYCLE_EGG_TOC_OPEN_TIMES_FIELD = protobuf.FieldDescriptor();
M_CYCLE_EGG_TOC_LIST_FIELD = protobuf.FieldDescriptor();
M_CYCLE_EGG_TOC_A_LOG_FIELD = protobuf.FieldDescriptor();
M_CYCLE_EGG_TOC_B_LOG_FIELD = protobuf.FieldDescriptor();

M_CYCLE_EGG_TOC_EGGS_FIELD.name = "eggs"
M_CYCLE_EGG_TOC_EGGS_FIELD.full_name = ".m_cycle_egg_toc.eggs"
M_CYCLE_EGG_TOC_EGGS_FIELD.number = 1
M_CYCLE_EGG_TOC_EGGS_FIELD.index = 0
M_CYCLE_EGG_TOC_EGGS_FIELD.label = 3
M_CYCLE_EGG_TOC_EGGS_FIELD.has_default_value = false
M_CYCLE_EGG_TOC_EGGS_FIELD.default_value = {}
M_CYCLE_EGG_TOC_EGGS_FIELD.message_type = p_egg_pb.P_EGG
M_CYCLE_EGG_TOC_EGGS_FIELD.type = 11
M_CYCLE_EGG_TOC_EGGS_FIELD.cpp_type = 10

M_CYCLE_EGG_TOC_CAN_REFRESH_FIELD.name = "can_refresh"
M_CYCLE_EGG_TOC_CAN_REFRESH_FIELD.full_name = ".m_cycle_egg_toc.can_refresh"
M_CYCLE_EGG_TOC_CAN_REFRESH_FIELD.number = 2
M_CYCLE_EGG_TOC_CAN_REFRESH_FIELD.index = 1
M_CYCLE_EGG_TOC_CAN_REFRESH_FIELD.label = 1
M_CYCLE_EGG_TOC_CAN_REFRESH_FIELD.has_default_value = true
M_CYCLE_EGG_TOC_CAN_REFRESH_FIELD.default_value = true
M_CYCLE_EGG_TOC_CAN_REFRESH_FIELD.type = 8
M_CYCLE_EGG_TOC_CAN_REFRESH_FIELD.cpp_type = 7

M_CYCLE_EGG_TOC_OPEN_TIMES_FIELD.name = "open_times"
M_CYCLE_EGG_TOC_OPEN_TIMES_FIELD.full_name = ".m_cycle_egg_toc.open_times"
M_CYCLE_EGG_TOC_OPEN_TIMES_FIELD.number = 3
M_CYCLE_EGG_TOC_OPEN_TIMES_FIELD.index = 2
M_CYCLE_EGG_TOC_OPEN_TIMES_FIELD.label = 1
M_CYCLE_EGG_TOC_OPEN_TIMES_FIELD.has_default_value = true
M_CYCLE_EGG_TOC_OPEN_TIMES_FIELD.default_value = 0
M_CYCLE_EGG_TOC_OPEN_TIMES_FIELD.type = 5
M_CYCLE_EGG_TOC_OPEN_TIMES_FIELD.cpp_type = 1

M_CYCLE_EGG_TOC_LIST_FIELD.name = "list"
M_CYCLE_EGG_TOC_LIST_FIELD.full_name = ".m_cycle_egg_toc.list"
M_CYCLE_EGG_TOC_LIST_FIELD.number = 4
M_CYCLE_EGG_TOC_LIST_FIELD.index = 3
M_CYCLE_EGG_TOC_LIST_FIELD.label = 3
M_CYCLE_EGG_TOC_LIST_FIELD.has_default_value = false
M_CYCLE_EGG_TOC_LIST_FIELD.default_value = {}
M_CYCLE_EGG_TOC_LIST_FIELD.message_type = p_kv_pb.P_KV
M_CYCLE_EGG_TOC_LIST_FIELD.type = 11
M_CYCLE_EGG_TOC_LIST_FIELD.cpp_type = 10

M_CYCLE_EGG_TOC_A_LOG_FIELD.name = "a_log"
M_CYCLE_EGG_TOC_A_LOG_FIELD.full_name = ".m_cycle_egg_toc.a_log"
M_CYCLE_EGG_TOC_A_LOG_FIELD.number = 5
M_CYCLE_EGG_TOC_A_LOG_FIELD.index = 4
M_CYCLE_EGG_TOC_A_LOG_FIELD.label = 3
M_CYCLE_EGG_TOC_A_LOG_FIELD.has_default_value = false
M_CYCLE_EGG_TOC_A_LOG_FIELD.default_value = {}
M_CYCLE_EGG_TOC_A_LOG_FIELD.message_type = p_kvs_pb.P_KVS
M_CYCLE_EGG_TOC_A_LOG_FIELD.type = 11
M_CYCLE_EGG_TOC_A_LOG_FIELD.cpp_type = 10

M_CYCLE_EGG_TOC_B_LOG_FIELD.name = "b_log"
M_CYCLE_EGG_TOC_B_LOG_FIELD.full_name = ".m_cycle_egg_toc.b_log"
M_CYCLE_EGG_TOC_B_LOG_FIELD.number = 6
M_CYCLE_EGG_TOC_B_LOG_FIELD.index = 5
M_CYCLE_EGG_TOC_B_LOG_FIELD.label = 3
M_CYCLE_EGG_TOC_B_LOG_FIELD.has_default_value = false
M_CYCLE_EGG_TOC_B_LOG_FIELD.default_value = {}
M_CYCLE_EGG_TOC_B_LOG_FIELD.message_type = p_kvs_pb.P_KVS
M_CYCLE_EGG_TOC_B_LOG_FIELD.type = 11
M_CYCLE_EGG_TOC_B_LOG_FIELD.cpp_type = 10

M_CYCLE_EGG_TOC.name = "m_cycle_egg_toc"
M_CYCLE_EGG_TOC.full_name = ".m_cycle_egg_toc"
M_CYCLE_EGG_TOC.nested_types = {}
M_CYCLE_EGG_TOC.enum_types = {}
M_CYCLE_EGG_TOC.fields = {M_CYCLE_EGG_TOC_EGGS_FIELD, M_CYCLE_EGG_TOC_CAN_REFRESH_FIELD, M_CYCLE_EGG_TOC_OPEN_TIMES_FIELD, M_CYCLE_EGG_TOC_LIST_FIELD, M_CYCLE_EGG_TOC_A_LOG_FIELD, M_CYCLE_EGG_TOC_B_LOG_FIELD}
M_CYCLE_EGG_TOC.is_extendable = false
M_CYCLE_EGG_TOC.extensions = {}

m_cycle_egg_toc = protobuf.Message(M_CYCLE_EGG_TOC)

