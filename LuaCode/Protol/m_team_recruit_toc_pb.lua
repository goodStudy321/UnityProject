--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_chat_role_pb = require("Protol.p_chat_role_pb")
module('Protol.m_team_recruit_toc_pb')

M_TEAM_RECRUIT_TOC = protobuf.Descriptor();
M_TEAM_RECRUIT_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_TEAM_RECRUIT_TOC_ROLE_INFO_FIELD = protobuf.FieldDescriptor();
M_TEAM_RECRUIT_TOC_MAP_ID_FIELD = protobuf.FieldDescriptor();
M_TEAM_RECRUIT_TOC_MIN_LEVEL_FIELD = protobuf.FieldDescriptor();
M_TEAM_RECRUIT_TOC_MAX_LEVEL_FIELD = protobuf.FieldDescriptor();
M_TEAM_RECRUIT_TOC_TEAM_ID_FIELD = protobuf.FieldDescriptor();
M_TEAM_RECRUIT_TOC_SUB_TYPE_FIELD = protobuf.FieldDescriptor();

M_TEAM_RECRUIT_TOC_ERR_CODE_FIELD.name = "err_code"
M_TEAM_RECRUIT_TOC_ERR_CODE_FIELD.full_name = ".m_team_recruit_toc.err_code"
M_TEAM_RECRUIT_TOC_ERR_CODE_FIELD.number = 1
M_TEAM_RECRUIT_TOC_ERR_CODE_FIELD.index = 0
M_TEAM_RECRUIT_TOC_ERR_CODE_FIELD.label = 1
M_TEAM_RECRUIT_TOC_ERR_CODE_FIELD.has_default_value = true
M_TEAM_RECRUIT_TOC_ERR_CODE_FIELD.default_value = 0
M_TEAM_RECRUIT_TOC_ERR_CODE_FIELD.type = 5
M_TEAM_RECRUIT_TOC_ERR_CODE_FIELD.cpp_type = 1

M_TEAM_RECRUIT_TOC_ROLE_INFO_FIELD.name = "role_info"
M_TEAM_RECRUIT_TOC_ROLE_INFO_FIELD.full_name = ".m_team_recruit_toc.role_info"
M_TEAM_RECRUIT_TOC_ROLE_INFO_FIELD.number = 2
M_TEAM_RECRUIT_TOC_ROLE_INFO_FIELD.index = 1
M_TEAM_RECRUIT_TOC_ROLE_INFO_FIELD.label = 1
M_TEAM_RECRUIT_TOC_ROLE_INFO_FIELD.has_default_value = false
M_TEAM_RECRUIT_TOC_ROLE_INFO_FIELD.default_value = nil
M_TEAM_RECRUIT_TOC_ROLE_INFO_FIELD.message_type = p_chat_role_pb.P_CHAT_ROLE
M_TEAM_RECRUIT_TOC_ROLE_INFO_FIELD.type = 11
M_TEAM_RECRUIT_TOC_ROLE_INFO_FIELD.cpp_type = 10

M_TEAM_RECRUIT_TOC_MAP_ID_FIELD.name = "map_id"
M_TEAM_RECRUIT_TOC_MAP_ID_FIELD.full_name = ".m_team_recruit_toc.map_id"
M_TEAM_RECRUIT_TOC_MAP_ID_FIELD.number = 3
M_TEAM_RECRUIT_TOC_MAP_ID_FIELD.index = 2
M_TEAM_RECRUIT_TOC_MAP_ID_FIELD.label = 1
M_TEAM_RECRUIT_TOC_MAP_ID_FIELD.has_default_value = true
M_TEAM_RECRUIT_TOC_MAP_ID_FIELD.default_value = 0
M_TEAM_RECRUIT_TOC_MAP_ID_FIELD.type = 5
M_TEAM_RECRUIT_TOC_MAP_ID_FIELD.cpp_type = 1

M_TEAM_RECRUIT_TOC_MIN_LEVEL_FIELD.name = "min_level"
M_TEAM_RECRUIT_TOC_MIN_LEVEL_FIELD.full_name = ".m_team_recruit_toc.min_level"
M_TEAM_RECRUIT_TOC_MIN_LEVEL_FIELD.number = 4
M_TEAM_RECRUIT_TOC_MIN_LEVEL_FIELD.index = 3
M_TEAM_RECRUIT_TOC_MIN_LEVEL_FIELD.label = 1
M_TEAM_RECRUIT_TOC_MIN_LEVEL_FIELD.has_default_value = true
M_TEAM_RECRUIT_TOC_MIN_LEVEL_FIELD.default_value = 0
M_TEAM_RECRUIT_TOC_MIN_LEVEL_FIELD.type = 5
M_TEAM_RECRUIT_TOC_MIN_LEVEL_FIELD.cpp_type = 1

