--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.p_limitedtime_buy_pb')

P_LIMITEDTIME_BUY = protobuf.Descriptor();
P_LIMITEDTIME_BUY_REWARD_FIELD = protobuf.FieldDescriptor();
P_LIMITEDTIME_BUY_TYPE_FIELD = protobuf.FieldDescriptor();
P_LIMITEDTIME_BUY_NAME_FIELD = protobuf.FieldDescriptor();
P_LIMITEDTIME_BUY_TIME_FIELD = protobuf.FieldDescriptor();

P_LIMITEDTIME_BUY_REWARD_FIELD.name = "reward"
P_LIMITEDTIME_BUY_REWARD_FIELD.full_name = ".p_limitedtime_buy.reward"
P_LIMITEDTIME_BUY_REWARD_FIELD.number = 1
P_LIMITEDTIME_BUY_REWARD_FIELD.index = 0
P_LIMITEDTIME_BUY_REWARD_FIELD.label = 1
P_LIMITEDTIME_BUY_REWARD_FIELD.has_default_value = true
P_LIMITEDTIME_BUY_REWARD_FIELD.default_value = 0
P_LIMITEDTIME_BUY_REWARD_FIELD.type = 5
P_LIMITEDTIME_BUY_REWARD_FIELD.cpp_type = 1

P_LIMITEDTIME_BUY_TYPE_FIELD.name = "type"
P_LIMITEDTIME_BUY_TYPE_FIELD.full_name = ".p_limitedtime_buy.type"
P_LIMITEDTIME_BUY_TYPE_FIELD.number = 2
P_LIMITEDTIME_BUY_TYPE_FIELD.index = 1
P_LIMITEDTIME_BUY_TYPE_FIELD.label = 1
P_LIMITEDTIME_BUY_TYPE_FIELD.has_default_value = true
P_LIMITEDTIME_BUY_TYPE_FIELD.default_value = 0
P_LIMITEDTIME_BUY_TYPE_FIELD.type = 5
P_LIMITEDTIME_BUY_TYPE_FIELD.cpp_type = 1

P_LIMITEDTIME_BUY_NAME_FIELD.name = "name"
P_LIMITEDTIME_BUY_NAME_FIELD.full_name = ".p_limitedtime_buy.name"
P_LIMITEDTIME_BUY_NAME_FIELD.number = 3
P_LIMITEDTIME_BUY_NAME_FIELD.index = 2
P_LIMITEDTIME_BUY_NAME_FIELD.label = 1
P_LIMITEDTIME_BUY_NAME_FIELD.has_default_value = false
P_LIMITEDTIME_BUY_NAME_FIELD.default_value = ""
P_LIMITEDTIME_BUY_NAME_FIELD.type = 9
P_LIMITEDTIME_BUY_NAME_FIELD.cpp_type = 9

P_LIMITEDTIME_BUY_TIME_FIELD.name = "time"
P_LIMITEDTIME_BUY_TIME_FIELD.full_name = ".p_limitedtime_buy.time"
P_LIMITEDTIME_BUY_TIME_FIELD.number = 4
P_LIMITEDTIME_BUY_TIME_FIELD.index = 3
P_LIMITEDTIME_BUY_TIME_FIELD.label = 1
P_LIMITEDTIME_BUY_TIME_FIELD.has_default_value = true
P_LIMITEDTIME_BUY_TIME_FIELD.default_value = 0
P_LIMITEDTIME_BUY_TIME_FIELD.type = 5
P_LIMITEDTIME_BUY_TIME_FIELD.cpp_type = 1

P_LIMITEDTIME_BUY.name = "p_limitedtime_buy"
P_LIMITEDTIME_BUY.full_name = ".p_limitedtime_buy"
P_LIMITEDTIME_BUY.nested_types = {}
P_LIMITEDTIME_BUY.enum_types = {}
P_LIMITEDTIME_BUY.fields = {P_LIMITEDTIME_BUY_REWARD_FIELD, P_LIMITEDTIME_BUY_TYPE_FIELD, P_LIMITEDTIME_BUY_NAME_FIELD, P_LIMITEDTIME_BUY_TIME_FIELD}
P_LIMITEDTIME_BUY.is_extendable = false
P_LIMITEDTIME_BUY.extensions = {}

p_limitedtime_buy = protobuf.Message(P_LIMITEDTIME_BUY)

