--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.p_tab_skill_pb')

P_TAB_SKILL = protobuf.Descriptor();
P_TAB_SKILL_TAB_ID_FIELD = protobuf.FieldDescriptor();
P_TAB_SKILL_SKILLS_FIELD = protobuf.FieldDescriptor();

P_TAB_SKILL_TAB_ID_FIELD.name = "tab_id"
P_TAB_SKILL_TAB_ID_FIELD.full_name = ".p_tab_skill.tab_id"
P_TAB_SKILL_TAB_ID_FIELD.number = 1
P_TAB_SKILL_TAB_ID_FIELD.index = 0
P_TAB_SKILL_TAB_ID_FIELD.label = 1
P_TAB_SKILL_TAB_ID_FIELD.has_default_value = true
P_TAB_SKILL_TAB_ID_FIELD.default_value = 0
P_TAB_SKILL_TAB_ID_FIELD.type = 5
P_TAB_SKILL_TAB_ID_FIELD.cpp_type = 1

P_TAB_SKILL_SKILLS_FIELD.name = "skills"
P_TAB_SKILL_SKILLS_FIELD.full_name = ".p_tab_skill.skills"
P_TAB_SKILL_SKILLS_FIELD.number = 2
P_TAB_SKILL_SKILLS_FIELD.index = 1
P_TAB_SKILL_SKILLS_FIELD.label = 3
P_TAB_SKILL_SKILLS_FIELD.has_default_value = false
P_TAB_SKILL_SKILLS_FIELD.default_value = {}
P_TAB_SKILL_SKILLS_FIELD.type = 5
P_TAB_SKILL_SKILLS_FIELD.cpp_type = 1

P_TAB_SKILL.name = "p_tab_skill"
P_TAB_SKILL.full_name = ".p_tab_skill"
P_TAB_SKILL.nested_types = {}
P_TAB_SKILL.enum_types = {}
P_TAB_SKILL.fields = {P_TAB_SKILL_TAB_ID_FIELD, P_TAB_SKILL_SKILLS_FIELD}
P_TAB_SKILL.is_extendable = false
P_TAB_SKILL.extensions = {}

p_tab_skill = protobuf.Message(P_TAB_SKILL)

