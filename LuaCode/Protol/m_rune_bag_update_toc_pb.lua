--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_rune_pb = require("Protol.p_rune_pb")
module('Protol.m_rune_bag_update_toc_pb')

M_RUNE_BAG_UPDATE_TOC = protobuf.Descriptor();
M_RUNE_BAG_UPDATE_TOC_UPDATE_RUNES_FIELD = protobuf.FieldDescriptor();
M_RUNE_BAG_UPDATE_TOC_DEL_RUNES_FIELD = protobuf.FieldDescriptor();

M_RUNE_BAG_UPDATE_TOC_UPDATE_RUNES_FIELD.name = "update_runes"
M_RUNE_BAG_UPDATE_TOC_UPDATE_RUNES_FIELD.full_name = ".m_rune_bag_update_toc.update_runes"
M_RUNE_BAG_UPDATE_TOC_UPDATE_RUNES_FIELD.number = 1
M_RUNE_BAG_UPDATE_TOC_UPDATE_RUNES_FIELD.index = 0
M_RUNE_BAG_UPDATE_TOC_UPDATE_RUNES_FIELD.label = 3
M_RUNE_BAG_UPDATE_TOC_UPDATE_RUNES_FIELD.has_default_value = false
M_RUNE_BAG_UPDATE_TOC_UPDATE_RUNES_FIELD.default_value = {}
M_RUNE_BAG_UPDATE_TOC_UPDATE_RUNES_FIELD.message_type = p_rune_pb.P_RUNE
M_RUNE_BAG_UPDATE_TOC_UPDATE_RUNES_FIELD.type = 11
M_RUNE_BAG_UPDATE_TOC_UPDATE_RUNES_FIELD.cpp_type = 10

M_RUNE_BAG_UPDATE_TOC_DEL_RUNES_FIELD.name = "del_runes"
M_RUNE_BAG_UPDATE_TOC_DEL_RUNES_FIELD.full_name = ".m_rune_bag_update_toc.del_runes"
M_RUNE_BAG_UPDATE_TOC_DEL_RUNES_FIELD.number = 2
M_RUNE_BAG_UPDATE_TOC_DEL_RUNES_FIELD.index = 1
M_RUNE_BAG_UPDATE_TOC_DEL_RUNES_FIELD.label = 3
M_RUNE_BAG_UPDATE_TOC_DEL_RUNES_FIELD.has_default_value = false
M_RUNE_BAG_UPDATE_TOC_DEL_RUNES_FIELD.default_value = {}
M_RUNE_BAG_UPDATE_TOC_DEL_RUNES_FIELD.type = 5
M_RUNE_BAG_UPDATE_TOC_DEL_RUNES_FIELD.cpp_type = 1

M_RUNE_BAG_UPDATE_TOC.name = "m_rune_bag_update_toc"
M_RUNE_BAG_UPDATE_TOC.full_name = ".m_rune_bag_update_toc"
M_RUNE_BAG_UPDATE_TOC.nested_types = {}
M_RUNE_BAG_UPDATE_TOC.enum_types = {}
M_RUNE_BAG_UPDATE_TOC.fields = {M_RUNE_BAG_UPDATE_TOC_UPDATE_RUNES_FIELD, M_RUNE_BAG_UPDATE_TOC_DEL_RUNES_FIELD}
M_RUNE_BAG_UPDATE_TOC.is_extendable = false
M_RUNE_BAG_UPDATE_TOC.extensions = {}

m_rune_bag_update_toc = protobuf.Message(M_RUNE_BAG_UPDATE_TOC)

