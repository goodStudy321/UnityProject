--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_kv_pb = require("Protol.p_kv_pb")
module('Protol.m_oss_trevi_fountain_reward_toc_pb')

M_OSS_TREVI_FOUNTAIN_REWARD_TOC = protobuf.Descriptor();
M_OSS_TREVI_FOUNTAIN_REWARD_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_OSS_TREVI_FOUNTAIN_REWARD_TOC_REWARD_FIELD = protobuf.FieldDescriptor();

M_OSS_TREVI_FOUNTAIN_REWARD_TOC_ERR_CODE_FIELD.name = "err_code"
M_OSS_TREVI_FOUNTAIN_REWARD_TOC_ERR_CODE_FIELD.full_name = ".m_oss_trevi_fountain_reward_toc.err_code"
M_OSS_TREVI_FOUNTAIN_REWARD_TOC_ERR_CODE_FIELD.number = 1
M_OSS_TREVI_FOUNTAIN_REWARD_TOC_ERR_CODE_FIELD.index = 0
M_OSS_TREVI_FOUNTAIN_REWARD_TOC_ERR_CODE_FIELD.label = 1
M_OSS_TREVI_FOUNTAIN_REWARD_TOC_ERR_CODE_FIELD.has_default_value = true
M_OSS_TREVI_FOUNTAIN_REWARD_TOC_ERR_CODE_FIELD.default_value = 0
M_OSS_TREVI_FOUNTAIN_REWARD_TOC_ERR_CODE_FIELD.type = 5
M_OSS_TREVI_FOUNTAIN_REWARD_TOC_ERR_CODE_FIELD.cpp_type = 1

M_OSS_TREVI_FOUNTAIN_REWARD_TOC_REWARD_FIELD.name = "reward"
M_OSS_TREVI_FOUNTAIN_REWARD_TOC_REWARD_FIELD.full_name = ".m_oss_trevi_fountain_reward_toc.reward"
M_OSS_TREVI_FOUNTAIN_REWARD_TOC_REWARD_FIELD.number = 2
M_OSS_TREVI_FOUNTAIN_REWARD_TOC_REWARD_FIELD.index = 1
M_OSS_TREVI_FOUNTAIN_REWARD_TOC_REWARD_FIELD.label = 1
M_OSS_TREVI_FOUNTAIN_REWARD_TOC_REWARD_FIELD.has_default_value = false
M_OSS_TREVI_FOUNTAIN_REWARD_TOC_REWARD_FIELD.default_value = nil
M_OSS_TREVI_FOUNTAIN_REWARD_TOC_REWARD_FIELD.message_type = p_kv_pb.P_KV
M_OSS_TREVI_FOUNTAIN_REWARD_TOC_REWARD_FIELD.type = 11
M_OSS_TREVI_FOUNTAIN_REWARD_TOC_REWARD_FIELD.cpp_type = 10

M_OSS_TREVI_FOUNTAIN_REWARD_TOC.name = "m_oss_trevi_fountain_reward_toc"
M_OSS_TREVI_FOUNTAIN_REWARD_TOC.full_name = ".m_oss_trevi_fountain_reward_toc"
M_OSS_TREVI_FOUNTAIN_REWARD_TOC.nested_types = {}
M_OSS_TREVI_FOUNTAIN_REWARD_TOC.enum_types = {}
M_OSS_TREVI_FOUNTAIN_REWARD_TOC.fields = {M_OSS_TREVI_FOUNTAIN_REWARD_TOC_ERR_CODE_FIELD, M_OSS_TREVI_FOUNTAIN_REWARD_TOC_REWARD_FIELD}
M_OSS_TREVI_FOUNTAIN_REWARD_TOC.is_extendable = false
M_OSS_TREVI_FOUNTAIN_REWARD_TOC.extensions = {}

m_oss_trevi_fountain_reward_toc = protobuf.Message(M_OSS_TREVI_FOUNTAIN_REWARD_TOC)

