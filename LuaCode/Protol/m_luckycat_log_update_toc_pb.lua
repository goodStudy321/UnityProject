--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_luckycat_log_pb = require("Protol.p_luckycat_log_pb")
module('Protol.m_luckycat_log_update_toc_pb')

M_LUCKYCAT_LOG_UPDATE_TOC = protobuf.Descriptor();
M_LUCKYCAT_LOG_UPDATE_TOC_LOGS_FIELD = protobuf.FieldDescriptor();

M_LUCKYCAT_LOG_UPDATE_TOC_LOGS_FIELD.name = "logs"
M_LUCKYCAT_LOG_UPDATE_TOC_LOGS_FIELD.full_name = ".m_luckycat_log_update_toc.logs"
M_LUCKYCAT_LOG_UPDATE_TOC_LOGS_FIELD.number = 1
M_LUCKYCAT_LOG_UPDATE_TOC_LOGS_FIELD.index = 0
M_LUCKYCAT_LOG_UPDATE_TOC_LOGS_FIELD.label = 3
M_LUCKYCAT_LOG_UPDATE_TOC_LOGS_FIELD.has_default_value = false
M_LUCKYCAT_LOG_UPDATE_TOC_LOGS_FIELD.default_value = {}
M_LUCKYCAT_LOG_UPDATE_TOC_LOGS_FIELD.message_type = p_luckycat_log_pb.P_LUCKYCAT_LOG
M_LUCKYCAT_LOG_UPDATE_TOC_LOGS_FIELD.type = 11
M_LUCKYCAT_LOG_UPDATE_TOC_LOGS_FIELD.cpp_type = 10

M_LUCKYCAT_LOG_UPDATE_TOC.name = "m_luckycat_log_update_toc"
M_LUCKYCAT_LOG_UPDATE_TOC.full_name = ".m_luckycat_log_update_toc"
M_LUCKYCAT_LOG_UPDATE_TOC.nested_types = {}
M_LUCKYCAT_LOG_UPDATE_TOC.enum_types = {}
M_LUCKYCAT_LOG_UPDATE_TOC.fields = {M_LUCKYCAT_LOG_UPDATE_TOC_LOGS_FIELD}
M_LUCKYCAT_LOG_UPDATE_TOC.is_extendable = false
M_LUCKYCAT_LOG_UPDATE_TOC.extensions = {}

m_luckycat_log_update_toc = protobuf.Message(M_LUCKYCAT_LOG_UPDATE_TOC)

