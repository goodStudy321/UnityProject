--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.p_escort_log_pb')

P_ESCORT_LOG = protobuf.Descriptor();
P_ESCORT_LOG_TYPE_FIELD = protobuf.FieldDescriptor();
P_ESCORT_LOG_TEXT_FIELD = protobuf.FieldDescriptor();

P_ESCORT_LOG_TYPE_FIELD.name = "type"
P_ESCORT_LOG_TYPE_FIELD.full_name = ".p_escort_log.type"
P_ESCORT_LOG_TYPE_FIELD.number = 1
P_ESCORT_LOG_TYPE_FIELD.index = 0
P_ESCORT_LOG_TYPE_FIELD.label = 1
P_ESCORT_LOG_TYPE_FIELD.has_default_value = true
P_ESCORT_LOG_TYPE_FIELD.default_value = 0
P_ESCORT_LOG_TYPE_FIELD.type = 5
P_ESCORT_LOG_TYPE_FIELD.cpp_type = 1

P_ESCORT_LOG_TEXT_FIELD.name = "text"
P_ESCORT_LOG_TEXT_FIELD.full_name = ".p_escort_log.text"
P_ESCORT_LOG_TEXT_FIELD.number = 2
P_ESCORT_LOG_TEXT_FIELD.index = 1
P_ESCORT_LOG_TEXT_FIELD.label = 3
P_ESCORT_LOG_TEXT_FIELD.has_default_value = false
P_ESCORT_LOG_TEXT_FIELD.default_value = {}
P_ESCORT_LOG_TEXT_FIELD.type = 9
P_ESCORT_LOG_TEXT_FIELD.cpp_type = 9

P_ESCORT_LOG.name = "p_escort_log"
P_ESCORT_LOG.full_name = ".p_escort_log"
P_ESCORT_LOG.nested_types = {}
P_ESCORT_LOG.enum_types = {}
P_ESCORT_LOG.fields = {P_ESCORT_LOG_TYPE_FIELD, P_ESCORT_LOG_TEXT_FIELD}
P_ESCORT_LOG.is_extendable = false
P_ESCORT_LOG.extensions = {}

p_escort_log = protobuf.Message(P_ESCORT_LOG)
