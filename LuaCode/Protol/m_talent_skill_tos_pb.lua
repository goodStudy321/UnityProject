--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_talent_skill_tos_pb')

M_TALENT_SKILL_TOS = protobuf.Descriptor();
M_TALENT_SKILL_TOS_TAB_ID_FIELD = protobuf.FieldDescriptor();
M_TALENT_SKILL_TOS_TALENT_SKILL_ID_FIELD = protobuf.FieldDescriptor();

M_TALENT_SKILL_TOS_TAB_ID_FIELD.name = "tab_id"
M_TALENT_SKILL_TOS_TAB_ID_FIELD.full_name = ".m_talent_skill_tos.tab_id"
M_TALENT_SKILL_TOS_TAB_ID_FIELD.number = 1
M_TALENT_SKILL_TOS_TAB_ID_FIELD.index = 0
M_TALENT_SKILL_TOS_TAB_ID_FIELD.label = 1
M_TALENT_SKILL_TOS_TAB_ID_FIELD.has_default_value = true
M_TALENT_SKILL_TOS_TAB_ID_FIELD.default_value = 0
M_TALENT_SKILL_TOS_TAB_ID_FIELD.type = 5
M_TALENT_SKILL_TOS_TAB_ID_FIELD.cpp_type = 1

M_TALENT_SKILL_TOS_TALENT_SKILL_ID_FIELD.name = "talent_skill_id"
M_TALENT_SKILL_TOS_TALENT_SKILL_ID_FIELD.full_name = ".m_talent_skill_tos.talent_skill_id"
M_TALENT_SKILL_TOS_TALENT_SKILL_ID_FIELD.number = 2
M_TALENT_SKILL_TOS_TALENT_SKILL_ID_FIELD.index = 1
M_TALENT_SKILL_TOS_TALENT_SKILL_ID_FIELD.label = 1
M_TALENT_SKILL_TOS_TALENT_SKILL_ID_FIELD.has_default_value = true
M_TALENT_SKILL_TOS_TALENT_SKILL_ID_FIELD.default_value = 0
M_TALENT_SKILL_TOS_TALENT_SKILL_ID_FIELD.type = 5
M_TALENT_SKILL_TOS_TALENT_SKILL_ID_FIELD.cpp_type = 1

M_TALENT_SKILL_TOS.name = "m_talent_skill_tos"
M_TALENT_SKILL_TOS.full_name = ".m_talent_skill_tos"
M_TALENT_SKILL_TOS.nested_types = {}
M_TALENT_SKILL_TOS.enum_types = {}
M_TALENT_SKILL_TOS.fields = {M_TALENT_SKILL_TOS_TAB_ID_FIELD, M_TALENT_SKILL_TOS_TALENT_SKILL_ID_FIELD}
M_TALENT_SKILL_TOS.is_extendable = false
M_TALENT_SKILL_TOS.extensions = {}

m_talent_skill_tos = protobuf.Message(M_TALENT_SKILL_TOS)
