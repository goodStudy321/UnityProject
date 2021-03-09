--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.p_battle_rank_pb')

P_BATTLE_RANK = protobuf.Descriptor();
P_BATTLE_RANK_RANK_FIELD = protobuf.FieldDescriptor();
P_BATTLE_RANK_ROLE_ID_FIELD = protobuf.FieldDescriptor();
P_BATTLE_RANK_ROLE_NAME_FIELD = protobuf.FieldDescriptor();
P_BATTLE_RANK_ROLE_LEVEL_FIELD = protobuf.FieldDescriptor();
P_BATTLE_RANK_SCORE_FIELD = protobuf.FieldDescriptor();
P_BATTLE_RANK_POWER_FIELD = protobuf.FieldDescriptor();
P_BATTLE_RANK_CAMP_ID_FIELD = protobuf.FieldDescriptor();

P_BATTLE_RANK_RANK_FIELD.name = "rank"
P_BATTLE_RANK_RANK_FIELD.full_name = ".p_battle_rank.rank"
P_BATTLE_RANK_RANK_FIELD.number = 1
P_BATTLE_RANK_RANK_FIELD.index = 0
P_BATTLE_RANK_RANK_FIELD.label = 1
P_BATTLE_RANK_RANK_FIELD.has_default_value = true
P_BATTLE_RANK_RANK_FIELD.default_value = 0
P_BATTLE_RANK_RANK_FIELD.type = 5
P_BATTLE_RANK_RANK_FIELD.cpp_type = 1

P_BATTLE_RANK_ROLE_ID_FIELD.name = "role_id"
P_BATTLE_RANK_ROLE_ID_FIELD.full_name = ".p_battle_rank.role_id"
P_BATTLE_RANK_ROLE_ID_FIELD.number = 2
P_BATTLE_RANK_ROLE_ID_FIELD.index = 1
P_BATTLE_RANK_ROLE_ID_FIELD.label = 1
P_BATTLE_RANK_ROLE_ID_FIELD.has_default_value = true
P_BATTLE_RANK_ROLE_ID_FIELD.default_value = 0
P_BATTLE_RANK_ROLE_ID_FIELD.type = 3
P_BATTLE_RANK_ROLE_ID_FIELD.cpp_type = 2

P_BATTLE_RANK_ROLE_NAME_FIELD.name = "role_name"
P_BATTLE_RANK_ROLE_NAME_FIELD.full_name = ".p_battle_rank.role_name"
P_BATTLE_RANK_ROLE_NAME_FIELD.number = 3
P_BATTLE_RANK_ROLE_NAME_FIELD.index = 2
P_BATTLE_RANK_ROLE_NAME_FIELD.label = 1
P_BATTLE_RANK_ROLE_NAME_FIELD.has_default_value = false
P_BATTLE_RANK_ROLE_NAME_FIELD.default_value = ""
P_BATTLE_RANK_ROLE_NAME_FIELD.type = 9
P_BATTLE_RANK_ROLE_NAME_FIELD.cpp_type = 9

P_BATTLE_RANK_ROLE_LEVEL_FIELD.name = "role_level"
P_BATTLE_RANK_ROLE_LEVEL_FIELD.full_name = ".p_battle_rank.role_level"
P_BATTLE_RANK_ROLE_LEVEL_FIELD.number = 4
P_BATTLE_RANK_ROLE_LEVEL_FIELD.index = 3
P_BATTLE_RANK_ROLE_LEVEL_FIELD.label = 1
P_BATTLE_RANK_ROLE_LEVEL_FIELD.has_default_value = true
P_BATTLE_RANK_ROLE_LEVEL_FIELD.default_value = 0
P_BATTLE_RANK_ROLE_LEVEL_FIELD.type = 5
P_BATTLE_RANK_ROLE_LEVEL_FIELD.cpp_type = 1

P_BATTLE_RANK_SCORE_FIELD.name = "score"
P_BATTLE_RANK_SCORE_FIELD.full_name = ".p_battle_rank.score"
P_BATTLE_RANK_SCORE_FIELD.number = 5
P_BATTLE_RANK_SCORE_FIELD.index = 4
P_BATTLE_RANK_SCORE_FIELD.label = 1
P_BATTLE_RANK_SCORE_FIELD.has_default_value = true
P_BATTLE_RANK_SCORE_FIELD.default_value = 0
P_BATTLE_RANK_SCORE_FIELD.type = 5
P_BATTLE_RANK_SCORE_FIELD.cpp_type = 1

P_BATTLE_RANK_POWER_FIELD.name = "power"
P_BATTLE_RANK_POWER_FIELD.full_name = ".p_battle_rank.power"
P_BATTLE_RANK_POWER_FIELD.number = 6
P_BATTLE_RANK_POWER_FIELD.index = 5
P_BATTLE_RANK_POWER_FIELD.label = 1
P_BATTLE_RANK_POWER_FIELD.has_default_value = true
P_BATTLE_RANK_POWER_FIELD.default_value = 0
P_BATTLE_RANK_POWER_FIELD.type = 5
P_BATTLE_RANK_POWER_FIELD.cpp_type = 1

P_BATTLE_RANK_CAMP_ID_FIELD.name = "camp_id"
P_BATTLE_RANK_CAMP_ID_FIELD.full_name = ".p_battle_rank.camp_id"
P_BATTLE_RANK_CAMP_ID_FIELD.number = 7
P_BATTLE_RANK_CAMP_ID_FIELD.index = 6
P_BATTLE_RANK_CAMP_ID_FIELD.label = 1
P_BATTLE_RANK_CAMP_ID_FIELD.has_default_value = true
P_BATTLE_RANK_CAMP_ID_FIELD.default_value = 0
P_BATTLE_RANK_CAMP_ID_FIELD.type = 5
P_BATTLE_RANK_CAMP_ID_FIELD.cpp_type = 1

P_BATTLE_RANK.name = "p_battle_rank"
P_BATTLE_RANK.full_name = ".p_battle_rank"
P_BATTLE_RANK.nested_types = {}
P_BATTLE_RANK.enum_types = {}
P_BATTLE_RANK.fields = {P_BATTLE_RANK_RANK_FIELD, P_BATTLE_RANK_ROLE_ID_FIELD, P_BATTLE_RANK_ROLE_NAME_FIELD, P_BATTLE_RANK_ROLE_LEVEL_FIELD, P_BATTLE_RANK_SCORE_FIELD, P_BATTLE_RANK_POWER_FIELD, P_BATTLE_RANK_CAMP_ID_FIELD}
P_BATTLE_RANK.is_extendable = false
P_BATTLE_RANK.extensions = {}

p_battle_rank = protobuf.Message(P_BATTLE_RANK)
