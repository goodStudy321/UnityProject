--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_dks_pb = require("Protol.p_dks_pb")
module('Protol.m_marry_feast_info_toc_pb')

M_MARRY_FEAST_INFO_TOC = protobuf.Descriptor();
M_MARRY_FEAST_INFO_TOC_FEAST_START_TIME_FIELD = protobuf.FieldDescriptor();
M_MARRY_FEAST_INFO_TOC_FEAST_TIMES_FIELD = protobuf.FieldDescriptor();
M_MARRY_FEAST_INFO_TOC_EXTRA_GUEST_NUM_FIELD = protobuf.FieldDescriptor();
M_MARRY_FEAST_INFO_TOC_IS_BUY_JOIN_FIELD = protobuf.FieldDescriptor();
M_MARRY_FEAST_INFO_TOC_GUEST_LIST_FIELD = protobuf.FieldDescriptor();
M_MARRY_FEAST_INFO_TOC_APPLY_GUEST_LIST_FIELD = protobuf.FieldDescriptor();

M_MARRY_FEAST_INFO_TOC_FEAST_START_TIME_FIELD.name = "feast_start_time"
M_MARRY_FEAST_INFO_TOC_FEAST_START_TIME_FIELD.full_name = ".m_marry_feast_info_toc.feast_start_time"
M_MARRY_FEAST_INFO_TOC_FEAST_START_TIME_FIELD.number = 1
M_MARRY_FEAST_INFO_TOC_FEAST_START_TIME_FIELD.index = 0
M_MARRY_FEAST_INFO_TOC_FEAST_START_TIME_FIELD.label = 1
M_MARRY_FEAST_INFO_TOC_FEAST_START_TIME_FIELD.has_default_value = true
M_MARRY_FEAST_INFO_TOC_FEAST_START_TIME_FIELD.default_value = 0
M_MARRY_FEAST_INFO_TOC_FEAST_START_TIME_FIELD.type = 5
M_MARRY_FEAST_INFO_TOC_FEAST_START_TIME_FIELD.cpp_type = 1

M_MARRY_FEAST_INFO_TOC_FEAST_TIMES_FIELD.name = "feast_times"
M_MARRY_FEAST_INFO_TOC_FEAST_TIMES_FIELD.full_name = ".m_marry_feast_info_toc.feast_times"
M_MARRY_FEAST_INFO_TOC_FEAST_TIMES_FIELD.number = 2
M_MARRY_FEAST_INFO_TOC_FEAST_TIMES_FIELD.index = 1
M_MARRY_FEAST_INFO_TOC_FEAST_TIMES_FIELD.label = 1
M_MARRY_FEAST_INFO_TOC_FEAST_TIMES_FIELD.has_default_value = true
M_MARRY_FEAST_INFO_TOC_FEAST_TIMES_FIELD.default_value = 0
M_MARRY_FEAST_INFO_TOC_FEAST_TIMES_FIELD.type = 5
M_MARRY_FEAST_INFO_TOC_FEAST_TIMES_FIELD.cpp_type = 1

M_MARRY_FEAST_INFO_TOC_EXTRA_GUEST_NUM_FIELD.name = "extra_guest_num"
M_MARRY_FEAST_INFO_TOC_EXTRA_GUEST_NUM_FIELD.full_name = ".m_marry_feast_info_toc.extra_guest_num"
M_MARRY_FEAST_INFO_TOC_EXTRA_GUEST_NUM_FIELD.number = 3
M_MARRY_FEAST_INFO_TOC_EXTRA_GUEST_NUM_FIELD.index = 2
M_MARRY_FEAST_INFO_TOC_EXTRA_GUEST_NUM_FIELD.label = 1
M_MARRY_FEAST_INFO_TOC_EXTRA_GUEST_NUM_FIELD.has_default_value = true
M_MARRY_FEAST_INFO_TOC_EXTRA_GUEST_NUM_FIELD.default_value = 0
M_MARRY_FEAST_INFO_TOC_EXTRA_GUEST_NUM_FIELD.type = 5
M_MARRY_FEAST_INFO_TOC_EXTRA_GUEST_NUM_FIELD.cpp_type = 1

