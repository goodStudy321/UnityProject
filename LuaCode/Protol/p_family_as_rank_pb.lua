--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.p_family_as_rank_pb')

P_FAMILY_AS_RANK = protobuf.Descriptor();
P_FAMILY_AS_RANK_RANK_FIELD = protobuf.FieldDescriptor();
P_FAMILY_AS_RANK_NAME_FIELD = protobuf.FieldDescriptor();
P_FAMILY_AS_RANK_SCORE_FIELD = protobuf.FieldDescriptor();

P_FAMILY_AS_RANK_RANK_FIELD.name = "rank"
P_FAMILY_AS_RANK_RANK_FIELD.full_name = ".p_family_as_rank.rank"
P_FAMILY_AS_RANK_RANK_FIELD.number = 1
P_FAMILY_AS_RANK_RANK_FIELD.index = 0
P_FAMILY_AS_RANK_RANK_FIELD.label = 1
P_FAMILY_AS_RANK_RANK_FIELD.has_default_value = true
P_FAMILY_AS_RANK_RANK_FIELD.default_value = 0
P_FAMILY_AS_RANK_RANK_FIELD.type = 5
P_FAMILY_AS_RANK_RANK_FIELD.cpp_type = 1

P_FAMILY_AS_RANK_NAME_FIELD.name = "name"
P_FAMILY_AS_RANK_NAME_FIELD.full_name = ".p_family_as_rank.name"
P_FAMILY_AS_RANK_NAME_FIELD.number = 2
P_FAMILY_AS_RANK_NAME_FIELD.index = 1
P_FAMILY_AS_RANK_NAME_FIELD.label = 1
P_FAMILY_AS_RANK_NAME_FIELD.has_default_value = false
P_FAMILY_AS_RANK_NAME_FIELD.default_value = ""
P_FAMILY_AS_RANK_NAME_FIELD.type = 9
P_FAMILY_AS_RANK_NAME_FIELD.cpp_type = 9

P_FAMILY_AS_RANK_SCORE_FIELD.name = "score"
P_FAMILY_AS_RANK_SCORE_FIELD.full_name = ".p_family_as_rank.score"
P_FAMILY_AS_RANK_SCORE_FIELD.number = 3
P_FAMILY_AS_RANK_SCORE_FIELD.index = 2
P_FAMILY_AS_RANK_SCORE_FIELD.label = 1
P_FAMILY_AS_RANK_SCORE_FIELD.has_default_value = true
P_FAMILY_AS_RANK_SCORE_FIELD.default_value = 0
P_FAMILY_AS_RANK_SCORE_FIELD.type = 5
P_FAMILY_AS_RANK_SCORE_FIELD.cpp_type = 1

P_FAMILY_AS_RANK.name = "p_family_as_rank"
P_FAMILY_AS_RANK.full_name = ".p_family_as_rank"
P_FAMILY_AS_RANK.nested_types = {}
P_FAMILY_AS_RANK.enum_types = {}
P_FAMILY_AS_RANK.fields = {P_FAMILY_AS_RANK_RANK_FIELD, P_FAMILY_AS_RANK_NAME_FIELD, P_FAMILY_AS_RANK_SCORE_FIELD}
P_FAMILY_AS_RANK.is_extendable = false
P_FAMILY_AS_RANK.extensions = {}

p_family_as_rank = protobuf.Message(P_FAMILY_AS_RANK)
