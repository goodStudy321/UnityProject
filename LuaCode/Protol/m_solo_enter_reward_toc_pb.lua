--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_solo_enter_reward_toc_pb')

M_SOLO_ENTER_REWARD_TOC = protobuf.Descriptor();
M_SOLO_ENTER_REWARD_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_SOLO_ENTER_REWARD_TOC_TYPE_FIELD = protobuf.FieldDescriptor();
M_SOLO_ENTER_REWARD_TOC_ENTER_LIST_FIELD = protobuf.FieldDescriptor();

M_SOLO_ENTER_REWARD_TOC_ERR_CODE_FIELD.name = "err_code"
M_SOLO_ENTER_REWARD_TOC_ERR_CODE_FIELD.full_name = ".m_solo_enter_reward_toc.err_code"
M_SOLO_ENTER_REWARD_TOC_ERR_CODE_FIELD.number = 1
M_SOLO_ENTER_REWARD_TOC_ERR_CODE_FIELD.index = 0
M_SOLO_ENTER_REWARD_TOC_ERR_CODE_FIELD.label = 1
M_SOLO_ENTER_REWARD_TOC_ERR_CODE_FIELD.has_default_value = true
M_SOLO_ENTER_REWARD_TOC_ERR_CODE_FIELD.default_value = 0
M_SOLO_ENTER_REWARD_TOC_ERR_CODE_FIELD.type = 5
M_SOLO_ENTER_REWARD_TOC_ERR_CODE_FIELD.cpp_type = 1

M_SOLO_ENTER_REWARD_TOC_TYPE_FIELD.name = "type"
M_SOLO_ENTER_REWARD_TOC_TYPE_FIELD.full_name = ".m_solo_enter_reward_toc.type"
M_SOLO_ENTER_REWARD_TOC_TYPE_FIELD.number = 2
M_SOLO_ENTER_REWARD_TOC_TYPE_FIELD.index = 1
M_SOLO_ENTER_REWARD_TOC_TYPE_FIELD.label = 1
M_SOLO_ENTER_REWARD_TOC_TYPE_FIELD.has_default_value = true
M_SOLO_ENTER_REWARD_TOC_TYPE_FIELD.default_value = 0
M_SOLO_ENTER_REWARD_TOC_TYPE_FIELD.type = 5
M_SOLO_ENTER_REWARD_TOC_TYPE_FIELD.cpp_type = 1

M_SOLO_ENTER_REWARD_TOC_ENTER_LIST_FIELD.name = "enter_list"
M_SOLO_ENTER_REWARD_TOC_ENTER_LIST_FIELD.full_name = ".m_solo_enter_reward_toc.enter_list"
M_SOLO_ENTER_REWARD_TOC_ENTER_LIST_FIELD.number = 3
M_SOLO_ENTER_REWARD_TOC_ENTER_LIST_FIELD.index = 2
M_SOLO_ENTER_REWARD_TOC_ENTER_LIST_FIELD.label = 3
M_SOLO_ENTER_REWARD_TOC_ENTER_LIST_FIELD.has_default_value = false
M_SOLO_ENTER_REWARD_TOC_ENTER_LIST_FIELD.default_value = {}
M_SOLO_ENTER_REWARD_TOC_ENTER_LIST_FIELD.type = 5
M_SOLO_ENTER_REWARD_TOC_ENTER_LIST_FIELD.cpp_type = 1

M_SOLO_ENTER_REWARD_TOC.name = "m_solo_enter_reward_toc"
M_SOLO_ENTER_REWARD_TOC.full_name = ".m_solo_enter_reward_toc"
M_SOLO_ENTER_REWARD_TOC.nested_types = {}
M_SOLO_ENTER_REWARD_TOC.enum_types = {}
M_SOLO_ENTER_REWARD_TOC.fields = {M_SOLO_ENTER_REWARD_TOC_ERR_CODE_FIELD, M_SOLO_ENTER_REWARD_TOC_TYPE_FIELD, M_SOLO_ENTER_REWARD_TOC_ENTER_LIST_FIELD}
M_SOLO_ENTER_REWARD_TOC.is_extendable = false
M_SOLO_ENTER_REWARD_TOC.extensions = {}

m_solo_enter_reward_toc = protobuf.Message(M_SOLO_ENTER_REWARD_TOC)