M_MARRY_FEAST_INFO_TOC_IS_BUY_JOIN_FIELD.name = "is_buy_join"
M_MARRY_FEAST_INFO_TOC_IS_BUY_JOIN_FIELD.full_name = ".m_marry_feast_info_toc.is_buy_join"
M_MARRY_FEAST_INFO_TOC_IS_BUY_JOIN_FIELD.number = 4
M_MARRY_FEAST_INFO_TOC_IS_BUY_JOIN_FIELD.index = 3
M_MARRY_FEAST_INFO_TOC_IS_BUY_JOIN_FIELD.label = 1
M_MARRY_FEAST_INFO_TOC_IS_BUY_JOIN_FIELD.has_default_value = true
M_MARRY_FEAST_INFO_TOC_IS_BUY_JOIN_FIELD.default_value = true
M_MARRY_FEAST_INFO_TOC_IS_BUY_JOIN_FIELD.type = 8
M_MARRY_FEAST_INFO_TOC_IS_BUY_JOIN_FIELD.cpp_type = 7

M_MARRY_FEAST_INFO_TOC_GUEST_LIST_FIELD.name = "guest_list"
M_MARRY_FEAST_INFO_TOC_GUEST_LIST_FIELD.full_name = ".m_marry_feast_info_toc.guest_list"
M_MARRY_FEAST_INFO_TOC_GUEST_LIST_FIELD.number = 5
M_MARRY_FEAST_INFO_TOC_GUEST_LIST_FIELD.index = 4
M_MARRY_FEAST_INFO_TOC_GUEST_LIST_FIELD.label = 3
M_MARRY_FEAST_INFO_TOC_GUEST_LIST_FIELD.has_default_value = false
M_MARRY_FEAST_INFO_TOC_GUEST_LIST_FIELD.default_value = {}
M_MARRY_FEAST_INFO_TOC_GUEST_LIST_FIELD.message_type = p_dks_pb.P_DKS
M_MARRY_FEAST_INFO_TOC_GUEST_LIST_FIELD.type = 11
M_MARRY_FEAST_INFO_TOC_GUEST_LIST_FIELD.cpp_type = 10

M_MARRY_FEAST_INFO_TOC_APPLY_GUEST_LIST_FIELD.name = "apply_guest_list"
M_MARRY_FEAST_INFO_TOC_APPLY_GUEST_LIST_FIELD.full_name = ".m_marry_feast_info_toc.apply_guest_list"
M_MARRY_FEAST_INFO_TOC_APPLY_GUEST_LIST_FIELD.number = 6
M_MARRY_FEAST_INFO_TOC_APPLY_GUEST_LIST_FIELD.index = 5
M_MARRY_FEAST_INFO_TOC_APPLY_GUEST_LIST_FIELD.label = 3
M_MARRY_FEAST_INFO_TOC_APPLY_GUEST_LIST_FIELD.has_default_value = false
M_MARRY_FEAST_INFO_TOC_APPLY_GUEST_LIST_FIELD.default_value = {}
M_MARRY_FEAST_INFO_TOC_APPLY_GUEST_LIST_FIELD.message_type = p_dks_pb.P_DKS
M_MARRY_FEAST_INFO_TOC_APPLY_GUEST_LIST_FIELD.type = 11
M_MARRY_FEAST_INFO_TOC_APPLY_GUEST_LIST_FIELD.cpp_type = 10

M_MARRY_FEAST_INFO_TOC.name = "m_marry_feast_info_toc"
M_MARRY_FEAST_INFO_TOC.full_name = ".m_marry_feast_info_toc"
M_MARRY_FEAST_INFO_TOC.nested_types = {}
M_MARRY_FEAST_INFO_TOC.enum_types = {}
M_MARRY_FEAST_INFO_TOC.fields = {M_MARRY_FEAST_INFO_TOC_FEAST_START_TIME_FIELD, M_MARRY_FEAST_INFO_TOC_FEAST_TIMES_FIELD, M_MARRY_FEAST_INFO_TOC_EXTRA_GUEST_NUM_FIELD, M_MARRY_FEAST_INFO_TOC_IS_BUY_JOIN_FIELD, M_MARRY_FEAST_INFO_TOC_GUEST_LIST_FIELD, M_MARRY_FEAST_INFO_TOC_APPLY_GUEST_LIST_FIELD}
M_MARRY_FEAST_INFO_TOC.is_extendable = false
M_MARRY_FEAST_INFO_TOC.extensions = {}

m_marry_feast_info_toc = protobuf.Message(M_MARRY_FEAST_INFO_TOC)