M_TEAM_RECRUIT_TOC_MAX_LEVEL_FIELD.name = "max_level"
M_TEAM_RECRUIT_TOC_MAX_LEVEL_FIELD.full_name = ".m_team_recruit_toc.max_level"
M_TEAM_RECRUIT_TOC_MAX_LEVEL_FIELD.number = 5
M_TEAM_RECRUIT_TOC_MAX_LEVEL_FIELD.index = 4
M_TEAM_RECRUIT_TOC_MAX_LEVEL_FIELD.label = 1
M_TEAM_RECRUIT_TOC_MAX_LEVEL_FIELD.has_default_value = true
M_TEAM_RECRUIT_TOC_MAX_LEVEL_FIELD.default_value = 0
M_TEAM_RECRUIT_TOC_MAX_LEVEL_FIELD.type = 5
M_TEAM_RECRUIT_TOC_MAX_LEVEL_FIELD.cpp_type = 1

M_TEAM_RECRUIT_TOC_TEAM_ID_FIELD.name = "team_id"
M_TEAM_RECRUIT_TOC_TEAM_ID_FIELD.full_name = ".m_team_recruit_toc.team_id"
M_TEAM_RECRUIT_TOC_TEAM_ID_FIELD.number = 6
M_TEAM_RECRUIT_TOC_TEAM_ID_FIELD.index = 5
M_TEAM_RECRUIT_TOC_TEAM_ID_FIELD.label = 1
M_TEAM_RECRUIT_TOC_TEAM_ID_FIELD.has_default_value = true
M_TEAM_RECRUIT_TOC_TEAM_ID_FIELD.default_value = 0
M_TEAM_RECRUIT_TOC_TEAM_ID_FIELD.type = 5
M_TEAM_RECRUIT_TOC_TEAM_ID_FIELD.cpp_type = 1

M_TEAM_RECRUIT_TOC_SUB_TYPE_FIELD.name = "sub_type"
M_TEAM_RECRUIT_TOC_SUB_TYPE_FIELD.full_name = ".m_team_recruit_toc.sub_type"
M_TEAM_RECRUIT_TOC_SUB_TYPE_FIELD.number = 7
M_TEAM_RECRUIT_TOC_SUB_TYPE_FIELD.index = 6
M_TEAM_RECRUIT_TOC_SUB_TYPE_FIELD.label = 1
M_TEAM_RECRUIT_TOC_SUB_TYPE_FIELD.has_default_value = true
M_TEAM_RECRUIT_TOC_SUB_TYPE_FIELD.default_value = 0
M_TEAM_RECRUIT_TOC_SUB_TYPE_FIELD.type = 5
M_TEAM_RECRUIT_TOC_SUB_TYPE_FIELD.cpp_type = 1

M_TEAM_RECRUIT_TOC.name = "m_team_recruit_toc"
M_TEAM_RECRUIT_TOC.full_name = ".m_team_recruit_toc"
M_TEAM_RECRUIT_TOC.nested_types = {}
M_TEAM_RECRUIT_TOC.enum_types = {}
M_TEAM_RECRUIT_TOC.fields = {M_TEAM_RECRUIT_TOC_ERR_CODE_FIELD, M_TEAM_RECRUIT_TOC_ROLE_INFO_FIELD, M_TEAM_RECRUIT_TOC_MAP_ID_FIELD, M_TEAM_RECRUIT_TOC_MIN_LEVEL_FIELD, M_TEAM_RECRUIT_TOC_MAX_LEVEL_FIELD, M_TEAM_RECRUIT_TOC_TEAM_ID_FIELD, M_TEAM_RECRUIT_TOC_SUB_TYPE_FIELD}
M_TEAM_RECRUIT_TOC.is_extendable = false
M_TEAM_RECRUIT_TOC.extensions = {}

m_team_recruit_toc = protobuf.Message(M_TEAM_RECRUIT_TOC)

