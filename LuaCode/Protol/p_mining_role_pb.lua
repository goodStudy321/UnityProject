--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.p_mining_role_pb')

P_MINING_ROLE = protobuf.Descriptor();
P_MINING_ROLE_X_FIELD = protobuf.FieldDescriptor();
P_MINING_ROLE_Y_FIELD = protobuf.FieldDescriptor();
P_MINING_ROLE_TYPE_ID_FIELD = protobuf.FieldDescriptor();
P_MINING_ROLE_ROLE_ID_FIELD = protobuf.FieldDescriptor();
P_MINING_ROLE_ROLE_NAME_FIELD = protobuf.FieldDescriptor();
P_MINING_ROLE_CATEGORY_FIELD = protobuf.FieldDescriptor();
P_MINING_ROLE_SEX_FIELD = protobuf.FieldDescriptor();
P_MINING_ROLE_FAMILY_ID_FIELD = protobuf.FieldDescriptor();
P_MINING_ROLE_POWER_FIELD = protobuf.FieldDescriptor();
P_MINING_ROLE_IS_FAMILY_ADD_FIELD = protobuf.FieldDescriptor();

P_MINING_ROLE_X_FIELD.name = "x"
P_MINING_ROLE_X_FIELD.full_name = ".p_mining_role.x"
P_MINING_ROLE_X_FIELD.number = 1
P_MINING_ROLE_X_FIELD.index = 0
P_MINING_ROLE_X_FIELD.label = 1
P_MINING_ROLE_X_FIELD.has_default_value = true
P_MINING_ROLE_X_FIELD.default_value = 0
P_MINING_ROLE_X_FIELD.type = 5
P_MINING_ROLE_X_FIELD.cpp_type = 1

P_MINING_ROLE_Y_FIELD.name = "y"
P_MINING_ROLE_Y_FIELD.full_name = ".p_mining_role.y"
P_MINING_ROLE_Y_FIELD.number = 2
P_MINING_ROLE_Y_FIELD.index = 1
P_MINING_ROLE_Y_FIELD.label = 1
P_MINING_ROLE_Y_FIELD.has_default_value = true
P_MINING_ROLE_Y_FIELD.default_value = 0
P_MINING_ROLE_Y_FIELD.type = 5
P_MINING_ROLE_Y_FIELD.cpp_type = 1

P_MINING_ROLE_TYPE_ID_FIELD.name = "type_id"
P_MINING_ROLE_TYPE_ID_FIELD.full_name = ".p_mining_role.type_id"
P_MINING_ROLE_TYPE_ID_FIELD.number = 3
P_MINING_ROLE_TYPE_ID_FIELD.index = 2
P_MINING_ROLE_TYPE_ID_FIELD.label = 1
P_MINING_ROLE_TYPE_ID_FIELD.has_default_value = true
P_MINING_ROLE_TYPE_ID_FIELD.default_value = 0
P_MINING_ROLE_TYPE_ID_FIELD.type = 5
P_MINING_ROLE_TYPE_ID_FIELD.cpp_type = 1

P_MINING_ROLE_ROLE_ID_FIELD.name = "role_id"
P_MINING_ROLE_ROLE_ID_FIELD.full_name = ".p_mining_role.role_id"
P_MINING_ROLE_ROLE_ID_FIELD.number = 4
P_MINING_ROLE_ROLE_ID_FIELD.index = 3
P_MINING_ROLE_ROLE_ID_FIELD.label = 1
P_MINING_ROLE_ROLE_ID_FIELD.has_default_value = true
P_MINING_ROLE_ROLE_ID_FIELD.default_value = 0
P_MINING_ROLE_ROLE_ID_FIELD.type = 3
P_MINING_ROLE_ROLE_ID_FIELD.cpp_type = 2

P_MINING_ROLE_ROLE_NAME_FIELD.name = "role_name"
P_MINING_ROLE_ROLE_NAME_FIELD.full_name = ".p_mining_role.role_name"
P_MINING_ROLE_ROLE_NAME_FIELD.number = 5
P_MINING_ROLE_ROLE_NAME_FIELD.index = 4
P_MINING_ROLE_ROLE_NAME_FIELD.label = 1
P_MINING_ROLE_ROLE_NAME_FIELD.has_default_value = false
P_MINING_ROLE_ROLE_NAME_FIELD.default_value = ""
P_MINING_ROLE_ROLE_NAME_FIELD.type = 9
P_MINING_ROLE_ROLE_NAME_FIELD.cpp_type = 9

