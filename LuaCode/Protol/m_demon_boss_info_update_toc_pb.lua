--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_demon_boss_room_pb = require("Protol.p_demon_boss_room_pb")
module('Protol.m_demon_boss_info_update_toc_pb')

M_DEMON_BOSS_INFO_UPDATE_TOC = protobuf.Descriptor();
M_DEMON_BOSS_INFO_UPDATE_TOC_ROOM_FIELD = protobuf.FieldDescriptor();

M_DEMON_BOSS_INFO_UPDATE_TOC_ROOM_FIELD.name = "room"
M_DEMON_BOSS_INFO_UPDATE_TOC_ROOM_FIELD.full_name = ".m_demon_boss_info_update_toc.room"
M_DEMON_BOSS_INFO_UPDATE_TOC_ROOM_FIELD.number = 1
M_DEMON_BOSS_INFO_UPDATE_TOC_ROOM_FIELD.index = 0
M_DEMON_BOSS_INFO_UPDATE_TOC_ROOM_FIELD.label = 1
M_DEMON_BOSS_INFO_UPDATE_TOC_ROOM_FIELD.has_default_value = false
M_DEMON_BOSS_INFO_UPDATE_TOC_ROOM_FIELD.default_value = nil
M_DEMON_BOSS_INFO_UPDATE_TOC_ROOM_FIELD.message_type = p_demon_boss_room_pb.P_DEMON_BOSS_ROOM
M_DEMON_BOSS_INFO_UPDATE_TOC_ROOM_FIELD.type = 11
M_DEMON_BOSS_INFO_UPDATE_TOC_ROOM_FIELD.cpp_type = 10

M_DEMON_BOSS_INFO_UPDATE_TOC.name = "m_demon_boss_info_update_toc"
M_DEMON_BOSS_INFO_UPDATE_TOC.full_name = ".m_demon_boss_info_update_toc"
M_DEMON_BOSS_INFO_UPDATE_TOC.nested_types = {}
M_DEMON_BOSS_INFO_UPDATE_TOC.enum_types = {}
M_DEMON_BOSS_INFO_UPDATE_TOC.fields = {M_DEMON_BOSS_INFO_UPDATE_TOC_ROOM_FIELD}
M_DEMON_BOSS_INFO_UPDATE_TOC.is_extendable = false
M_DEMON_BOSS_INFO_UPDATE_TOC.extensions = {}

m_demon_boss_info_update_toc = protobuf.Message(M_DEMON_BOSS_INFO_UPDATE_TOC)

