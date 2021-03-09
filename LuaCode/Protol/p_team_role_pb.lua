--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.p_team_role_pb')

P_TEAM_ROLE = protobuf.Descriptor();
P_TEAM_ROLE_ROLE_ID_FIELD = protobuf.FieldDescriptor();
P_TEAM_ROLE_ROLE_NAME_FIELD = protobuf.FieldDescriptor();
P_TEAM_ROLE_ROLE_LEVEL_FIELD = protobuf.FieldDescriptor();
P_TEAM_ROLE_CATEGORY_FIELD = protobuf.FieldDescriptor();
P_TEAM_ROLE_SEX_FIELD = protobuf.FieldDescriptor();
P_TEAM_ROLE_IS_ONLINE_FIELD = protobuf.FieldDescriptor();
P_TEAM_ROLE_MAP_ID_FIELD = protobuf.FieldDescriptor();
P_TEAM_ROLE_SKIN_LIST_FIELD = protobuf.FieldDescriptor();
P_TEAM_ROLE_ORNAMENT_LIST_FIELD = protobuf.FieldDescriptor();

P_TEAM_ROLE_ROLE_ID_FIELD.name = "role_id"
P_TEAM_ROLE_ROLE_ID_FIELD.full_name = ".p_team_role.role_id"
P_TEAM_ROLE_ROLE_ID_FIELD.number = 1
P_TEAM_ROLE_ROLE_ID_FIELD.index = 0
P_TEAM_ROLE_ROLE_ID_FIELD.label = 1
P_TEAM_ROLE_ROLE_ID_FIELD.has_default_value = true
P_TEAM_ROLE_ROLE_ID_FIELD.default_value = 0
P_TEAM_ROLE_ROLE_ID_FIELD.type = 3
P_TEAM_ROLE_ROLE_ID_FIELD.cpp_type = 2

P_TEAM_ROLE_ROLE_NAME_FIELD.name = "role_name"
P_TEAM_ROLE_ROLE_NAME_FIELD.full_name = ".p_team_role.role_name"
P_TEAM_ROLE_ROLE_NAME_FIELD.number = 2
P_TEAM_ROLE_ROLE_NAME_FIELD.index = 1
P_TEAM_ROLE_ROLE_NAME_FIELD.label = 1
P_TEAM_ROLE_ROLE_NAME_FIELD.has_default_value = false
P_TEAM_ROLE_ROLE_NAME_FIELD.default_value = ""
P_TEAM_ROLE_ROLE_NAME_FIELD.type = 9
P_TEAM_ROLE_ROLE_NAME_FIELD.cpp_type = 9

P_TEAM_ROLE_ROLE_LEVEL_FIELD.name = "role_level"
P_TEAM_ROLE_ROLE_LEVEL_FIELD.full_name = ".p_team_role.role_level"
P_TEAM_ROLE_ROLE_LEVEL_FIELD.number = 3
P_TEAM_ROLE_ROLE_LEVEL_FIELD.index = 2
P_TEAM_ROLE_ROLE_LEVEL_FIELD.label = 1
P_TEAM_ROLE_ROLE_LEVEL_FIELD.has_default_value = true
P_TEAM_ROLE_ROLE_LEVEL_FIELD.default_value = 0
P_TEAM_ROLE_ROLE_LEVEL_FIELD.type = 5
P_TEAM_ROLE_ROLE_LEVEL_FIELD.cpp_type = 1

P_TEAM_ROLE_CATEGORY_FIELD.name = "category"
P_TEAM_ROLE_CATEGORY_FIELD.full_name = ".p_team_role.category"
P_TEAM_ROLE_CATEGORY_FIELD.number = 4
P_TEAM_ROLE_CATEGORY_FIELD.index = 3
P_TEAM_ROLE_CATEGORY_FIELD.label = 1
P_TEAM_ROLE_CATEGORY_FIELD.has_default_value = true
P_TEAM_ROLE_CATEGORY_FIELD.default_value = 0
P_TEAM_ROLE_CATEGORY_FIELD.type = 5
P_TEAM_ROLE_CATEGORY_FIELD.cpp_type = 1

