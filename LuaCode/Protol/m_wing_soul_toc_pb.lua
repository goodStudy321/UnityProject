--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_kv_pb = require("Protol.p_kv_pb")
module('Protol.m_wing_soul_toc_pb')

M_WING_SOUL_TOC = protobuf.Descriptor();
M_WING_SOUL_TOC_SOUL_FIELD = protobuf.FieldDescriptor();

M_WING_SOUL_TOC_SOUL_FIELD.name = "soul"
M_WING_SOUL_TOC_SOUL_FIELD.full_name = ".m_wing_soul_toc.soul"
M_WING_SOUL_TOC_SOUL_FIELD.number = 1
M_WING_SOUL_TOC_SOUL_FIELD.index = 0
M_WING_SOUL_TOC_SOUL_FIELD.label = 1
M_WING_SOUL_TOC_SOUL_FIELD.has_default_value = false
M_WING_SOUL_TOC_SOUL_FIELD.default_value = nil
M_WING_SOUL_TOC_SOUL_FIELD.message_type = p_kv_pb.P_KV
M_WING_SOUL_TOC_SOUL_FIELD.type = 11
M_WING_SOUL_TOC_SOUL_FIELD.cpp_type = 10

M_WING_SOUL_TOC.name = "m_wing_soul_toc"
M_WING_SOUL_TOC.full_name = ".m_wing_soul_toc"
M_WING_SOUL_TOC.nested_types = {}
M_WING_SOUL_TOC.enum_types = {}
M_WING_SOUL_TOC.fields = {M_WING_SOUL_TOC_SOUL_FIELD}
M_WING_SOUL_TOC.is_extendable = false
M_WING_SOUL_TOC.extensions = {}

m_wing_soul_toc = protobuf.Message(M_WING_SOUL_TOC)

