--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_battle_end_combo_kill_toc_pb')

M_BATTLE_END_COMBO_KILL_TOC = protobuf.Descriptor();
M_BATTLE_END_COMBO_KILL_TOC_KILL_ROLE_NAME_FIELD = protobuf.FieldDescriptor();
M_BATTLE_END_COMBO_KILL_TOC_KILLED_ROLE_NAME_FIELD = protobuf.FieldDescriptor();
M_BATTLE_END_COMBO_KILL_TOC_KILL_NUM_FIELD = protobuf.FieldDescriptor();

M_BATTLE_END_COMBO_KILL_TOC_KILL_ROLE_NAME_FIELD.name = "kill_role_name"
M_BATTLE_END_COMBO_KILL_TOC_KILL_ROLE_NAME_FIELD.full_name = ".m_battle_end_combo_kill_toc.kill_role_name"
M_BATTLE_END_COMBO_KILL_TOC_KILL_ROLE_NAME_FIELD.number = 1
M_BATTLE_END_COMBO_KILL_TOC_KILL_ROLE_NAME_FIELD.index = 0
M_BATTLE_END_COMBO_KILL_TOC_KILL_ROLE_NAME_FIELD.label = 1
M_BATTLE_END_COMBO_KILL_TOC_KILL_ROLE_NAME_FIELD.has_default_value = false
M_BATTLE_END_COMBO_KILL_TOC_KILL_ROLE_NAME_FIELD.default_value = ""
M_BATTLE_END_COMBO_KILL_TOC_KILL_ROLE_NAME_FIELD.type = 9
M_BATTLE_END_COMBO_KILL_TOC_KILL_ROLE_NAME_FIELD.cpp_type = 9

M_BATTLE_END_COMBO_KILL_TOC_KILLED_ROLE_NAME_FIELD.name = "killed_role_name"
M_BATTLE_END_COMBO_KILL_TOC_KILLED_ROLE_NAME_FIELD.full_name = ".m_battle_end_combo_kill_toc.killed_role_name"
M_BATTLE_END_COMBO_KILL_TOC_KILLED_ROLE_NAME_FIELD.number = 2
M_BATTLE_END_COMBO_KILL_TOC_KILLED_ROLE_NAME_FIELD.index = 1
M_BATTLE_END_COMBO_KILL_TOC_KILLED_ROLE_NAME_FIELD.label = 1
M_BATTLE_END_COMBO_KILL_TOC_KILLED_ROLE_NAME_FIELD.has_default_value = false
M_BATTLE_END_COMBO_KILL_TOC_KILLED_ROLE_NAME_FIELD.default_value = ""
M_BATTLE_END_COMBO_KILL_TOC_KILLED_ROLE_NAME_FIELD.type = 9
M_BATTLE_END_COMBO_KILL_TOC_KILLED_ROLE_NAME_FIELD.cpp_type = 9

M_BATTLE_END_COMBO_KILL_TOC_KILL_NUM_FIELD.name = "kill_num"
M_BATTLE_END_COMBO_KILL_TOC_KILL_NUM_FIELD.full_name = ".m_battle_end_combo_kill_toc.kill_num"
M_BATTLE_END_COMBO_KILL_TOC_KILL_NUM_FIELD.number = 3
M_BATTLE_END_COMBO_KILL_TOC_KILL_NUM_FIELD.index = 2
M_BATTLE_END_COMBO_KILL_TOC_KILL_NUM_FIELD.label = 1
M_BATTLE_END_COMBO_KILL_TOC_KILL_NUM_FIELD.has_default_value = true
M_BATTLE_END_COMBO_KILL_TOC_KILL_NUM_FIELD.default_value = 0
M_BATTLE_END_COMBO_KILL_TOC_KILL_NUM_FIELD.type = 5
M_BATTLE_END_COMBO_KILL_TOC_KILL_NUM_FIELD.cpp_type = 1

M_BATTLE_END_COMBO_KILL_TOC.name = "m_battle_end_combo_kill_toc"
M_BATTLE_END_COMBO_KILL_TOC.full_name = ".m_battle_end_combo_kill_toc"
M_BATTLE_END_COMBO_KILL_TOC.nested_types = {}
M_BATTLE_END_COMBO_KILL_TOC.enum_types = {}
M_BATTLE_END_COMBO_KILL_TOC.fields = {M_BATTLE_END_COMBO_KILL_TOC_KILL_ROLE_NAME_FIELD, M_BATTLE_END_COMBO_KILL_TOC_KILLED_ROLE_NAME_FIELD, M_BATTLE_END_COMBO_KILL_TOC_KILL_NUM_FIELD}
M_BATTLE_END_COMBO_KILL_TOC.is_extendable = false
M_BATTLE_END_COMBO_KILL_TOC.extensions = {}

m_battle_end_combo_kill_toc = protobuf.Message(M_BATTLE_END_COMBO_KILL_TOC)

