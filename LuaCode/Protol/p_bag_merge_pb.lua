--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.p_bag_merge_pb')

P_BAG_MERGE = protobuf.Descriptor();
P_BAG_MERGE_ID_LIST_FIELD = protobuf.FieldDescriptor();

P_BAG_MERGE_ID_LIST_FIELD.name = "id_list"
P_BAG_MERGE_ID_LIST_FIELD.full_name = ".p_bag_merge.id_list"
P_BAG_MERGE_ID_LIST_FIELD.number = 1
P_BAG_MERGE_ID_LIST_FIELD.index = 0
P_BAG_MERGE_ID_LIST_FIELD.label = 3
P_BAG_MERGE_ID_LIST_FIELD.has_default_value = false
P_BAG_MERGE_ID_LIST_FIELD.default_value = {}
P_BAG_MERGE_ID_LIST_FIELD.type = 5
P_BAG_MERGE_ID_LIST_FIELD.cpp_type = 1

P_BAG_MERGE.name = "p_bag_merge"
P_BAG_MERGE.full_name = ".p_bag_merge"
P_BAG_MERGE.nested_types = {}
P_BAG_MERGE.enum_types = {}
P_BAG_MERGE.fields = {P_BAG_MERGE_ID_LIST_FIELD}
P_BAG_MERGE.is_extendable = false
P_BAG_MERGE.extensions = {}

p_bag_merge = protobuf.Message(P_BAG_MERGE)
