--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.p_world_boss_rank_pb')

P_WORLD_BOSS_RANK = protobuf.Descriptor();
P_WORLD_BOSS_RANK_RANK_FIELD = protobuf.FieldDescriptor();
P_WORLD_BOSS_RANK_ROLE_ID_FIELD = protobuf.FieldDescriptor();
P_WORLD_BOSS_RANK_ROLE_NAME_FIELD = protobuf.FieldDescriptor();
P_WORLD_BOSS_RANK_DAMAGE_FIELD = protobuf.FieldDescriptor();

P_WORLD_BOSS_RANK_RANK_FIELD.name = "rank"
P_WORLD_BOSS_RANK_RANK_FIELD.full_name = ".p_world_boss_rank.rank"
P_WORLD_BOSS_RANK_RANK_FIELD.number = 1
P_WORLD_BOSS_RANK_RANK_FIELD.index = 0
P_WORLD_BOSS_RANK_RANK_FIELD.label = 1
P_WORLD_BOSS_RANK_RANK_FIELD.has_default_value = true
P_WORLD_BOSS_RANK_RANK_FIELD.default_value = 0
P_WORLD_BOSS_RANK_RANK_FIELD.type = 5
P_WORLD_BOSS_RANK_RANK_FIELD.cpp_type = 1

P_WORLD_BOSS_RANK_ROLE_ID_FIELD.name = "role_id"
P_WORLD_BOSS_RANK_ROLE_ID_FIELD.full_name = ".p_world_boss_rank.role_id"
P_WORLD_BOSS_RANK_ROLE_ID_FIELD.number = 2
P_WORLD_BOSS_RANK_ROLE_ID_FIELD.index = 1
P_WORLD_BOSS_RANK_ROLE_ID_FIELD.label = 1
P_WORLD_BOSS_RANK_ROLE_ID_FIELD.has_default_value = true
P_WORLD_BOSS_RANK_ROLE_ID_FIELD.default_value = 0
P_WORLD_BOSS_RANK_ROLE_ID_FIELD.type = 3
P_WORLD_BOSS_RANK_ROLE_ID_FIELD.cpp_type = 2

P_WORLD_BOSS_RANK_ROLE_NAME_FIELD.name = "role_name"
P_WORLD_BOSS_RANK_ROLE_NAME_FIELD.full_name = ".p_world_boss_rank.role_name"
P_WORLD_BOSS_RANK_ROLE_NAME_FIELD.number = 3
P_WORLD_BOSS_RANK_ROLE_NAME_FIELD.index = 2
P_WORLD_BOSS_RANK_ROLE_NAME_FIELD.label = 1
P_WORLD_BOSS_RANK_ROLE_NAME_FIELD.has_default_value = false
P_WORLD_BOSS_RANK_ROLE_NAME_FIELD.default_value = ""
P_WORLD_BOSS_RANK_ROLE_NAME_FIELD.type = 9
P_WORLD_BOSS_RANK_ROLE_NAME_FIELD.cpp_type = 9

P_WORLD_BOSS_RANK_DAMAGE_FIELD.name = "damage"
P_WORLD_BOSS_RANK_DAMAGE_FIELD.full_name = ".p_world_boss_rank.damage"
P_WORLD_BOSS_RANK_DAMAGE_FIELD.number = 4
P_WORLD_BOSS_RANK_DAMAGE_FIELD.index = 3
P_WORLD_BOSS_RANK_DAMAGE_FIELD.label = 1
P_WORLD_BOSS_RANK_DAMAGE_FIELD.has_default_value = true
P_WORLD_BOSS_RANK_DAMAGE_FIELD.default_value = 0
P_WORLD_BOSS_RANK_DAMAGE_FIELD.type = 3
P_WORLD_BOSS_RANK_DAMAGE_FIELD.cpp_type = 2

P_WORLD_BOSS_RANK.name = "p_world_boss_rank"
P_WORLD_BOSS_RANK.full_name = ".p_world_boss_rank"
P_WORLD_BOSS_RANK.nested_types = {}
P_WORLD_BOSS_RANK.enum_types = {}
P_WORLD_BOSS_RANK.fields = {P_WORLD_BOSS_RANK_RANK_FIELD, P_WORLD_BOSS_RANK_ROLE_ID_FIELD, P_WORLD_BOSS_RANK_ROLE_NAME_FIELD, P_WORLD_BOSS_RANK_DAMAGE_FIELD}
P_WORLD_BOSS_RANK.is_extendable = false
P_WORLD_BOSS_RANK.extensions = {}

p_world_boss_rank = protobuf.Message(P_WORLD_BOSS_RANK)

