--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_friend_pb = require("Protol.p_friend_pb")
module('Protol.m_friend_request_info_toc_pb')

M_FRIEND_REQUEST_INFO_TOC = protobuf.Descriptor();
M_FRIEND_REQUEST_INFO_TOC_REQUEST_INFO_FIELD = protobuf.FieldDescriptor();

M_FRIEND_REQUEST_INFO_TOC_REQUEST_INFO_FIELD.name = "request_info"
M_FRIEND_REQUEST_INFO_TOC_REQUEST_INFO_FIELD.full_name = ".m_friend_request_info_toc.request_info"
M_FRIEND_REQUEST_INFO_TOC_REQUEST_INFO_FIELD.number = 1
M_FRIEND_REQUEST_INFO_TOC_REQUEST_INFO_FIELD.index = 0
M_FRIEND_REQUEST_INFO_TOC_REQUEST_INFO_FIELD.label = 1
M_FRIEND_REQUEST_INFO_TOC_REQUEST_INFO_FIELD.has_default_value = false
M_FRIEND_REQUEST_INFO_TOC_REQUEST_INFO_FIELD.default_value = nil
M_FRIEND_REQUEST_INFO_TOC_REQUEST_INFO_FIELD.message_type = p_friend_pb.P_FRIEND
M_FRIEND_REQUEST_INFO_TOC_REQUEST_INFO_FIELD.type = 11
M_FRIEND_REQUEST_INFO_TOC_REQUEST_INFO_FIELD.cpp_type = 10

M_FRIEND_REQUEST_INFO_TOC.name = "m_friend_request_info_toc"
M_FRIEND_REQUEST_INFO_TOC.full_name = ".m_friend_request_info_toc"
M_FRIEND_REQUEST_INFO_TOC.nested_types = {}
M_FRIEND_REQUEST_INFO_TOC.enum_types = {}
M_FRIEND_REQUEST_INFO_TOC.fields = {M_FRIEND_REQUEST_INFO_TOC_REQUEST_INFO_FIELD}
M_FRIEND_REQUEST_INFO_TOC.is_extendable = false
M_FRIEND_REQUEST_INFO_TOC.extensions = {}

m_friend_request_info_toc = protobuf.Message(M_FRIEND_REQUEST_INFO_TOC)

