--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.p_act_rank_pb')

P_ACT_RANK = protobuf.Descriptor();
P_ACT_RANK_RANK_FIELD = protobuf.FieldDescriptor();
P_ACT_RANK_ROLE_ID_FIELD = protobuf.FieldDescriptor();
P_ACT_RANK_ROLE_NAME_FIELD = protobuf.FieldDescriptor();
P_ACT_RANK_RANK_VALUE_FIELD = protobuf.FieldDescriptor();

P_ACT_RANK_RANK_FIELD.name = "rank"
P_ACT_RANK_RANK_FIELD.full_name = ".p_act_rank.rank"
P_ACT_RANK_RANK_FIELD.number = 1
P_ACT_RANK_RANK_FIELD.index = 0
P_ACT_RANK_RANK_FIELD.label = 1
P_ACT_RANK_RANK_FIELD.has_default_value = true
P_ACT_RANK_RANK_FIELD.default_value = 0
P_ACT_RANK_RANK_FIELD.type = 5
P_ACT_RANK_RANK_FIELD.cpp_type = 1

P_ACT_RANK_ROLE_ID_FIELD.name = "role_id"
P_ACT_RANK_ROLE_ID_FIELD.full_name = ".p_act_rank.role_id"
P_ACT_RANK_ROLE_ID_FIELD.number = 2
P_ACT_RANK_ROLE_ID_FIELD.index = 1
P_ACT_RANK_ROLE_ID_FIELD.label = 1
P_ACT_RANK_ROLE_ID_FIELD.has_default_value = true
P_ACT_RANK_ROLE_ID_FIELD.default_value = 0
P_ACT_RANK_ROLE_ID_FIELD.type = 3
P_ACT_RANK_ROLE_ID_FIELD.cpp_type = 2

P_ACT_RANK_ROLE_NAME_FIELD.name = "role_name"
P_ACT_RANK_ROLE_NAME_FIELD.full_name = ".p_act_rank.role_name"
P_ACT_RANK_ROLE_NAME_FIELD.number = 3
P_ACT_RANK_ROLE_NAME_FIELD.index = 2
P_ACT_RANK_ROLE_NAME_FIELD.label = 1
P_ACT_RANK_ROLE_NAME_FIELD.has_default_value = false
P_ACT_RANK_ROLE_NAME_FIELD.default_value = ""
P_ACT_RANK_ROLE_NAME_FIELD.type = 9
P_ACT_RANK_ROLE_NAME_FIELD.cpp_type = 9

P_ACT_RANK_RANK_VALUE_FIELD.name = "rank_value"
P_ACT_RANK_RANK_VALUE_FIELD.full_name = ".p_act_rank.rank_value"
P_ACT_RANK_RANK_VALUE_FIELD.number = 4
P_ACT_RANK_RANK_VALUE_FIELD.index = 3
P_ACT_RANK_RANK_VALUE_FIELD.label = 1
P_ACT_RANK_RANK_VALUE_FIELD.has_default_value = true
P_ACT_RANK_RANK_VALUE_FIELD.default_value = 0
P_ACT_RANK_RANK_VALUE_FIELD.type = 5
P_ACT_RANK_RANK_VALUE_FIELD.cpp_type = 1

P_ACT_RANK.name = "p_act_rank"
P_ACT_RANK.full_name = ".p_act_rank"
P_ACT_RANK.nested_types = {}
P_ACT_RANK.enum_types = {}
P_ACT_RANK.fields = {P_ACT_RANK_RANK_FIELD, P_ACT_RANK_ROLE_ID_FIELD, P_ACT_RANK_ROLE_NAME_FIELD, P_ACT_RANK_RANK_VALUE_FIELD}
P_ACT_RANK.is_extendable = false
P_ACT_RANK.extensions = {}

p_act_rank = protobuf.Message(P_ACT_RANK)
