--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_ks_pb = require("Protol.p_ks_pb")
module('Protol.m_summit_log_update_toc_pb')

M_SUMMIT_LOG_UPDATE_TOC = protobuf.Descriptor();
M_SUMMIT_LOG_UPDATE_TOC_WORLD_SUMMIT_LOGS_FIELD = protobuf.FieldDescriptor();

M_SUMMIT_LOG_UPDATE_TOC_WORLD_SUMMIT_LOGS_FIELD.name = "world_summit_logs"
M_SUMMIT_LOG_UPDATE_TOC_WORLD_SUMMIT_LOGS_FIELD.full_name = ".m_summit_log_update_toc.world_summit_logs"
M_SUMMIT_LOG_UPDATE_TOC_WORLD_SUMMIT_LOGS_FIELD.number = 1
M_SUMMIT_LOG_UPDATE_TOC_WORLD_SUMMIT_LOGS_FIELD.index = 0
M_SUMMIT_LOG_UPDATE_TOC_WORLD_SUMMIT_LOGS_FIELD.label = 3
M_SUMMIT_LOG_UPDATE_TOC_WORLD_SUMMIT_LOGS_FIELD.has_default_value = false
M_SUMMIT_LOG_UPDATE_TOC_WORLD_SUMMIT_LOGS_FIELD.default_value = {}
M_SUMMIT_LOG_UPDATE_TOC_WORLD_SUMMIT_LOGS_FIELD.message_type = p_ks_pb.P_KS
M_SUMMIT_LOG_UPDATE_TOC_WORLD_SUMMIT_LOGS_FIELD.type = 11
M_SUMMIT_LOG_UPDATE_TOC_WORLD_SUMMIT_LOGS_FIELD.cpp_type = 10

M_SUMMIT_LOG_UPDATE_TOC.name = "m_summit_log_update_toc"
M_SUMMIT_LOG_UPDATE_TOC.full_name = ".m_summit_log_update_toc"
M_SUMMIT_LOG_UPDATE_TOC.nested_types = {}
M_SUMMIT_LOG_UPDATE_TOC.enum_types = {}
M_SUMMIT_LOG_UPDATE_TOC.fields = {M_SUMMIT_LOG_UPDATE_TOC_WORLD_SUMMIT_LOGS_FIELD}
M_SUMMIT_LOG_UPDATE_TOC.is_extendable = false
M_SUMMIT_LOG_UPDATE_TOC.extensions = {}

m_summit_log_update_toc = protobuf.Message(M_SUMMIT_LOG_UPDATE_TOC)

