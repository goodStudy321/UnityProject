--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.p_kvl_pb')

P_KVL = protobuf.Descriptor();
P_KVL_ID_FIELD = protobuf.FieldDescriptor();
P_KVL_LIST_FIELD = protobuf.FieldDescriptor();

P_KVL_ID_FIELD.name = "id"
P_KVL_ID_FIELD.full_name = ".p_kvl.id"
P_KVL_ID_FIELD.number = 1
P_KVL_ID_FIELD.index = 0
P_KVL_ID_FIELD.label = 1
P_KVL_ID_FIELD.has_default_value = true
P_KVL_ID_FIELD.default_value = 0
P_KVL_ID_FIELD.type = 5
P_KVL_ID_FIELD.cpp_type = 1

P_KVL_LIST_FIELD.name = "list"
P_KVL_LIST_FIELD.full_name = ".p_kvl.list"
P_KVL_LIST_FIELD.number = 2
P_KVL_LIST_FIELD.index = 1
P_KVL_LIST_FIELD.label = 3
P_KVL_LIST_FIELD.has_default_value = false
P_KVL_LIST_FIELD.default_value = {}
P_KVL_LIST_FIELD.type = 5
P_KVL_LIST_FIELD.cpp_type = 1

P_KVL.name = "p_kvl"
P_KVL.full_name = ".p_kvl"
P_KVL.nested_types = {}
P_KVL.enum_types = {}
P_KVL.fields = {P_KVL_ID_FIELD, P_KVL_LIST_FIELD}
P_KVL.is_extendable = false
P_KVL.extensions = {}

p_kvl = protobuf.Message(P_KVL)
