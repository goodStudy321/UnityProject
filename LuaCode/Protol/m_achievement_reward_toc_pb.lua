--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_achievement_reward_toc_pb')

M_ACHIEVEMENT_REWARD_TOC = protobuf.Descriptor();
M_ACHIEVEMENT_REWARD_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_ACHIEVEMENT_REWARD_TOC_ACHIEVEMENT_ID_FIELD = protobuf.FieldDescriptor();

M_ACHIEVEMENT_REWARD_TOC_ERR_CODE_FIELD.name = "err_code"
M_ACHIEVEMENT_REWARD_TOC_ERR_CODE_FIELD.full_name = ".m_achievement_reward_toc.err_code"
M_ACHIEVEMENT_REWARD_TOC_ERR_CODE_FIELD.number = 1
M_ACHIEVEMENT_REWARD_TOC_ERR_CODE_FIELD.index = 0
M_ACHIEVEMENT_REWARD_TOC_ERR_CODE_FIELD.label = 1
M_ACHIEVEMENT_REWARD_TOC_ERR_CODE_FIELD.has_default_value = true
M_ACHIEVEMENT_REWARD_TOC_ERR_CODE_FIELD.default_value = 0
M_ACHIEVEMENT_REWARD_TOC_ERR_CODE_FIELD.type = 5
M_ACHIEVEMENT_REWARD_TOC_ERR_CODE_FIELD.cpp_type = 1

M_ACHIEVEMENT_REWARD_TOC_ACHIEVEMENT_ID_FIELD.name = "achievement_id"
M_ACHIEVEMENT_REWARD_TOC_ACHIEVEMENT_ID_FIELD.full_name = ".m_achievement_reward_toc.achievement_id"
M_ACHIEVEMENT_REWARD_TOC_ACHIEVEMENT_ID_FIELD.number = 2
M_ACHIEVEMENT_REWARD_TOC_ACHIEVEMENT_ID_FIELD.index = 1
M_ACHIEVEMENT_REWARD_TOC_ACHIEVEMENT_ID_FIELD.label = 1
M_ACHIEVEMENT_REWARD_TOC_ACHIEVEMENT_ID_FIELD.has_default_value = true
M_ACHIEVEMENT_REWARD_TOC_ACHIEVEMENT_ID_FIELD.default_value = 0
M_ACHIEVEMENT_REWARD_TOC_ACHIEVEMENT_ID_FIELD.type = 5
M_ACHIEVEMENT_REWARD_TOC_ACHIEVEMENT_ID_FIELD.cpp_type = 1

M_ACHIEVEMENT_REWARD_TOC.name = "m_achievement_reward_toc"
M_ACHIEVEMENT_REWARD_TOC.full_name = ".m_achievement_reward_toc"
M_ACHIEVEMENT_REWARD_TOC.nested_types = {}
M_ACHIEVEMENT_REWARD_TOC.enum_types = {}
M_ACHIEVEMENT_REWARD_TOC.fields = {M_ACHIEVEMENT_REWARD_TOC_ERR_CODE_FIELD, M_ACHIEVEMENT_REWARD_TOC_ACHIEVEMENT_ID_FIELD}
M_ACHIEVEMENT_REWARD_TOC.is_extendable = false
M_ACHIEVEMENT_REWARD_TOC.extensions = {}

m_achievement_reward_toc = protobuf.Message(M_ACHIEVEMENT_REWARD_TOC)

