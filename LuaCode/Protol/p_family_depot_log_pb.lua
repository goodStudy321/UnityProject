--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_goods_pb = require("Protol.p_goods_pb")
module('Protol.p_family_depot_log_pb')

P_FAMILY_DEPOT_LOG = protobuf.Descriptor();
P_FAMILY_DEPOT_LOG_ROLE_NAME_FIELD = protobuf.FieldDescriptor();
P_FAMILY_DEPOT_LOG_TYPE_FIELD = protobuf.FieldDescriptor();
P_FAMILY_DEPOT_LOG_GOODS_FIELD = protobuf.FieldDescriptor();

P_FAMILY_DEPOT_LOG_ROLE_NAME_FIELD.name = "role_name"
P_FAMILY_DEPOT_LOG_ROLE_NAME_FIELD.full_name = ".p_family_depot_log.role_name"
P_FAMILY_DEPOT_LOG_ROLE_NAME_FIELD.number = 1
P_FAMILY_DEPOT_LOG_ROLE_NAME_FIELD.index = 0
P_FAMILY_DEPOT_LOG_ROLE_NAME_FIELD.label = 1
P_FAMILY_DEPOT_LOG_ROLE_NAME_FIELD.has_default_value = false
P_FAMILY_DEPOT_LOG_ROLE_NAME_FIELD.default_value = ""
P_FAMILY_DEPOT_LOG_ROLE_NAME_FIELD.type = 9
P_FAMILY_DEPOT_LOG_ROLE_NAME_FIELD.cpp_type = 9

P_FAMILY_DEPOT_LOG_TYPE_FIELD.name = "type"
P_FAMILY_DEPOT_LOG_TYPE_FIELD.full_name = ".p_family_depot_log.type"
P_FAMILY_DEPOT_LOG_TYPE_FIELD.number = 2
P_FAMILY_DEPOT_LOG_TYPE_FIELD.index = 1
P_FAMILY_DEPOT_LOG_TYPE_FIELD.label = 1
P_FAMILY_DEPOT_LOG_TYPE_FIELD.has_default_value = true
P_FAMILY_DEPOT_LOG_TYPE_FIELD.default_value = 0
P_FAMILY_DEPOT_LOG_TYPE_FIELD.type = 5
P_FAMILY_DEPOT_LOG_TYPE_FIELD.cpp_type = 1

P_FAMILY_DEPOT_LOG_GOODS_FIELD.name = "goods"
P_FAMILY_DEPOT_LOG_GOODS_FIELD.full_name = ".p_family_depot_log.goods"
P_FAMILY_DEPOT_LOG_GOODS_FIELD.number = 3
P_FAMILY_DEPOT_LOG_GOODS_FIELD.index = 2
P_FAMILY_DEPOT_LOG_GOODS_FIELD.label = 1
P_FAMILY_DEPOT_LOG_GOODS_FIELD.has_default_value = false
P_FAMILY_DEPOT_LOG_GOODS_FIELD.default_value = nil
P_FAMILY_DEPOT_LOG_GOODS_FIELD.message_type = p_goods_pb.P_GOODS
P_FAMILY_DEPOT_LOG_GOODS_FIELD.type = 11
P_FAMILY_DEPOT_LOG_GOODS_FIELD.cpp_type = 10

P_FAMILY_DEPOT_LOG.name = "p_family_depot_log"
P_FAMILY_DEPOT_LOG.full_name = ".p_family_depot_log"
P_FAMILY_DEPOT_LOG.nested_types = {}
P_FAMILY_DEPOT_LOG.enum_types = {}
P_FAMILY_DEPOT_LOG.fields = {P_FAMILY_DEPOT_LOG_ROLE_NAME_FIELD, P_FAMILY_DEPOT_LOG_TYPE_FIELD, P_FAMILY_DEPOT_LOG_GOODS_FIELD}
P_FAMILY_DEPOT_LOG.is_extendable = false
P_FAMILY_DEPOT_LOG.extensions = {}

p_family_depot_log = protobuf.Message(P_FAMILY_DEPOT_LOG)

