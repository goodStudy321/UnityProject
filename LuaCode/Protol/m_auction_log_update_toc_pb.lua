--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_auction_log_pb = require("Protol.p_auction_log_pb")
module('Protol.m_auction_log_update_toc_pb')

M_AUCTION_LOG_UPDATE_TOC = protobuf.Descriptor();
M_AUCTION_LOG_UPDATE_TOC_TYPE_FIELD = protobuf.FieldDescriptor();
M_AUCTION_LOG_UPDATE_TOC_LOG_FIELD = protobuf.FieldDescriptor();

M_AUCTION_LOG_UPDATE_TOC_TYPE_FIELD.name = "type"
M_AUCTION_LOG_UPDATE_TOC_TYPE_FIELD.full_name = ".m_auction_log_update_toc.type"
M_AUCTION_LOG_UPDATE_TOC_TYPE_FIELD.number = 1
M_AUCTION_LOG_UPDATE_TOC_TYPE_FIELD.index = 0
M_AUCTION_LOG_UPDATE_TOC_TYPE_FIELD.label = 1
M_AUCTION_LOG_UPDATE_TOC_TYPE_FIELD.has_default_value = true
M_AUCTION_LOG_UPDATE_TOC_TYPE_FIELD.default_value = 0
M_AUCTION_LOG_UPDATE_TOC_TYPE_FIELD.type = 5
M_AUCTION_LOG_UPDATE_TOC_TYPE_FIELD.cpp_type = 1

M_AUCTION_LOG_UPDATE_TOC_LOG_FIELD.name = "log"
M_AUCTION_LOG_UPDATE_TOC_LOG_FIELD.full_name = ".m_auction_log_update_toc.log"
M_AUCTION_LOG_UPDATE_TOC_LOG_FIELD.number = 2
M_AUCTION_LOG_UPDATE_TOC_LOG_FIELD.index = 1
M_AUCTION_LOG_UPDATE_TOC_LOG_FIELD.label = 1
M_AUCTION_LOG_UPDATE_TOC_LOG_FIELD.has_default_value = false
M_AUCTION_LOG_UPDATE_TOC_LOG_FIELD.default_value = nil
M_AUCTION_LOG_UPDATE_TOC_LOG_FIELD.message_type = p_auction_log_pb.P_AUCTION_LOG
M_AUCTION_LOG_UPDATE_TOC_LOG_FIELD.type = 11
M_AUCTION_LOG_UPDATE_TOC_LOG_FIELD.cpp_type = 10

M_AUCTION_LOG_UPDATE_TOC.name = "m_auction_log_update_toc"
M_AUCTION_LOG_UPDATE_TOC.full_name = ".m_auction_log_update_toc"
M_AUCTION_LOG_UPDATE_TOC.nested_types = {}
M_AUCTION_LOG_UPDATE_TOC.enum_types = {}
M_AUCTION_LOG_UPDATE_TOC.fields = {M_AUCTION_LOG_UPDATE_TOC_TYPE_FIELD, M_AUCTION_LOG_UPDATE_TOC_LOG_FIELD}
M_AUCTION_LOG_UPDATE_TOC.is_extendable = false
M_AUCTION_LOG_UPDATE_TOC.extensions = {}

m_auction_log_update_toc = protobuf.Message(M_AUCTION_LOG_UPDATE_TOC)

