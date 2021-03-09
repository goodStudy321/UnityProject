--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.p_world_boss_pb')

P_WORLD_BOSS = protobuf.Descriptor();
P_WORLD_BOSS_MAP_ID_FIELD = protobuf.FieldDescriptor();
P_WORLD_BOSS_TYPE_ID_FIELD = protobuf.FieldDescriptor();
P_WORLD_BOSS_IS_ALIVE_FIELD = protobuf.FieldDescriptor();
P_WORLD_BOSS_NEXT_REFRESH_TIME_FIELD = protobuf.FieldDescriptor();
P_WORLD_BOSS_REMAIN_NUM_FIELD = protobuf.FieldDescriptor();
P_WORLD_BOSS_ROLE_NUM_FIELD = protobuf.FieldDescriptor();
P_WORLD_BOSS_CAN_ENTER_FIELD = protobuf.FieldDescriptor();

P_WORLD_BOSS_MAP_ID_FIELD.name = "map_id"
P_WORLD_BOSS_MAP_ID_FIELD.full_name = ".p_world_boss.map_id"
P_WORLD_BOSS_MAP_ID_FIELD.number = 1
P_WORLD_BOSS_MAP_ID_FIELD.index = 0
P_WORLD_BOSS_MAP_ID_FIELD.label = 1
P_WORLD_BOSS_MAP_ID_FIELD.has_default_value = true
P_WORLD_BOSS_MAP_ID_FIELD.default_value = 0
P_WORLD_BOSS_MAP_ID_FIELD.type = 5
P_WORLD_BOSS_MAP_ID_FIELD.cpp_type = 1

P_WORLD_BOSS_TYPE_ID_FIELD.name = "type_id"
P_WORLD_BOSS_TYPE_ID_FIELD.full_name = ".p_world_boss.type_id"
P_WORLD_BOSS_TYPE_ID_FIELD.number = 2
P_WORLD_BOSS_TYPE_ID_FIELD.index = 1
P_WORLD_BOSS_TYPE_ID_FIELD.label = 1
P_WORLD_BOSS_TYPE_ID_FIELD.has_default_value = true
P_WORLD_BOSS_TYPE_ID_FIELD.default_value = 0
P_WORLD_BOSS_TYPE_ID_FIELD.type = 5
P_WORLD_BOSS_TYPE_ID_FIELD.cpp_type = 1

P_WORLD_BOSS_IS_ALIVE_FIELD.name = "is_alive"
P_WORLD_BOSS_IS_ALIVE_FIELD.full_name = ".p_world_boss.is_alive"
P_WORLD_BOSS_IS_ALIVE_FIELD.number = 3
P_WORLD_BOSS_IS_ALIVE_FIELD.index = 2
P_WORLD_BOSS_IS_ALIVE_FIELD.label = 1
P_WORLD_BOSS_IS_ALIVE_FIELD.has_default_value = true
P_WORLD_BOSS_IS_ALIVE_FIELD.default_value = true
P_WORLD_BOSS_IS_ALIVE_FIELD.type = 8
P_WORLD_BOSS_IS_ALIVE_FIELD.cpp_type = 7

P_WORLD_BOSS_NEXT_REFRESH_TIME_FIELD.name = "next_refresh_time"
P_WORLD_BOSS_NEXT_REFRESH_TIME_FIELD.full_name = ".p_world_boss.next_refresh_time"
P_WORLD_BOSS_NEXT_REFRESH_TIME_FIELD.number = 4
P_WORLD_BOSS_NEXT_REFRESH_TIME_FIELD.index = 3
P_WORLD_BOSS_NEXT_REFRESH_TIME_FIELD.label = 1
P_WORLD_BOSS_NEXT_REFRESH_TIME_FIELD.has_default_value = true
P_WORLD_BOSS_NEXT_REFRESH_TIME_FIELD.default_value = 0
P_WORLD_BOSS_NEXT_REFRESH_TIME_FIELD.type = 5
P_WORLD_BOSS_NEXT_REFRESH_TIME_FIELD.cpp_type = 1

P_WORLD_BOSS_REMAIN_NUM_FIELD.name = "remain_num"
P_WORLD_BOSS_REMAIN_NUM_FIELD.full_name = ".p_world_boss.remain_num"
P_WORLD_BOSS_REMAIN_NUM_FIELD.number = 5
P_WORLD_BOSS_REMAIN_NUM_FIELD.index = 4
P_WORLD_BOSS_REMAIN_NUM_FIELD.label = 1
P_WORLD_BOSS_REMAIN_NUM_FIELD.has_default_value = true
P_WORLD_BOSS_REMAIN_NUM_FIELD.default_value = 0
P_WORLD_BOSS_REMAIN_NUM_FIELD.type = 5
P_WORLD_BOSS_REMAIN_NUM_FIELD.cpp_type = 1

P_WORLD_BOSS_ROLE_NUM_FIELD.name = "role_num"
P_WORLD_BOSS_ROLE_NUM_FIELD.full_name = ".p_world_boss.role_num"
P_WORLD_BOSS_ROLE_NUM_FIELD.number = 6
P_WORLD_BOSS_ROLE_NUM_FIELD.index = 5
P_WORLD_BOSS_ROLE_NUM_FIELD.label = 1
P_WORLD_BOSS_ROLE_NUM_FIELD.has_default_value = true
P_WORLD_BOSS_ROLE_NUM_FIELD.default_value = 0
P_WORLD_BOSS_ROLE_NUM_FIELD.type = 5
P_WORLD_BOSS_ROLE_NUM_FIELD.cpp_type = 1

P_WORLD_BOSS_CAN_ENTER_FIELD.name = "can_enter"
P_WORLD_BOSS_CAN_ENTER_FIELD.full_name = ".p_world_boss.can_enter"
P_WORLD_BOSS_CAN_ENTER_FIELD.number = 7
P_WORLD_BOSS_CAN_ENTER_FIELD.index = 6
P_WORLD_BOSS_CAN_ENTER_FIELD.label = 1
P_WORLD_BOSS_CAN_ENTER_FIELD.has_default_value = true
P_WORLD_BOSS_CAN_ENTER_FIELD.default_value = true
P_WORLD_BOSS_CAN_ENTER_FIELD.type = 8
P_WORLD_BOSS_CAN_ENTER_FIELD.cpp_type = 7

P_WORLD_BOSS.name = "p_world_boss"
P_WORLD_BOSS.full_name = ".p_world_boss"
P_WORLD_BOSS.nested_types = {}
P_WORLD_BOSS.enum_types = {}
P_WORLD_BOSS.fields = {P_WORLD_BOSS_MAP_ID_FIELD, P_WORLD_BOSS_TYPE_ID_FIELD, P_WORLD_BOSS_IS_ALIVE_FIELD, P_WORLD_BOSS_NEXT_REFRESH_TIME_FIELD, P_WORLD_BOSS_REMAIN_NUM_FIELD, P_WORLD_BOSS_ROLE_NUM_FIELD, P_WORLD_BOSS_CAN_ENTER_FIELD}
P_WORLD_BOSS.is_extendable = false
P_WORLD_BOSS.extensions = {}

p_world_boss = protobuf.Message(P_WORLD_BOSS)

