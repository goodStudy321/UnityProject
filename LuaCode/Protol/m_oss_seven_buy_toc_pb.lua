--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_kv_pb = require("Protol.p_kv_pb")
module('Protol.m_oss_seven_buy_toc_pb')

M_OSS_SEVEN_BUY_TOC = protobuf.Descriptor();
M_OSS_SEVEN_BUY_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_OSS_SEVEN_BUY_TOC_UPDATE_LIST_FIELD = protobuf.FieldDescriptor();

M_OSS_SEVEN_BUY_TOC_ERR_CODE_FIELD.name = "err_code"
M_OSS_SEVEN_BUY_TOC_ERR_CODE_FIELD.full_name = ".m_oss_seven_buy_toc.err_code"
M_OSS_SEVEN_BUY_TOC_ERR_CODE_FIELD.number = 1
M_OSS_SEVEN_BUY_TOC_ERR_CODE_FIELD.index = 0
M_OSS_SEVEN_BUY_TOC_ERR_CODE_FIELD.label = 1
M_OSS_SEVEN_BUY_TOC_ERR_CODE_FIELD.has_default_value = true
M_OSS_SEVEN_BUY_TOC_ERR_CODE_FIELD.default_value = 0
M_OSS_SEVEN_BUY_TOC_ERR_CODE_FIELD.type = 5
M_OSS_SEVEN_BUY_TOC_ERR_CODE_FIELD.cpp_type = 1

M_OSS_SEVEN_BUY_TOC_UPDATE_LIST_FIELD.name = "update_list"
M_OSS_SEVEN_BUY_TOC_UPDATE_LIST_FIELD.full_name = ".m_oss_seven_buy_toc.update_list"
M_OSS_SEVEN_BUY_TOC_UPDATE_LIST_FIELD.number = 2
M_OSS_SEVEN_BUY_TOC_UPDATE_LIST_FIELD.index = 1
M_OSS_SEVEN_BUY_TOC_UPDATE_LIST_FIELD.label = 3
M_OSS_SEVEN_BUY_TOC_UPDATE_LIST_FIELD.has_default_value = false
M_OSS_SEVEN_BUY_TOC_UPDATE_LIST_FIELD.default_value = {}
M_OSS_SEVEN_BUY_TOC_UPDATE_LIST_FIELD.message_type = p_kv_pb.P_KV
M_OSS_SEVEN_BUY_TOC_UPDATE_LIST_FIELD.type = 11
M_OSS_SEVEN_BUY_TOC_UPDATE_LIST_FIELD.cpp_type = 10

M_OSS_SEVEN_BUY_TOC.name = "m_oss_seven_buy_toc"
M_OSS_SEVEN_BUY_TOC.full_name = ".m_oss_seven_buy_toc"
M_OSS_SEVEN_BUY_TOC.nested_types = {}
M_OSS_SEVEN_BUY_TOC.enum_types = {}
M_OSS_SEVEN_BUY_TOC.fields = {M_OSS_SEVEN_BUY_TOC_ERR_CODE_FIELD, M_OSS_SEVEN_BUY_TOC_UPDATE_LIST_FIELD}
M_OSS_SEVEN_BUY_TOC.is_extendable = false
M_OSS_SEVEN_BUY_TOC.extensions = {}

m_oss_seven_buy_toc = protobuf.Message(M_OSS_SEVEN_BUY_TOC)
