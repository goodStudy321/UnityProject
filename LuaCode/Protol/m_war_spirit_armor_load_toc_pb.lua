--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_war_spirit_armor_pb = require("Protol.p_war_spirit_armor_pb")
module('Protol.m_war_spirit_armor_load_toc_pb')

M_WAR_SPIRIT_ARMOR_LOAD_TOC = protobuf.Descriptor();
M_WAR_SPIRIT_ARMOR_LOAD_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_WAR_SPIRIT_ARMOR_LOAD_TOC_WAR_SPIRIT_ID_FIELD = protobuf.FieldDescriptor();
M_WAR_SPIRIT_ARMOR_LOAD_TOC_CHANGE_ARMORS_FIELD = protobuf.FieldDescriptor();

M_WAR_SPIRIT_ARMOR_LOAD_TOC_ERR_CODE_FIELD.name = "err_code"
M_WAR_SPIRIT_ARMOR_LOAD_TOC_ERR_CODE_FIELD.full_name = ".m_war_spirit_armor_load_toc.err_code"
M_WAR_SPIRIT_ARMOR_LOAD_TOC_ERR_CODE_FIELD.number = 1
M_WAR_SPIRIT_ARMOR_LOAD_TOC_ERR_CODE_FIELD.index = 0
M_WAR_SPIRIT_ARMOR_LOAD_TOC_ERR_CODE_FIELD.label = 1
M_WAR_SPIRIT_ARMOR_LOAD_TOC_ERR_CODE_FIELD.has_default_value = true
M_WAR_SPIRIT_ARMOR_LOAD_TOC_ERR_CODE_FIELD.default_value = 0
M_WAR_SPIRIT_ARMOR_LOAD_TOC_ERR_CODE_FIELD.type = 5
M_WAR_SPIRIT_ARMOR_LOAD_TOC_ERR_CODE_FIELD.cpp_type = 1

M_WAR_SPIRIT_ARMOR_LOAD_TOC_WAR_SPIRIT_ID_FIELD.name = "war_spirit_id"
M_WAR_SPIRIT_ARMOR_LOAD_TOC_WAR_SPIRIT_ID_FIELD.full_name = ".m_war_spirit_armor_load_toc.war_spirit_id"
M_WAR_SPIRIT_ARMOR_LOAD_TOC_WAR_SPIRIT_ID_FIELD.number = 2
M_WAR_SPIRIT_ARMOR_LOAD_TOC_WAR_SPIRIT_ID_FIELD.index = 1
M_WAR_SPIRIT_ARMOR_LOAD_TOC_WAR_SPIRIT_ID_FIELD.label = 1
M_WAR_SPIRIT_ARMOR_LOAD_TOC_WAR_SPIRIT_ID_FIELD.has_default_value = true
M_WAR_SPIRIT_ARMOR_LOAD_TOC_WAR_SPIRIT_ID_FIELD.default_value = 0
M_WAR_SPIRIT_ARMOR_LOAD_TOC_WAR_SPIRIT_ID_FIELD.type = 5
M_WAR_SPIRIT_ARMOR_LOAD_TOC_WAR_SPIRIT_ID_FIELD.cpp_type = 1

M_WAR_SPIRIT_ARMOR_LOAD_TOC_CHANGE_ARMORS_FIELD.name = "change_armors"
M_WAR_SPIRIT_ARMOR_LOAD_TOC_CHANGE_ARMORS_FIELD.full_name = ".m_war_spirit_armor_load_toc.change_armors"
M_WAR_SPIRIT_ARMOR_LOAD_TOC_CHANGE_ARMORS_FIELD.number = 3
M_WAR_SPIRIT_ARMOR_LOAD_TOC_CHANGE_ARMORS_FIELD.index = 2
M_WAR_SPIRIT_ARMOR_LOAD_TOC_CHANGE_ARMORS_FIELD.label = 3
M_WAR_SPIRIT_ARMOR_LOAD_TOC_CHANGE_ARMORS_FIELD.has_default_value = false
M_WAR_SPIRIT_ARMOR_LOAD_TOC_CHANGE_ARMORS_FIELD.default_value = {}
M_WAR_SPIRIT_ARMOR_LOAD_TOC_CHANGE_ARMORS_FIELD.message_type = p_war_spirit_armor_pb.P_WAR_SPIRIT_ARMOR
M_WAR_SPIRIT_ARMOR_LOAD_TOC_CHANGE_ARMORS_FIELD.type = 11
M_WAR_SPIRIT_ARMOR_LOAD_TOC_CHANGE_ARMORS_FIELD.cpp_type = 10

M_WAR_SPIRIT_ARMOR_LOAD_TOC.name = "m_war_spirit_armor_load_toc"
M_WAR_SPIRIT_ARMOR_LOAD_TOC.full_name = ".m_war_spirit_armor_load_toc"
M_WAR_SPIRIT_ARMOR_LOAD_TOC.nested_types = {}
M_WAR_SPIRIT_ARMOR_LOAD_TOC.enum_types = {}
M_WAR_SPIRIT_ARMOR_LOAD_TOC.fields = {M_WAR_SPIRIT_ARMOR_LOAD_TOC_ERR_CODE_FIELD, M_WAR_SPIRIT_ARMOR_LOAD_TOC_WAR_SPIRIT_ID_FIELD, M_WAR_SPIRIT_ARMOR_LOAD_TOC_CHANGE_ARMORS_FIELD}
M_WAR_SPIRIT_ARMOR_LOAD_TOC.is_extendable = false
M_WAR_SPIRIT_ARMOR_LOAD_TOC.extensions = {}

m_war_spirit_armor_load_toc = protobuf.Message(M_WAR_SPIRIT_ARMOR_LOAD_TOC)

