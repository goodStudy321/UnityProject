--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_mythical_soul_pb = require("Protol.p_mythical_soul_pb")
module('Protol.m_mythical_equip_load_toc_pb')

M_MYTHICAL_EQUIP_LOAD_TOC = protobuf.Descriptor();
M_MYTHICAL_EQUIP_LOAD_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_MYTHICAL_EQUIP_LOAD_TOC_SOUL_FIELD = protobuf.FieldDescriptor();

M_MYTHICAL_EQUIP_LOAD_TOC_ERR_CODE_FIELD.name = "err_code"
M_MYTHICAL_EQUIP_LOAD_TOC_ERR_CODE_FIELD.full_name = ".m_mythical_equip_load_toc.err_code"
M_MYTHICAL_EQUIP_LOAD_TOC_ERR_CODE_FIELD.number = 1
M_MYTHICAL_EQUIP_LOAD_TOC_ERR_CODE_FIELD.index = 0
M_MYTHICAL_EQUIP_LOAD_TOC_ERR_CODE_FIELD.label = 1
M_MYTHICAL_EQUIP_LOAD_TOC_ERR_CODE_FIELD.has_default_value = true
M_MYTHICAL_EQUIP_LOAD_TOC_ERR_CODE_FIELD.default_value = 0
M_MYTHICAL_EQUIP_LOAD_TOC_ERR_CODE_FIELD.type = 5
M_MYTHICAL_EQUIP_LOAD_TOC_ERR_CODE_FIELD.cpp_type = 1

M_MYTHICAL_EQUIP_LOAD_TOC_SOUL_FIELD.name = "soul"
M_MYTHICAL_EQUIP_LOAD_TOC_SOUL_FIELD.full_name = ".m_mythical_equip_load_toc.soul"
M_MYTHICAL_EQUIP_LOAD_TOC_SOUL_FIELD.number = 2
M_MYTHICAL_EQUIP_LOAD_TOC_SOUL_FIELD.index = 1
M_MYTHICAL_EQUIP_LOAD_TOC_SOUL_FIELD.label = 1
M_MYTHICAL_EQUIP_LOAD_TOC_SOUL_FIELD.has_default_value = false
M_MYTHICAL_EQUIP_LOAD_TOC_SOUL_FIELD.default_value = nil
M_MYTHICAL_EQUIP_LOAD_TOC_SOUL_FIELD.message_type = p_mythical_soul_pb.P_MYTHICAL_SOUL
M_MYTHICAL_EQUIP_LOAD_TOC_SOUL_FIELD.type = 11
M_MYTHICAL_EQUIP_LOAD_TOC_SOUL_FIELD.cpp_type = 10

M_MYTHICAL_EQUIP_LOAD_TOC.name = "m_mythical_equip_load_toc"
M_MYTHICAL_EQUIP_LOAD_TOC.full_name = ".m_mythical_equip_load_toc"
M_MYTHICAL_EQUIP_LOAD_TOC.nested_types = {}
M_MYTHICAL_EQUIP_LOAD_TOC.enum_types = {}
M_MYTHICAL_EQUIP_LOAD_TOC.fields = {M_MYTHICAL_EQUIP_LOAD_TOC_ERR_CODE_FIELD, M_MYTHICAL_EQUIP_LOAD_TOC_SOUL_FIELD}
M_MYTHICAL_EQUIP_LOAD_TOC.is_extendable = false
M_MYTHICAL_EQUIP_LOAD_TOC.extensions = {}

m_mythical_equip_load_toc = protobuf.Message(M_MYTHICAL_EQUIP_LOAD_TOC)

