--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_world_boss_kill_pb = require("Protol.p_world_boss_kill_pb")
module('Protol.m_world_boss_kill_toc_pb')

M_WORLD_BOSS_KILL_TOC = protobuf.Descriptor();
M_WORLD_BOSS_KILL_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_WORLD_BOSS_KILL_TOC_KILL_LIST_FIELD = protobuf.FieldDescriptor();

M_WORLD_BOSS_KILL_TOC_ERR_CODE_FIELD.name = "err_code"
M_WORLD_BOSS_KILL_TOC_ERR_CODE_FIELD.full_name = ".m_world_boss_kill_toc.err_code"
M_WORLD_BOSS_KILL_TOC_ERR_CODE_FIELD.number = 1
M_WORLD_BOSS_KILL_TOC_ERR_CODE_FIELD.index = 0
M_WORLD_BOSS_KILL_TOC_ERR_CODE_FIELD.label = 1
M_WORLD_BOSS_KILL_TOC_ERR_CODE_FIELD.has_default_value = true
M_WORLD_BOSS_KILL_TOC_ERR_CODE_FIELD.default_value = 0
M_WORLD_BOSS_KILL_TOC_ERR_CODE_FIELD.type = 5
M_WORLD_BOSS_KILL_TOC_ERR_CODE_FIELD.cpp_type = 1

M_WORLD_BOSS_KILL_TOC_KILL_LIST_FIELD.name = "kill_list"
M_WORLD_BOSS_KILL_TOC_KILL_LIST_FIELD.full_name = ".m_world_boss_kill_toc.kill_list"
M_WORLD_BOSS_KILL_TOC_KILL_LIST_FIELD.number = 2
M_WORLD_BOSS_KILL_TOC_KILL_LIST_FIELD.index = 1
M_WORLD_BOSS_KILL_TOC_KILL_LIST_FIELD.label = 3
M_WORLD_BOSS_KILL_TOC_KILL_LIST_FIELD.has_default_value = false
M_WORLD_BOSS_KILL_TOC_KILL_LIST_FIELD.default_value = {}
M_WORLD_BOSS_KILL_TOC_KILL_LIST_FIELD.message_type = p_world_boss_kill_pb.P_WORLD_BOSS_KILL
M_WORLD_BOSS_KILL_TOC_KILL_LIST_FIELD.type = 11
M_WORLD_BOSS_KILL_TOC_KILL_LIST_FIELD.cpp_type = 10

M_WORLD_BOSS_KILL_TOC.name = "m_world_boss_kill_toc"
M_WORLD_BOSS_KILL_TOC.full_name = ".m_world_boss_kill_toc"
M_WORLD_BOSS_KILL_TOC.nested_types = {}
M_WORLD_BOSS_KILL_TOC.enum_types = {}
M_WORLD_BOSS_KILL_TOC.fields = {M_WORLD_BOSS_KILL_TOC_ERR_CODE_FIELD, M_WORLD_BOSS_KILL_TOC_KILL_LIST_FIELD}
M_WORLD_BOSS_KILL_TOC.is_extendable = false
M_WORLD_BOSS_KILL_TOC.extensions = {}

m_world_boss_kill_toc = protobuf.Message(M_WORLD_BOSS_KILL_TOC)
