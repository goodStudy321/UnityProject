--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_family_mission_pb = require("Protol.p_family_mission_pb")
module('Protol.m_role_family_mission_update_toc_pb')

M_ROLE_FAMILY_MISSION_UPDATE_TOC = protobuf.Descriptor();
M_ROLE_FAMILY_MISSION_UPDATE_TOC_FAMILY_MISSION_FIELD = protobuf.FieldDescriptor();

M_ROLE_FAMILY_MISSION_UPDATE_TOC_FAMILY_MISSION_FIELD.name = "family_mission"
M_ROLE_FAMILY_MISSION_UPDATE_TOC_FAMILY_MISSION_FIELD.full_name = ".m_role_family_mission_update_toc.family_mission"
M_ROLE_FAMILY_MISSION_UPDATE_TOC_FAMILY_MISSION_FIELD.number = 1
M_ROLE_FAMILY_MISSION_UPDATE_TOC_FAMILY_MISSION_FIELD.index = 0
M_ROLE_FAMILY_MISSION_UPDATE_TOC_FAMILY_MISSION_FIELD.label = 1
M_ROLE_FAMILY_MISSION_UPDATE_TOC_FAMILY_MISSION_FIELD.has_default_value = false
M_ROLE_FAMILY_MISSION_UPDATE_TOC_FAMILY_MISSION_FIELD.default_value = nil
M_ROLE_FAMILY_MISSION_UPDATE_TOC_FAMILY_MISSION_FIELD.message_type = p_family_mission_pb.P_FAMILY_MISSION
M_ROLE_FAMILY_MISSION_UPDATE_TOC_FAMILY_MISSION_FIELD.type = 11
M_ROLE_FAMILY_MISSION_UPDATE_TOC_FAMILY_MISSION_FIELD.cpp_type = 10

M_ROLE_FAMILY_MISSION_UPDATE_TOC.name = "m_role_family_mission_update_toc"
M_ROLE_FAMILY_MISSION_UPDATE_TOC.full_name = ".m_role_family_mission_update_toc"
M_ROLE_FAMILY_MISSION_UPDATE_TOC.nested_types = {}
M_ROLE_FAMILY_MISSION_UPDATE_TOC.enum_types = {}
M_ROLE_FAMILY_MISSION_UPDATE_TOC.fields = {M_ROLE_FAMILY_MISSION_UPDATE_TOC_FAMILY_MISSION_FIELD}
M_ROLE_FAMILY_MISSION_UPDATE_TOC.is_extendable = false
M_ROLE_FAMILY_MISSION_UPDATE_TOC.extensions = {}

m_role_family_mission_update_toc = protobuf.Message(M_ROLE_FAMILY_MISSION_UPDATE_TOC)

