--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_act_login_info_toc_pb')

M_ACT_LOGIN_INFO_TOC = protobuf.Descriptor();
M_ACT_LOGIN_INFO_TOC_RETURN_REWARD_STATUS_FIELD = protobuf.FieldDescriptor();
M_ACT_LOGIN_INFO_TOC_TODAY_REWARD_STATUS_FIELD = protobuf.FieldDescriptor();

M_ACT_LOGIN_INFO_TOC_RETURN_REWARD_STATUS_FIELD.name = "return_reward_status"
M_ACT_LOGIN_INFO_TOC_RETURN_REWARD_STATUS_FIELD.full_name = ".m_act_login_info_toc.return_reward_status"
M_ACT_LOGIN_INFO_TOC_RETURN_REWARD_STATUS_FIELD.number = 1
M_ACT_LOGIN_INFO_TOC_RETURN_REWARD_STATUS_FIELD.index = 0
M_ACT_LOGIN_INFO_TOC_RETURN_REWARD_STATUS_FIELD.label = 1
M_ACT_LOGIN_INFO_TOC_RETURN_REWARD_STATUS_FIELD.has_default_value = true
M_ACT_LOGIN_INFO_TOC_RETURN_REWARD_STATUS_FIELD.default_value = 0
M_ACT_LOGIN_INFO_TOC_RETURN_REWARD_STATUS_FIELD.type = 5
M_ACT_LOGIN_INFO_TOC_RETURN_REWARD_STATUS_FIELD.cpp_type = 1

M_ACT_LOGIN_INFO_TOC_TODAY_REWARD_STATUS_FIELD.name = "today_reward_status"
M_ACT_LOGIN_INFO_TOC_TODAY_REWARD_STATUS_FIELD.full_name = ".m_act_login_info_toc.today_reward_status"
M_ACT_LOGIN_INFO_TOC_TODAY_REWARD_STATUS_FIELD.number = 2
M_ACT_LOGIN_INFO_TOC_TODAY_REWARD_STATUS_FIELD.index = 1
M_ACT_LOGIN_INFO_TOC_TODAY_REWARD_STATUS_FIELD.label = 1
M_ACT_LOGIN_INFO_TOC_TODAY_REWARD_STATUS_FIELD.has_default_value = true
M_ACT_LOGIN_INFO_TOC_TODAY_REWARD_STATUS_FIELD.default_value = 0
M_ACT_LOGIN_INFO_TOC_TODAY_REWARD_STATUS_FIELD.type = 5
M_ACT_LOGIN_INFO_TOC_TODAY_REWARD_STATUS_FIELD.cpp_type = 1

M_ACT_LOGIN_INFO_TOC.name = "m_act_login_info_toc"
M_ACT_LOGIN_INFO_TOC.full_name = ".m_act_login_info_toc"
M_ACT_LOGIN_INFO_TOC.nested_types = {}
M_ACT_LOGIN_INFO_TOC.enum_types = {}
M_ACT_LOGIN_INFO_TOC.fields = {M_ACT_LOGIN_INFO_TOC_RETURN_REWARD_STATUS_FIELD, M_ACT_LOGIN_INFO_TOC_TODAY_REWARD_STATUS_FIELD}
M_ACT_LOGIN_INFO_TOC.is_extendable = false
M_ACT_LOGIN_INFO_TOC.extensions = {}

m_act_login_info_toc = protobuf.Message(M_ACT_LOGIN_INFO_TOC)

