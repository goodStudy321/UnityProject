--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_team_match_toc_pb')

M_TEAM_MATCH_TOC = protobuf.Descriptor();
M_TEAM_MATCH_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_TEAM_MATCH_TOC_COPY_ID_FIELD = protobuf.FieldDescriptor();
M_TEAM_MATCH_TOC_IS_MATCHING_FIELD = protobuf.FieldDescriptor();

M_TEAM_MATCH_TOC_ERR_CODE_FIELD.name = "err_code"
M_TEAM_MATCH_TOC_ERR_CODE_FIELD.full_name = ".m_team_match_toc.err_code"
M_TEAM_MATCH_TOC_ERR_CODE_FIELD.number = 1
M_TEAM_MATCH_TOC_ERR_CODE_FIELD.index = 0
M_TEAM_MATCH_TOC_ERR_CODE_FIELD.label = 1
M_TEAM_MATCH_TOC_ERR_CODE_FIELD.has_default_value = true
M_TEAM_MATCH_TOC_ERR_CODE_FIELD.default_value = 0
M_TEAM_MATCH_TOC_ERR_CODE_FIELD.type = 5
M_TEAM_MATCH_TOC_ERR_CODE_FIELD.cpp_type = 1

M_TEAM_MATCH_TOC_COPY_ID_FIELD.name = "copy_id"
M_TEAM_MATCH_TOC_COPY_ID_FIELD.full_name = ".m_team_match_toc.copy_id"
M_TEAM_MATCH_TOC_COPY_ID_FIELD.number = 2
M_TEAM_MATCH_TOC_COPY_ID_FIELD.index = 1
M_TEAM_MATCH_TOC_COPY_ID_FIELD.label = 1
M_TEAM_MATCH_TOC_COPY_ID_FIELD.has_default_value = true
M_TEAM_MATCH_TOC_COPY_ID_FIELD.default_value = 0
M_TEAM_MATCH_TOC_COPY_ID_FIELD.type = 5
M_TEAM_MATCH_TOC_COPY_ID_FIELD.cpp_type = 1

M_TEAM_MATCH_TOC_IS_MATCHING_FIELD.name = "is_matching"
M_TEAM_MATCH_TOC_IS_MATCHING_FIELD.full_name = ".m_team_match_toc.is_matching"
M_TEAM_MATCH_TOC_IS_MATCHING_FIELD.number = 3
M_TEAM_MATCH_TOC_IS_MATCHING_FIELD.index = 2
M_TEAM_MATCH_TOC_IS_MATCHING_FIELD.label = 1
M_TEAM_MATCH_TOC_IS_MATCHING_FIELD.has_default_value = true
M_TEAM_MATCH_TOC_IS_MATCHING_FIELD.default_value = true
M_TEAM_MATCH_TOC_IS_MATCHING_FIELD.type = 8
M_TEAM_MATCH_TOC_IS_MATCHING_FIELD.cpp_type = 7

M_TEAM_MATCH_TOC.name = "m_team_match_toc"
M_TEAM_MATCH_TOC.full_name = ".m_team_match_toc"
M_TEAM_MATCH_TOC.nested_types = {}
M_TEAM_MATCH_TOC.enum_types = {}
M_TEAM_MATCH_TOC.fields = {M_TEAM_MATCH_TOC_ERR_CODE_FIELD, M_TEAM_MATCH_TOC_COPY_ID_FIELD, M_TEAM_MATCH_TOC_IS_MATCHING_FIELD}
M_TEAM_MATCH_TOC.is_extendable = false
M_TEAM_MATCH_TOC.extensions = {}

m_team_match_toc = protobuf.Message(M_TEAM_MATCH_TOC)

