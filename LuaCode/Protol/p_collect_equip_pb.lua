--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.p_collect_equip_pb')

P_COLLECT_EQUIP = protobuf.Descriptor();
P_COLLECT_EQUIP_ID_FIELD = protobuf.FieldDescriptor();
P_COLLECT_EQUIP_TYPE_ID_FIELD = protobuf.FieldDescriptor();

P_COLLECT_EQUIP_ID_FIELD.name = "id"
P_COLLECT_EQUIP_ID_FIELD.full_name = ".p_collect_equip.id"
P_COLLECT_EQUIP_ID_FIELD.number = 1
P_COLLECT_EQUIP_ID_FIELD.index = 0
P_COLLECT_EQUIP_ID_FIELD.label = 1
P_COLLECT_EQUIP_ID_FIELD.has_default_value = true
P_COLLECT_EQUIP_ID_FIELD.default_value = 0
P_COLLECT_EQUIP_ID_FIELD.type = 3
P_COLLECT_EQUIP_ID_FIELD.cpp_type = 2

P_COLLECT_EQUIP_TYPE_ID_FIELD.name = "type_id"
P_COLLECT_EQUIP_TYPE_ID_FIELD.full_name = ".p_collect_equip.type_id"
P_COLLECT_EQUIP_TYPE_ID_FIELD.number = 2
P_COLLECT_EQUIP_TYPE_ID_FIELD.index = 1
P_COLLECT_EQUIP_TYPE_ID_FIELD.label = 1
P_COLLECT_EQUIP_TYPE_ID_FIELD.has_default_value = true
P_COLLECT_EQUIP_TYPE_ID_FIELD.default_value = 0
P_COLLECT_EQUIP_TYPE_ID_FIELD.type = 3
P_COLLECT_EQUIP_TYPE_ID_FIELD.cpp_type = 2

P_COLLECT_EQUIP.name = "p_collect_equip"
P_COLLECT_EQUIP.full_name = ".p_collect_equip"
P_COLLECT_EQUIP.nested_types = {}
P_COLLECT_EQUIP.enum_types = {}
P_COLLECT_EQUIP.fields = {P_COLLECT_EQUIP_ID_FIELD, P_COLLECT_EQUIP_TYPE_ID_FIELD}
P_COLLECT_EQUIP.is_extendable = false
P_COLLECT_EQUIP.extensions = {}

p_collect_equip = protobuf.Message(P_COLLECT_EQUIP)
