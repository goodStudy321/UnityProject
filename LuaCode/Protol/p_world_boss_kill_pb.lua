--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.p_world_boss_kill_pb')

P_WORLD_BOSS_KILL = protobuf.Descriptor();
P_WORLD_BOSS_KILL_ROLE_ID_FIELD = protobuf.FieldDescriptor();
P_WORLD_BOSS_KILL_ROLE_NAME_FIELD = protobuf.FieldDescriptor();
P_WORLD_BOSS_KILL_KILL_TIME_FIELD = protobuf.FieldDescriptor();

P_WORLD_BOSS_KILL_ROLE_ID_FIELD.name = "role_id"
P_WORLD_BOSS_KILL_ROLE_ID_FIELD.full_name = ".p_world_boss_kill.role_id"
P_WORLD_BOSS_KILL_ROLE_ID_FIELD.number = 1
P_WORLD_BOSS_KILL_ROLE_ID_FIELD.index = 0
P_WORLD_BOSS_KILL_ROLE_ID_FIELD.label = 1
P_WORLD_BOSS_KILL_ROLE_ID_FIELD.has_default_value = true
P_WORLD_BOSS_KILL_ROLE_ID_FIELD.default_value = 0
P_WORLD_BOSS_KILL_ROLE_ID_FIELD.type = 3
P_WORLD_BOSS_KILL_ROLE_ID_FIELD.cpp_type = 2

P_WORLD_BOSS_KILL_ROLE_NAME_FIELD.name = "role_name"
P_WORLD_BOSS_KILL_ROLE_NAME_FIELD.full_name = ".p_world_boss_kill.role_name"
P_WORLD_BOSS_KILL_ROLE_NAME_FIELD.number = 2
P_WORLD_BOSS_KILL_ROLE_NAME_FIELD.index = 1
P_WORLD_BOSS_KILL_ROLE_NAME_FIELD.label = 1
P_WORLD_BOSS_KILL_ROLE_NAME_FIELD.has_default_value = false
P_WORLD_BOSS_KILL_ROLE_NAME_FIELD.default_value = ""
P_WORLD_BOSS_KILL_ROLE_NAME_FIELD.type = 9
P_WORLD_BOSS_KILL_ROLE_NAME_FIELD.cpp_type = 9

P_WORLD_BOSS_KILL_KILL_TIME_FIELD.name = "kill_time"
P_WORLD_BOSS_KILL_KILL_TIME_FIELD.full_name = ".p_world_boss_kill.kill_time"
P_WORLD_BOSS_KILL_KILL_TIME_FIELD.number = 3
P_WORLD_BOSS_KILL_KILL_TIME_FIELD.index = 2
P_WORLD_BOSS_KILL_KILL_TIME_FIELD.label = 1
P_WORLD_BOSS_KILL_KILL_TIME_FIELD.has_default_value = true
P_WORLD_BOSS_KILL_KILL_TIME_FIELD.default_value = 0
P_WORLD_BOSS_KILL_KILL_TIME_FIELD.type = 5
P_WORLD_BOSS_KILL_KILL_TIME_FIELD.cpp_type = 1

P_WORLD_BOSS_KILL.name = "p_world_boss_kill"
P_WORLD_BOSS_KILL.full_name = ".p_world_boss_kill"
P_WORLD_BOSS_KILL.nested_types = {}
P_WORLD_BOSS_KILL.enum_types = {}
P_WORLD_BOSS_KILL.fields = {P_WORLD_BOSS_KILL_ROLE_ID_FIELD, P_WORLD_BOSS_KILL_ROLE_NAME_FIELD, P_WORLD_BOSS_KILL_KILL_TIME_FIELD}
P_WORLD_BOSS_KILL.is_extendable = false
P_WORLD_BOSS_KILL.extensions = {}

p_world_boss_kill = protobuf.Message(P_WORLD_BOSS_KILL)

