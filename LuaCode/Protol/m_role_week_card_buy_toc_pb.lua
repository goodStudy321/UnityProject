--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_week_card_pb = require("Protol.p_week_card_pb")
module('Protol.m_role_week_card_buy_toc_pb')

M_ROLE_WEEK_CARD_BUY_TOC = protobuf.Descriptor();
M_ROLE_WEEK_CARD_BUY_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_ROLE_WEEK_CARD_BUY_TOC_CARD_FIELD = protobuf.FieldDescriptor();

M_ROLE_WEEK_CARD_BUY_TOC_ERR_CODE_FIELD.name = "err_code"
M_ROLE_WEEK_CARD_BUY_TOC_ERR_CODE_FIELD.full_name = ".m_role_week_card_buy_toc.err_code"
M_ROLE_WEEK_CARD_BUY_TOC_ERR_CODE_FIELD.number = 1
M_ROLE_WEEK_CARD_BUY_TOC_ERR_CODE_FIELD.index = 0
M_ROLE_WEEK_CARD_BUY_TOC_ERR_CODE_FIELD.label = 1
M_ROLE_WEEK_CARD_BUY_TOC_ERR_CODE_FIELD.has_default_value = true
M_ROLE_WEEK_CARD_BUY_TOC_ERR_CODE_FIELD.default_value = 0
M_ROLE_WEEK_CARD_BUY_TOC_ERR_CODE_FIELD.type = 5
M_ROLE_WEEK_CARD_BUY_TOC_ERR_CODE_FIELD.cpp_type = 1

M_ROLE_WEEK_CARD_BUY_TOC_CARD_FIELD.name = "card"
M_ROLE_WEEK_CARD_BUY_TOC_CARD_FIELD.full_name = ".m_role_week_card_buy_toc.card"
M_ROLE_WEEK_CARD_BUY_TOC_CARD_FIELD.number = 2
M_ROLE_WEEK_CARD_BUY_TOC_CARD_FIELD.index = 1
M_ROLE_WEEK_CARD_BUY_TOC_CARD_FIELD.label = 1
M_ROLE_WEEK_CARD_BUY_TOC_CARD_FIELD.has_default_value = false
M_ROLE_WEEK_CARD_BUY_TOC_CARD_FIELD.default_value = nil
M_ROLE_WEEK_CARD_BUY_TOC_CARD_FIELD.message_type = p_week_card_pb.P_WEEK_CARD
M_ROLE_WEEK_CARD_BUY_TOC_CARD_FIELD.type = 11
M_ROLE_WEEK_CARD_BUY_TOC_CARD_FIELD.cpp_type = 10

M_ROLE_WEEK_CARD_BUY_TOC.name = "m_role_week_card_buy_toc"
M_ROLE_WEEK_CARD_BUY_TOC.full_name = ".m_role_week_card_buy_toc"
M_ROLE_WEEK_CARD_BUY_TOC.nested_types = {}
M_ROLE_WEEK_CARD_BUY_TOC.enum_types = {}
M_ROLE_WEEK_CARD_BUY_TOC.fields = {M_ROLE_WEEK_CARD_BUY_TOC_ERR_CODE_FIELD, M_ROLE_WEEK_CARD_BUY_TOC_CARD_FIELD}
M_ROLE_WEEK_CARD_BUY_TOC.is_extendable = false
M_ROLE_WEEK_CARD_BUY_TOC.extensions = {}

m_role_week_card_buy_toc = protobuf.Message(M_ROLE_WEEK_CARD_BUY_TOC)
