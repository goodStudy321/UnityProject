--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.p_cycle_act_pb')

P_CYCLE_ACT = protobuf.Descriptor();
P_CYCLE_ACT_ID_FIELD = protobuf.FieldDescriptor();
P_CYCLE_ACT_VAL_FIELD = protobuf.FieldDescriptor();
P_CYCLE_ACT_CONFIG_NUM_FIELD = protobuf.FieldDescriptor();
P_CYCLE_ACT_START_TIME_FIELD = protobuf.FieldDescriptor();
P_CYCLE_ACT_END_TIME_FIELD = protobuf.FieldDescriptor();

P_CYCLE_ACT_ID_FIELD.name = "id"
P_CYCLE_ACT_ID_FIELD.full_name = ".p_cycle_act.id"
P_CYCLE_ACT_ID_FIELD.number = 1
P_CYCLE_ACT_ID_FIELD.index = 0
P_CYCLE_ACT_ID_FIELD.label = 1
P_CYCLE_ACT_ID_FIELD.has_default_value = true
P_CYCLE_ACT_ID_FIELD.default_value = 0
P_CYCLE_ACT_ID_FIELD.type = 5
P_CYCLE_ACT_ID_FIELD.cpp_type = 1

P_CYCLE_ACT_VAL_FIELD.name = "val"
P_CYCLE_ACT_VAL_FIELD.full_name = ".p_cycle_act.val"
P_CYCLE_ACT_VAL_FIELD.number = 2
P_CYCLE_ACT_VAL_FIELD.index = 1
P_CYCLE_ACT_VAL_FIELD.label = 1
P_CYCLE_ACT_VAL_FIELD.has_default_value = true
P_CYCLE_ACT_VAL_FIELD.default_value = 0
P_CYCLE_ACT_VAL_FIELD.type = 5
P_CYCLE_ACT_VAL_FIELD.cpp_type = 1

P_CYCLE_ACT_CONFIG_NUM_FIELD.name = "config_num"
P_CYCLE_ACT_CONFIG_NUM_FIELD.full_name = ".p_cycle_act.config_num"
P_CYCLE_ACT_CONFIG_NUM_FIELD.number = 3
P_CYCLE_ACT_CONFIG_NUM_FIELD.index = 2
P_CYCLE_ACT_CONFIG_NUM_FIELD.label = 1
P_CYCLE_ACT_CONFIG_NUM_FIELD.has_default_value = true
P_CYCLE_ACT_CONFIG_NUM_FIELD.default_value = 0
P_CYCLE_ACT_CONFIG_NUM_FIELD.type = 5
P_CYCLE_ACT_CONFIG_NUM_FIELD.cpp_type = 1

P_CYCLE_ACT_START_TIME_FIELD.name = "start_time"
P_CYCLE_ACT_START_TIME_FIELD.full_name = ".p_cycle_act.start_time"
P_CYCLE_ACT_START_TIME_FIELD.number = 4
P_CYCLE_ACT_START_TIME_FIELD.index = 3
P_CYCLE_ACT_START_TIME_FIELD.label = 1
P_CYCLE_ACT_START_TIME_FIELD.has_default_value = true
P_CYCLE_ACT_START_TIME_FIELD.default_value = 0
P_CYCLE_ACT_START_TIME_FIELD.type = 5
P_CYCLE_ACT_START_TIME_FIELD.cpp_type = 1

P_CYCLE_ACT_END_TIME_FIELD.name = "end_time"
P_CYCLE_ACT_END_TIME_FIELD.full_name = ".p_cycle_act.end_time"
P_CYCLE_ACT_END_TIME_FIELD.number = 5
P_CYCLE_ACT_END_TIME_FIELD.index = 4
P_CYCLE_ACT_END_TIME_FIELD.label = 1
P_CYCLE_ACT_END_TIME_FIELD.has_default_value = true
P_CYCLE_ACT_END_TIME_FIELD.default_value = 0
P_CYCLE_ACT_END_TIME_FIELD.type = 5
P_CYCLE_ACT_END_TIME_FIELD.cpp_type = 1

P_CYCLE_ACT.name = "p_cycle_act"
P_CYCLE_ACT.full_name = ".p_cycle_act"
P_CYCLE_ACT.nested_types = {}
P_CYCLE_ACT.enum_types = {}
P_CYCLE_ACT.fields = {P_CYCLE_ACT_ID_FIELD, P_CYCLE_ACT_VAL_FIELD, P_CYCLE_ACT_CONFIG_NUM_FIELD, P_CYCLE_ACT_START_TIME_FIELD, P_CYCLE_ACT_END_TIME_FIELD}
P_CYCLE_ACT.is_extendable = false
P_CYCLE_ACT.extensions = {}

p_cycle_act = protobuf.Message(P_CYCLE_ACT)