P_TEAM_ROLE_SEX_FIELD.name = "sex"
P_TEAM_ROLE_SEX_FIELD.full_name = ".p_team_role.sex"
P_TEAM_ROLE_SEX_FIELD.number = 5
P_TEAM_ROLE_SEX_FIELD.index = 4
P_TEAM_ROLE_SEX_FIELD.label = 1
P_TEAM_ROLE_SEX_FIELD.has_default_value = true
P_TEAM_ROLE_SEX_FIELD.default_value = 0
P_TEAM_ROLE_SEX_FIELD.type = 5
P_TEAM_ROLE_SEX_FIELD.cpp_type = 1

P_TEAM_ROLE_IS_ONLINE_FIELD.name = "is_online"
P_TEAM_ROLE_IS_ONLINE_FIELD.full_name = ".p_team_role.is_online"
P_TEAM_ROLE_IS_ONLINE_FIELD.number = 6
P_TEAM_ROLE_IS_ONLINE_FIELD.index = 5
P_TEAM_ROLE_IS_ONLINE_FIELD.label = 1
P_TEAM_ROLE_IS_ONLINE_FIELD.has_default_value = true
P_TEAM_ROLE_IS_ONLINE_FIELD.default_value = true
P_TEAM_ROLE_IS_ONLINE_FIELD.type = 8
P_TEAM_ROLE_IS_ONLINE_FIELD.cpp_type = 7

P_TEAM_ROLE_MAP_ID_FIELD.name = "map_id"
P_TEAM_ROLE_MAP_ID_FIELD.full_name = ".p_team_role.map_id"
P_TEAM_ROLE_MAP_ID_FIELD.number = 7
P_TEAM_ROLE_MAP_ID_FIELD.index = 6
P_TEAM_ROLE_MAP_ID_FIELD.label = 1
P_TEAM_ROLE_MAP_ID_FIELD.has_default_value = true
P_TEAM_ROLE_MAP_ID_FIELD.default_value = 0
P_TEAM_ROLE_MAP_ID_FIELD.type = 5
P_TEAM_ROLE_MAP_ID_FIELD.cpp_type = 1

P_TEAM_ROLE_SKIN_LIST_FIELD.name = "skin_list"
P_TEAM_ROLE_SKIN_LIST_FIELD.full_name = ".p_team_role.skin_list"
P_TEAM_ROLE_SKIN_LIST_FIELD.number = 8
P_TEAM_ROLE_SKIN_LIST_FIELD.index = 7
P_TEAM_ROLE_SKIN_LIST_FIELD.label = 3
P_TEAM_ROLE_SKIN_LIST_FIELD.has_default_value = false
P_TEAM_ROLE_SKIN_LIST_FIELD.default_value = {}
P_TEAM_ROLE_SKIN_LIST_FIELD.type = 5
P_TEAM_ROLE_SKIN_LIST_FIELD.cpp_type = 1

P_TEAM_ROLE_ORNAMENT_LIST_FIELD.name = "ornament_list"
P_TEAM_ROLE_ORNAMENT_LIST_FIELD.full_name = ".p_team_role.ornament_list"
P_TEAM_ROLE_ORNAMENT_LIST_FIELD.number = 9
P_TEAM_ROLE_ORNAMENT_LIST_FIELD.index = 8
P_TEAM_ROLE_ORNAMENT_LIST_FIELD.label = 3
P_TEAM_ROLE_ORNAMENT_LIST_FIELD.has_default_value = false
P_TEAM_ROLE_ORNAMENT_LIST_FIELD.default_value = {}
P_TEAM_ROLE_ORNAMENT_LIST_FIELD.type = 5
P_TEAM_ROLE_ORNAMENT_LIST_FIELD.cpp_type = 1

P_TEAM_ROLE.name = "p_team_role"
P_TEAM_ROLE.full_name = ".p_team_role"
P_TEAM_ROLE.nested_types = {}
P_TEAM_ROLE.enum_types = {}
P_TEAM_ROLE.fields = {P_TEAM_ROLE_ROLE_ID_FIELD, P_TEAM_ROLE_ROLE_NAME_FIELD, P_TEAM_ROLE_ROLE_LEVEL_FIELD, P_TEAM_ROLE_CATEGORY_FIELD, P_TEAM_ROLE_SEX_FIELD, P_TEAM_ROLE_IS_ONLINE_FIELD, P_TEAM_ROLE_MAP_ID_FIELD, P_TEAM_ROLE_SKIN_LIST_FIELD, P_TEAM_ROLE_ORNAMENT_LIST_FIELD}
P_TEAM_ROLE.is_extendable = false
P_TEAM_ROLE.extensions = {}

p_team_role = protobuf.Message(P_TEAM_ROLE)

