--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_month_card_buy_toc_pb')

M_MONTH_CARD_BUY_TOC = protobuf.Descriptor();
M_MONTH_CARD_BUY_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_MONTH_CARD_BUY_TOC_IS_REWARD_FIELD = protobuf.FieldDescriptor();
M_MONTH_CARD_BUY_TOC_IS_PRINCIPAL_REWARD_FIELD = protobuf.FieldDescriptor();
M_MONTH_CARD_BUY_TOC_REMAIN_DAYS_FIELD = protobuf.FieldDescriptor();

M_MONTH_CARD_BUY_TOC_ERR_CODE_FIELD.name = "err_code"
M_MONTH_CARD_BUY_TOC_ERR_CODE_FIELD.full_name = ".m_month_card_buy_toc.err_code"
M_MONTH_CARD_BUY_TOC_ERR_CODE_FIELD.number = 1
M_MONTH_CARD_BUY_TOC_ERR_CODE_FIELD.index = 0
M_MONTH_CARD_BUY_TOC_ERR_CODE_FIELD.label = 1
M_MONTH_CARD_BUY_TOC_ERR_CODE_FIELD.has_default_value = true
M_MONTH_CARD_BUY_TOC_ERR_CODE_FIELD.default_value = 0
M_MONTH_CARD_BUY_TOC_ERR_CODE_FIELD.type = 5
M_MONTH_CARD_BUY_TOC_ERR_CODE_FIELD.cpp_type = 1

M_MONTH_CARD_BUY_TOC_IS_REWARD_FIELD.name = "is_reward"
M_MONTH_CARD_BUY_TOC_IS_REWARD_FIELD.full_name = ".m_month_card_buy_toc.is_reward"
M_MONTH_CARD_BUY_TOC_IS_REWARD_FIELD.number = 2
M_MONTH_CARD_BUY_TOC_IS_REWARD_FIELD.index = 1
M_MONTH_CARD_BUY_TOC_IS_REWARD_FIELD.label = 1
M_MONTH_CARD_BUY_TOC_IS_REWARD_FIELD.has_default_value = true
M_MONTH_CARD_BUY_TOC_IS_REWARD_FIELD.default_value = true
M_MONTH_CARD_BUY_TOC_IS_REWARD_FIELD.type = 8
M_MONTH_CARD_BUY_TOC_IS_REWARD_FIELD.cpp_type = 7

M_MONTH_CARD_BUY_TOC_IS_PRINCIPAL_REWARD_FIELD.name = "is_principal_reward"
M_MONTH_CARD_BUY_TOC_IS_PRINCIPAL_REWARD_FIELD.full_name = ".m_month_card_buy_toc.is_principal_reward"
M_MONTH_CARD_BUY_TOC_IS_PRINCIPAL_REWARD_FIELD.number = 3
M_MONTH_CARD_BUY_TOC_IS_PRINCIPAL_REWARD_FIELD.index = 2
M_MONTH_CARD_BUY_TOC_IS_PRINCIPAL_REWARD_FIELD.label = 1
M_MONTH_CARD_BUY_TOC_IS_PRINCIPAL_REWARD_FIELD.has_default_value = true
M_MONTH_CARD_BUY_TOC_IS_PRINCIPAL_REWARD_FIELD.default_value = true
M_MONTH_CARD_BUY_TOC_IS_PRINCIPAL_REWARD_FIELD.type = 8
M_MONTH_CARD_BUY_TOC_IS_PRINCIPAL_REWARD_FIELD.cpp_type = 7

M_MONTH_CARD_BUY_TOC_REMAIN_DAYS_FIELD.name = "remain_days"
M_MONTH_CARD_BUY_TOC_REMAIN_DAYS_FIELD.full_name = ".m_month_card_buy_toc.remain_days"
M_MONTH_CARD_BUY_TOC_REMAIN_DAYS_FIELD.number = 4
M_MONTH_CARD_BUY_TOC_REMAIN_DAYS_FIELD.index = 3
M_MONTH_CARD_BUY_TOC_REMAIN_DAYS_FIELD.label = 1
M_MONTH_CARD_BUY_TOC_REMAIN_DAYS_FIELD.has_default_value = true
M_MONTH_CARD_BUY_TOC_REMAIN_DAYS_FIELD.default_value = 0
M_MONTH_CARD_BUY_TOC_REMAIN_DAYS_FIELD.type = 5
M_MONTH_CARD_BUY_TOC_REMAIN_DAYS_FIELD.cpp_type = 1

M_MONTH_CARD_BUY_TOC.name = "m_month_card_buy_toc"
M_MONTH_CARD_BUY_TOC.full_name = ".m_month_card_buy_toc"
M_MONTH_CARD_BUY_TOC.nested_types = {}
M_MONTH_CARD_BUY_TOC.enum_types = {}
M_MONTH_CARD_BUY_TOC.fields = {M_MONTH_CARD_BUY_TOC_ERR_CODE_FIELD, M_MONTH_CARD_BUY_TOC_IS_REWARD_FIELD, M_MONTH_CARD_BUY_TOC_IS_PRINCIPAL_REWARD_FIELD, M_MONTH_CARD_BUY_TOC_REMAIN_DAYS_FIELD}
M_MONTH_CARD_BUY_TOC.is_extendable = false
M_MONTH_CARD_BUY_TOC.extensions = {}

m_month_card_buy_toc = protobuf.Message(M_MONTH_CARD_BUY_TOC)
