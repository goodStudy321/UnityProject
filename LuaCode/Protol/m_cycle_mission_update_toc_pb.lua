--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_kv_pb = require("Protol.p_kv_pb")
module('Protol.m_cycle_mission_update_toc_pb')

M_CYCLE_MISSION_UPDATE_TOC = protobuf.Descriptor();
M_CYCLE_MISSION_UPDATE_TOC_LIST_FIELD = protobuf.FieldDescriptor();
M_CYCLE_MISSION_UPDATE_TOC_MONEY_FIELD = protobuf.FieldDescriptor();

M_CYCLE_MISSION_UPDATE_TOC_LIST_FIELD.name = "list"
M_CYCLE_MISSION_UPDATE_TOC_LIST_FIELD.full_name = ".m_cycle_mission_update_toc.list"
M_CYCLE_MISSION_UPDATE_TOC_LIST_FIELD.number = 1
M_CYCLE_MISSION_UPDATE_TOC_LIST_FIELD.index = 0
M_CYCLE_MISSION_UPDATE_TOC_LIST_FIELD.label = 3
M_CYCLE_MISSION_UPDATE_TOC_LIST_FIELD.has_default_value = false
M_CYCLE_MISSION_UPDATE_TOC_LIST_FIELD.default_value = {}
M_CYCLE_MISSION_UPDATE_TOC_LIST_FIELD.message_type = p_kv_pb.P_KV
M_CYCLE_MISSION_UPDATE_TOC_LIST_FIELD.type = 11
M_CYCLE_MISSION_UPDATE_TOC_LIST_FIELD.cpp_type = 10

M_CYCLE_MISSION_UPDATE_TOC_MONEY_FIELD.name = "money"
M_CYCLE_MISSION_UPDATE_TOC_MONEY_FIELD.full_name = ".m_cycle_mission_update_toc.money"
M_CYCLE_MISSION_UPDATE_TOC_MONEY_FIELD.number = 2
M_CYCLE_MISSION_UPDATE_TOC_MONEY_FIELD.index = 1
M_CYCLE_MISSION_UPDATE_TOC_MONEY_FIELD.label = 1
M_CYCLE_MISSION_UPDATE_TOC_MONEY_FIELD.has_default_value = true
M_CYCLE_MISSION_UPDATE_TOC_MONEY_FIELD.default_value = 0
M_CYCLE_MISSION_UPDATE_TOC_MONEY_FIELD.type = 5
M_CYCLE_MISSION_UPDATE_TOC_MONEY_FIELD.cpp_type = 1

M_CYCLE_MISSION_UPDATE_TOC.name = "m_cycle_mission_update_toc"
M_CYCLE_MISSION_UPDATE_TOC.full_name = ".m_cycle_mission_update_toc"
M_CYCLE_MISSION_UPDATE_TOC.nested_types = {}
M_CYCLE_MISSION_UPDATE_TOC.enum_types = {}
M_CYCLE_MISSION_UPDATE_TOC.fields = {M_CYCLE_MISSION_UPDATE_TOC_LIST_FIELD, M_CYCLE_MISSION_UPDATE_TOC_MONEY_FIELD}
M_CYCLE_MISSION_UPDATE_TOC.is_extendable = false
M_CYCLE_MISSION_UPDATE_TOC.extensions = {}

m_cycle_mission_update_toc = protobuf.Message(M_CYCLE_MISSION_UPDATE_TOC)

