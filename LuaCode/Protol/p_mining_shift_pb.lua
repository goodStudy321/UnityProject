--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.p_mining_shift_pb')

P_MINING_SHIFT = protobuf.Descriptor();
P_MINING_SHIFT_X_FIELD = protobuf.FieldDescriptor();
P_MINING_SHIFT_Y_FIELD = protobuf.FieldDescriptor();
P_MINING_SHIFT_TYPE_ID_FIELD = protobuf.FieldDescriptor();
P_MINING_SHIFT_SURPLUS_NUM_FIELD = protobuf.FieldDescriptor();

P_MINING_SHIFT_X_FIELD.name = "x"
P_MINING_SHIFT_X_FIELD.full_name = ".p_mining_shift.x"
P_MINING_SHIFT_X_FIELD.number = 1
P_MINING_SHIFT_X_FIELD.index = 0
P_MINING_SHIFT_X_FIELD.label = 1
P_MINING_SHIFT_X_FIELD.has_default_value = true
P_MINING_SHIFT_X_FIELD.default_value = 0
P_MINING_SHIFT_X_FIELD.type = 5
P_MINING_SHIFT_X_FIELD.cpp_type = 1

P_MINING_SHIFT_Y_FIELD.name = "y"
P_MINING_SHIFT_Y_FIELD.full_name = ".p_mining_shift.y"
P_MINING_SHIFT_Y_FIELD.number = 2
P_MINING_SHIFT_Y_FIELD.index = 1
P_MINING_SHIFT_Y_FIELD.label = 1
P_MINING_SHIFT_Y_FIELD.has_default_value = true
P_MINING_SHIFT_Y_FIELD.default_value = 0
P_MINING_SHIFT_Y_FIELD.type = 5
P_MINING_SHIFT_Y_FIELD.cpp_type = 1

P_MINING_SHIFT_TYPE_ID_FIELD.name = "type_id"
P_MINING_SHIFT_TYPE_ID_FIELD.full_name = ".p_mining_shift.type_id"
P_MINING_SHIFT_TYPE_ID_FIELD.number = 3
P_MINING_SHIFT_TYPE_ID_FIELD.index = 2
P_MINING_SHIFT_TYPE_ID_FIELD.label = 1
P_MINING_SHIFT_TYPE_ID_FIELD.has_default_value = true
P_MINING_SHIFT_TYPE_ID_FIELD.default_value = 0
P_MINING_SHIFT_TYPE_ID_FIELD.type = 5
P_MINING_SHIFT_TYPE_ID_FIELD.cpp_type = 1

P_MINING_SHIFT_SURPLUS_NUM_FIELD.name = "surplus_num"
P_MINING_SHIFT_SURPLUS_NUM_FIELD.full_name = ".p_mining_shift.surplus_num"
P_MINING_SHIFT_SURPLUS_NUM_FIELD.number = 4
P_MINING_SHIFT_SURPLUS_NUM_FIELD.index = 3
P_MINING_SHIFT_SURPLUS_NUM_FIELD.label = 1
P_MINING_SHIFT_SURPLUS_NUM_FIELD.has_default_value = true
P_MINING_SHIFT_SURPLUS_NUM_FIELD.default_value = 0
P_MINING_SHIFT_SURPLUS_NUM_FIELD.type = 5
P_MINING_SHIFT_SURPLUS_NUM_FIELD.cpp_type = 1

P_MINING_SHIFT.name = "p_mining_shift"
P_MINING_SHIFT.full_name = ".p_mining_shift"
P_MINING_SHIFT.nested_types = {}
P_MINING_SHIFT.enum_types = {}
P_MINING_SHIFT.fields = {P_MINING_SHIFT_X_FIELD, P_MINING_SHIFT_Y_FIELD, P_MINING_SHIFT_TYPE_ID_FIELD, P_MINING_SHIFT_SURPLUS_NUM_FIELD}
P_MINING_SHIFT.is_extendable = false
P_MINING_SHIFT.extensions = {}

p_mining_shift = protobuf.Message(P_MINING_SHIFT)

