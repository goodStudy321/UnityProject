--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_marry_wish_pb = require("Protol.p_marry_wish_pb")
module('Protol.m_marry_map_wish_log_toc_pb')

M_MARRY_MAP_WISH_LOG_TOC = protobuf.Descriptor();
M_MARRY_MAP_WISH_LOG_TOC_WISH_LOG_FIELD = protobuf.FieldDescriptor();

M_MARRY_MAP_WISH_LOG_TOC_WISH_LOG_FIELD.name = "wish_log"
M_MARRY_MAP_WISH_LOG_TOC_WISH_LOG_FIELD.full_name = ".m_marry_map_wish_log_toc.wish_log"
M_MARRY_MAP_WISH_LOG_TOC_WISH_LOG_FIELD.number = 1
M_MARRY_MAP_WISH_LOG_TOC_WISH_LOG_FIELD.index = 0
M_MARRY_MAP_WISH_LOG_TOC_WISH_LOG_FIELD.label = 1
M_MARRY_MAP_WISH_LOG_TOC_WISH_LOG_FIELD.has_default_value = false
M_MARRY_MAP_WISH_LOG_TOC_WISH_LOG_FIELD.default_value = nil
M_MARRY_MAP_WISH_LOG_TOC_WISH_LOG_FIELD.message_type = p_marry_wish_pb.P_MARRY_WISH
M_MARRY_MAP_WISH_LOG_TOC_WISH_LOG_FIELD.type = 11
M_MARRY_MAP_WISH_LOG_TOC_WISH_LOG_FIELD.cpp_type = 10

M_MARRY_MAP_WISH_LOG_TOC.name = "m_marry_map_wish_log_toc"
M_MARRY_MAP_WISH_LOG_TOC.full_name = ".m_marry_map_wish_log_toc"
M_MARRY_MAP_WISH_LOG_TOC.nested_types = {}
M_MARRY_MAP_WISH_LOG_TOC.enum_types = {}
M_MARRY_MAP_WISH_LOG_TOC.fields = {M_MARRY_MAP_WISH_LOG_TOC_WISH_LOG_FIELD}
M_MARRY_MAP_WISH_LOG_TOC.is_extendable = false
M_MARRY_MAP_WISH_LOG_TOC.extensions = {}

m_marry_map_wish_log_toc = protobuf.Message(M_MARRY_MAP_WISH_LOG_TOC)
