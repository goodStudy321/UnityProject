--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.p_equip_collect_pb')

P_EQUIP_COLLECT = protobuf.Descriptor();
P_EQUIP_COLLECT_ID_FIELD = protobuf.FieldDescriptor();
P_EQUIP_COLLECT_SUIT_NUM_FIELD = protobuf.FieldDescriptor();
P_EQUIP_COLLECT_IS_ACTIVE_FIELD = protobuf.FieldDescriptor();
P_EQUIP_COLLECT_IDS_FIELD = protobuf.FieldDescriptor();

P_EQUIP_COLLECT_ID_FIELD.name = "id"
P_EQUIP_COLLECT_ID_FIELD.full_name = ".p_equip_collect.id"
P_EQUIP_COLLECT_ID_FIELD.number = 1
P_EQUIP_COLLECT_ID_FIELD.index = 0
P_EQUIP_COLLECT_ID_FIELD.label = 1
P_EQUIP_COLLECT_ID_FIELD.has_default_value = true
P_EQUIP_COLLECT_ID_FIELD.default_value = 0
P_EQUIP_COLLECT_ID_FIELD.type = 5
P_EQUIP_COLLECT_ID_FIELD.cpp_type = 1

P_EQUIP_COLLECT_SUIT_NUM_FIELD.name = "suit_num"
P_EQUIP_COLLECT_SUIT_NUM_FIELD.full_name = ".p_equip_collect.suit_num"
P_EQUIP_COLLECT_SUIT_NUM_FIELD.number = 2
P_EQUIP_COLLECT_SUIT_NUM_FIELD.index = 1
P_EQUIP_COLLECT_SUIT_NUM_FIELD.label = 1
P_EQUIP_COLLECT_SUIT_NUM_FIELD.has_default_value = true
P_EQUIP_COLLECT_SUIT_NUM_FIELD.default_value = 0
P_EQUIP_COLLECT_SUIT_NUM_FIELD.type = 5
P_EQUIP_COLLECT_SUIT_NUM_FIELD.cpp_type = 1

P_EQUIP_COLLECT_IS_ACTIVE_FIELD.name = "is_active"
P_EQUIP_COLLECT_IS_ACTIVE_FIELD.full_name = ".p_equip_collect.is_active"
P_EQUIP_COLLECT_IS_ACTIVE_FIELD.number = 3
P_EQUIP_COLLECT_IS_ACTIVE_FIELD.index = 2
P_EQUIP_COLLECT_IS_ACTIVE_FIELD.label = 1
P_EQUIP_COLLECT_IS_ACTIVE_FIELD.has_default_value = true
P_EQUIP_COLLECT_IS_ACTIVE_FIELD.default_value = true
P_EQUIP_COLLECT_IS_ACTIVE_FIELD.type = 8
P_EQUIP_COLLECT_IS_ACTIVE_FIELD.cpp_type = 7

P_EQUIP_COLLECT_IDS_FIELD.name = "ids"
P_EQUIP_COLLECT_IDS_FIELD.full_name = ".p_equip_collect.ids"
P_EQUIP_COLLECT_IDS_FIELD.number = 4
P_EQUIP_COLLECT_IDS_FIELD.index = 3
P_EQUIP_COLLECT_IDS_FIELD.label = 3
P_EQUIP_COLLECT_IDS_FIELD.has_default_value = false
P_EQUIP_COLLECT_IDS_FIELD.default_value = {}
P_EQUIP_COLLECT_IDS_FIELD.type = 5
P_EQUIP_COLLECT_IDS_FIELD.cpp_type = 1

P_EQUIP_COLLECT.name = "p_equip_collect"
P_EQUIP_COLLECT.full_name = ".p_equip_collect"
P_EQUIP_COLLECT.nested_types = {}
P_EQUIP_COLLECT.enum_types = {}
P_EQUIP_COLLECT.fields = {P_EQUIP_COLLECT_ID_FIELD, P_EQUIP_COLLECT_SUIT_NUM_FIELD, P_EQUIP_COLLECT_IS_ACTIVE_FIELD, P_EQUIP_COLLECT_IDS_FIELD}
P_EQUIP_COLLECT.is_extendable = false
P_EQUIP_COLLECT.extensions = {}

p_equip_collect = protobuf.Message(P_EQUIP_COLLECT)

