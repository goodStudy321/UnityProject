--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_red_packet_pb = require("Protol.p_red_packet_pb")
module('Protol.m_family_new_red_packet_toc_pb')

M_FAMILY_NEW_RED_PACKET_TOC = protobuf.Descriptor();
M_FAMILY_NEW_RED_PACKET_TOC_RED_PACKET_FIELD = protobuf.FieldDescriptor();

M_FAMILY_NEW_RED_PACKET_TOC_RED_PACKET_FIELD.name = "red_packet"
M_FAMILY_NEW_RED_PACKET_TOC_RED_PACKET_FIELD.full_name = ".m_family_new_red_packet_toc.red_packet"
M_FAMILY_NEW_RED_PACKET_TOC_RED_PACKET_FIELD.number = 1
M_FAMILY_NEW_RED_PACKET_TOC_RED_PACKET_FIELD.index = 0
M_FAMILY_NEW_RED_PACKET_TOC_RED_PACKET_FIELD.label = 1
M_FAMILY_NEW_RED_PACKET_TOC_RED_PACKET_FIELD.has_default_value = false
M_FAMILY_NEW_RED_PACKET_TOC_RED_PACKET_FIELD.default_value = nil
M_FAMILY_NEW_RED_PACKET_TOC_RED_PACKET_FIELD.message_type = p_red_packet_pb.P_RED_PACKET
M_FAMILY_NEW_RED_PACKET_TOC_RED_PACKET_FIELD.type = 11
M_FAMILY_NEW_RED_PACKET_TOC_RED_PACKET_FIELD.cpp_type = 10

M_FAMILY_NEW_RED_PACKET_TOC.name = "m_family_new_red_packet_toc"
M_FAMILY_NEW_RED_PACKET_TOC.full_name = ".m_family_new_red_packet_toc"
M_FAMILY_NEW_RED_PACKET_TOC.nested_types = {}
M_FAMILY_NEW_RED_PACKET_TOC.enum_types = {}
M_FAMILY_NEW_RED_PACKET_TOC.fields = {M_FAMILY_NEW_RED_PACKET_TOC_RED_PACKET_FIELD}
M_FAMILY_NEW_RED_PACKET_TOC.is_extendable = false
M_FAMILY_NEW_RED_PACKET_TOC.extensions = {}

m_family_new_red_packet_toc = protobuf.Message(M_FAMILY_NEW_RED_PACKET_TOC)

