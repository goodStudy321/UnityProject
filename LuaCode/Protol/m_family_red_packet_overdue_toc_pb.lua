--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_family_red_packet_overdue_toc_pb')

M_FAMILY_RED_PACKET_OVERDUE_TOC = protobuf.Descriptor();
M_FAMILY_RED_PACKET_OVERDUE_TOC_TYPE_FIELD = protobuf.FieldDescriptor();
M_FAMILY_RED_PACKET_OVERDUE_TOC_PACKET_ID_FIELD = protobuf.FieldDescriptor();

M_FAMILY_RED_PACKET_OVERDUE_TOC_TYPE_FIELD.name = "type"
M_FAMILY_RED_PACKET_OVERDUE_TOC_TYPE_FIELD.full_name = ".m_family_red_packet_overdue_toc.type"
M_FAMILY_RED_PACKET_OVERDUE_TOC_TYPE_FIELD.number = 1
M_FAMILY_RED_PACKET_OVERDUE_TOC_TYPE_FIELD.index = 0
M_FAMILY_RED_PACKET_OVERDUE_TOC_TYPE_FIELD.label = 1
M_FAMILY_RED_PACKET_OVERDUE_TOC_TYPE_FIELD.has_default_value = true
M_FAMILY_RED_PACKET_OVERDUE_TOC_TYPE_FIELD.default_value = 0
M_FAMILY_RED_PACKET_OVERDUE_TOC_TYPE_FIELD.type = 5
M_FAMILY_RED_PACKET_OVERDUE_TOC_TYPE_FIELD.cpp_type = 1

M_FAMILY_RED_PACKET_OVERDUE_TOC_PACKET_ID_FIELD.name = "packet_id"
M_FAMILY_RED_PACKET_OVERDUE_TOC_PACKET_ID_FIELD.full_name = ".m_family_red_packet_overdue_toc.packet_id"
M_FAMILY_RED_PACKET_OVERDUE_TOC_PACKET_ID_FIELD.number = 2
M_FAMILY_RED_PACKET_OVERDUE_TOC_PACKET_ID_FIELD.index = 1
M_FAMILY_RED_PACKET_OVERDUE_TOC_PACKET_ID_FIELD.label = 3
M_FAMILY_RED_PACKET_OVERDUE_TOC_PACKET_ID_FIELD.has_default_value = false
M_FAMILY_RED_PACKET_OVERDUE_TOC_PACKET_ID_FIELD.default_value = {}
M_FAMILY_RED_PACKET_OVERDUE_TOC_PACKET_ID_FIELD.type = 5
M_FAMILY_RED_PACKET_OVERDUE_TOC_PACKET_ID_FIELD.cpp_type = 1

M_FAMILY_RED_PACKET_OVERDUE_TOC.name = "m_family_red_packet_overdue_toc"
M_FAMILY_RED_PACKET_OVERDUE_TOC.full_name = ".m_family_red_packet_overdue_toc"
M_FAMILY_RED_PACKET_OVERDUE_TOC.nested_types = {}
M_FAMILY_RED_PACKET_OVERDUE_TOC.enum_types = {}
M_FAMILY_RED_PACKET_OVERDUE_TOC.fields = {M_FAMILY_RED_PACKET_OVERDUE_TOC_TYPE_FIELD, M_FAMILY_RED_PACKET_OVERDUE_TOC_PACKET_ID_FIELD}
M_FAMILY_RED_PACKET_OVERDUE_TOC.is_extendable = false
M_FAMILY_RED_PACKET_OVERDUE_TOC.extensions = {}

m_family_red_packet_overdue_toc = protobuf.Message(M_FAMILY_RED_PACKET_OVERDUE_TOC)

