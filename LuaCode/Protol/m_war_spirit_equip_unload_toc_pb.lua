--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_war_spirit_pb = require("Protol.p_war_spirit_pb")
module('Protol.m_war_spirit_equip_unload_toc_pb')

M_WAR_SPIRIT_EQUIP_UNLOAD_TOC = protobuf.Descriptor();
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC_WAR_SPIRIT_FIELD = protobuf.FieldDescriptor();

M_WAR_SPIRIT_EQUIP_UNLOAD_TOC_ERR_CODE_FIELD.name = "err_code"
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC_ERR_CODE_FIELD.full_name = ".m_war_spirit_equip_unload_toc.err_code"
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC_ERR_CODE_FIELD.number = 1
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC_ERR_CODE_FIELD.index = 0
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC_ERR_CODE_FIELD.label = 1
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC_ERR_CODE_FIELD.has_default_value = true
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC_ERR_CODE_FIELD.default_value = 0
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC_ERR_CODE_FIELD.type = 5
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC_ERR_CODE_FIELD.cpp_type = 1

M_WAR_SPIRIT_EQUIP_UNLOAD_TOC_WAR_SPIRIT_FIELD.name = "war_spirit"
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC_WAR_SPIRIT_FIELD.full_name = ".m_war_spirit_equip_unload_toc.war_spirit"
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC_WAR_SPIRIT_FIELD.number = 2
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC_WAR_SPIRIT_FIELD.index = 1
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC_WAR_SPIRIT_FIELD.label = 1
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC_WAR_SPIRIT_FIELD.has_default_value = false
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC_WAR_SPIRIT_FIELD.default_value = nil
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC_WAR_SPIRIT_FIELD.message_type = p_war_spirit_pb.P_WAR_SPIRIT
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC_WAR_SPIRIT_FIELD.type = 11
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC_WAR_SPIRIT_FIELD.cpp_type = 10

M_WAR_SPIRIT_EQUIP_UNLOAD_TOC.name = "m_war_spirit_equip_unload_toc"
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC.full_name = ".m_war_spirit_equip_unload_toc"
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC.nested_types = {}
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC.enum_types = {}
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC.fields = {M_WAR_SPIRIT_EQUIP_UNLOAD_TOC_ERR_CODE_FIELD, M_WAR_SPIRIT_EQUIP_UNLOAD_TOC_WAR_SPIRIT_FIELD}
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC.is_extendable = false
M_WAR_SPIRIT_EQUIP_UNLOAD_TOC.extensions = {}

m_war_spirit_equip_unload_toc = protobuf.Message(M_WAR_SPIRIT_EQUIP_UNLOAD_TOC)