P_MINING_ROLE_CATEGORY_FIELD.name = "category"
P_MINING_ROLE_CATEGORY_FIELD.full_name = ".p_mining_role.category"
P_MINING_ROLE_CATEGORY_FIELD.number = 6
P_MINING_ROLE_CATEGORY_FIELD.index = 5
P_MINING_ROLE_CATEGORY_FIELD.label = 1
P_MINING_ROLE_CATEGORY_FIELD.has_default_value = true
P_MINING_ROLE_CATEGORY_FIELD.default_value = 0
P_MINING_ROLE_CATEGORY_FIELD.type = 5
P_MINING_ROLE_CATEGORY_FIELD.cpp_type = 1

P_MINING_ROLE_SEX_FIELD.name = "sex"
P_MINING_ROLE_SEX_FIELD.full_name = ".p_mining_role.sex"
P_MINING_ROLE_SEX_FIELD.number = 7
P_MINING_ROLE_SEX_FIELD.index = 6
P_MINING_ROLE_SEX_FIELD.label = 1
P_MINING_ROLE_SEX_FIELD.has_default_value = true
P_MINING_ROLE_SEX_FIELD.default_value = 0
P_MINING_ROLE_SEX_FIELD.type = 5
P_MINING_ROLE_SEX_FIELD.cpp_type = 1

P_MINING_ROLE_FAMILY_ID_FIELD.name = "family_id"
P_MINING_ROLE_FAMILY_ID_FIELD.full_name = ".p_mining_role.family_id"
P_MINING_ROLE_FAMILY_ID_FIELD.number = 8
P_MINING_ROLE_FAMILY_ID_FIELD.index = 7
P_MINING_ROLE_FAMILY_ID_FIELD.label = 1
P_MINING_ROLE_FAMILY_ID_FIELD.has_default_value = true
P_MINING_ROLE_FAMILY_ID_FIELD.default_value = 0
P_MINING_ROLE_FAMILY_ID_FIELD.type = 3
P_MINING_ROLE_FAMILY_ID_FIELD.cpp_type = 2

P_MINING_ROLE_POWER_FIELD.name = "power"
P_MINING_ROLE_POWER_FIELD.full_name = ".p_mining_role.power"
P_MINING_ROLE_POWER_FIELD.number = 9
P_MINING_ROLE_POWER_FIELD.index = 8
P_MINING_ROLE_POWER_FIELD.label = 1
P_MINING_ROLE_POWER_FIELD.has_default_value = true
P_MINING_ROLE_POWER_FIELD.default_value = 0
P_MINING_ROLE_POWER_FIELD.type = 5
P_MINING_ROLE_POWER_FIELD.cpp_type = 1

P_MINING_ROLE_IS_FAMILY_ADD_FIELD.name = "is_family_add"
P_MINING_ROLE_IS_FAMILY_ADD_FIELD.full_name = ".p_mining_role.is_family_add"
P_MINING_ROLE_IS_FAMILY_ADD_FIELD.number = 10
P_MINING_ROLE_IS_FAMILY_ADD_FIELD.index = 9
P_MINING_ROLE_IS_FAMILY_ADD_FIELD.label = 1
P_MINING_ROLE_IS_FAMILY_ADD_FIELD.has_default_value = true
P_MINING_ROLE_IS_FAMILY_ADD_FIELD.default_value = true
P_MINING_ROLE_IS_FAMILY_ADD_FIELD.type = 8
P_MINING_ROLE_IS_FAMILY_ADD_FIELD.cpp_type = 7

P_MINING_ROLE.name = "p_mining_role"
P_MINING_ROLE.full_name = ".p_mining_role"
P_MINING_ROLE.nested_types = {}
P_MINING_ROLE.enum_types = {}
P_MINING_ROLE.fields = {P_MINING_ROLE_X_FIELD, P_MINING_ROLE_Y_FIELD, P_MINING_ROLE_TYPE_ID_FIELD, P_MINING_ROLE_ROLE_ID_FIELD, P_MINING_ROLE_ROLE_NAME_FIELD, P_MINING_ROLE_CATEGORY_FIELD, P_MINING_ROLE_SEX_FIELD, P_MINING_ROLE_FAMILY_ID_FIELD, P_MINING_ROLE_POWER_FIELD, P_MINING_ROLE_IS_FAMILY_ADD_FIELD}
P_MINING_ROLE.is_extendable = false
P_MINING_ROLE.extensions = {}

p_mining_role = protobuf.Message(P_MINING_ROLE)
