--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_war_spirit_armor_load_tos_pb')

M_WAR_SPIRIT_ARMOR_LOAD_TOS = protobuf.Descriptor();
M_WAR_SPIRIT_ARMOR_LOAD_TOS_WAR_SPIRIT_ID_FIELD = protobuf.FieldDescriptor();
M_WAR_SPIRIT_ARMOR_LOAD_TOS_GOODS_IDS_FIELD = protobuf.FieldDescriptor();

M_WAR_SPIRIT_ARMOR_LOAD_TOS_WAR_SPIRIT_ID_FIELD.name = "war_spirit_id"
M_WAR_SPIRIT_ARMOR_LOAD_TOS_WAR_SPIRIT_ID_FIELD.full_name = ".m_war_spirit_armor_load_tos.war_spirit_id"
M_WAR_SPIRIT_ARMOR_LOAD_TOS_WAR_SPIRIT_ID_FIELD.number = 1
M_WAR_SPIRIT_ARMOR_LOAD_TOS_WAR_SPIRIT_ID_FIELD.index = 0
M_WAR_SPIRIT_ARMOR_LOAD_TOS_WAR_SPIRIT_ID_FIELD.label = 1
M_WAR_SPIRIT_ARMOR_LOAD_TOS_WAR_SPIRIT_ID_FIELD.has_default_value = true
M_WAR_SPIRIT_ARMOR_LOAD_TOS_WAR_SPIRIT_ID_FIELD.default_value = 0
M_WAR_SPIRIT_ARMOR_LOAD_TOS_WAR_SPIRIT_ID_FIELD.type = 5
M_WAR_SPIRIT_ARMOR_LOAD_TOS_WAR_SPIRIT_ID_FIELD.cpp_type = 1

M_WAR_SPIRIT_ARMOR_LOAD_TOS_GOODS_IDS_FIELD.name = "goods_ids"
M_WAR_SPIRIT_ARMOR_LOAD_TOS_GOODS_IDS_FIELD.full_name = ".m_war_spirit_armor_load_tos.goods_ids"
M_WAR_SPIRIT_ARMOR_LOAD_TOS_GOODS_IDS_FIELD.number = 2
M_WAR_SPIRIT_ARMOR_LOAD_TOS_GOODS_IDS_FIELD.index = 1
M_WAR_SPIRIT_ARMOR_LOAD_TOS_GOODS_IDS_FIELD.label = 3
M_WAR_SPIRIT_ARMOR_LOAD_TOS_GOODS_IDS_FIELD.has_default_value = false
M_WAR_SPIRIT_ARMOR_LOAD_TOS_GOODS_IDS_FIELD.default_value = {}
M_WAR_SPIRIT_ARMOR_LOAD_TOS_GOODS_IDS_FIELD.type = 5
M_WAR_SPIRIT_ARMOR_LOAD_TOS_GOODS_IDS_FIELD.cpp_type = 1

M_WAR_SPIRIT_ARMOR_LOAD_TOS.name = "m_war_spirit_armor_load_tos"
M_WAR_SPIRIT_ARMOR_LOAD_TOS.full_name = ".m_war_spirit_armor_load_tos"
M_WAR_SPIRIT_ARMOR_LOAD_TOS.nested_types = {}
M_WAR_SPIRIT_ARMOR_LOAD_TOS.enum_types = {}
M_WAR_SPIRIT_ARMOR_LOAD_TOS.fields = {M_WAR_SPIRIT_ARMOR_LOAD_TOS_WAR_SPIRIT_ID_FIELD, M_WAR_SPIRIT_ARMOR_LOAD_TOS_GOODS_IDS_FIELD}
M_WAR_SPIRIT_ARMOR_LOAD_TOS.is_extendable = false
M_WAR_SPIRIT_ARMOR_LOAD_TOS.extensions = {}

m_war_spirit_armor_load_tos = protobuf.Message(M_WAR_SPIRIT_ARMOR_LOAD_TOS)

