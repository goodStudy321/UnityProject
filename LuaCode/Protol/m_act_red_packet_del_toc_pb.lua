--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_act_red_packet_del_toc_pb')

M_ACT_RED_PACKET_DEL_TOC = protobuf.Descriptor();
M_ACT_RED_PACKET_DEL_TOC_PACKET_IDS_FIELD = protobuf.FieldDescriptor();

M_ACT_RED_PACKET_DEL_TOC_PACKET_IDS_FIELD.name = "packet_ids"
M_ACT_RED_PACKET_DEL_TOC_PACKET_IDS_FIELD.full_name = ".m_act_red_packet_del_toc.packet_ids"
M_ACT_RED_PACKET_DEL_TOC_PACKET_IDS_FIELD.number = 1
M_ACT_RED_PACKET_DEL_TOC_PACKET_IDS_FIELD.index = 0
M_ACT_RED_PACKET_DEL_TOC_PACKET_IDS_FIELD.label = 3
M_ACT_RED_PACKET_DEL_TOC_PACKET_IDS_FIELD.has_default_value = false
M_ACT_RED_PACKET_DEL_TOC_PACKET_IDS_FIELD.default_value = {}
M_ACT_RED_PACKET_DEL_TOC_PACKET_IDS_FIELD.type = 3
M_ACT_RED_PACKET_DEL_TOC_PACKET_IDS_FIELD.cpp_type = 2

M_ACT_RED_PACKET_DEL_TOC.name = "m_act_red_packet_del_toc"
M_ACT_RED_PACKET_DEL_TOC.full_name = ".m_act_red_packet_del_toc"
M_ACT_RED_PACKET_DEL_TOC.nested_types = {}
M_ACT_RED_PACKET_DEL_TOC.enum_types = {}
M_ACT_RED_PACKET_DEL_TOC.fields = {M_ACT_RED_PACKET_DEL_TOC_PACKET_IDS_FIELD}
M_ACT_RED_PACKET_DEL_TOC.is_extendable = false
M_ACT_RED_PACKET_DEL_TOC.extensions = {}

m_act_red_packet_del_toc = protobuf.Message(M_ACT_RED_PACKET_DEL_TOC)

