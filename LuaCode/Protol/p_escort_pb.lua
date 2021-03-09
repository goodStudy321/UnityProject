--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.p_escort_pb')

P_ESCORT = protobuf.Descriptor();
P_ESCORT_ID_FIELD = protobuf.FieldDescriptor();
P_ESCORT_ROLE_ID_FIELD = protobuf.FieldDescriptor();
P_ESCORT_END_TIME_FIELD = protobuf.FieldDescriptor();
P_ESCORT_FIGHT_FIELD = protobuf.FieldDescriptor();
P_ESCORT_ROLE_NAME_FIELD = protobuf.FieldDescriptor();
P_ESCORT_TYPE_FIELD = protobuf.FieldDescriptor();
P_ESCORT_SERVER_NAME_FIELD = protobuf.FieldDescriptor();

P_ESCORT_ID_FIELD.name = "id"
P_ESCORT_ID_FIELD.full_name = ".p_escort.id"
P_ESCORT_ID_FIELD.number = 1
P_ESCORT_ID_FIELD.index = 0
P_ESCORT_ID_FIELD.label = 1
P_ESCORT_ID_FIELD.has_default_value = true
P_ESCORT_ID_FIELD.default_value = 0
P_ESCORT_ID_FIELD.type = 5
P_ESCORT_ID_FIELD.cpp_type = 1

P_ESCORT_ROLE_ID_FIELD.name = "role_id"
P_ESCORT_ROLE_ID_FIELD.full_name = ".p_escort.role_id"
P_ESCORT_ROLE_ID_FIELD.number = 2
P_ESCORT_ROLE_ID_FIELD.index = 1
P_ESCORT_ROLE_ID_FIELD.label = 1
P_ESCORT_ROLE_ID_FIELD.has_default_value = true
P_ESCORT_ROLE_ID_FIELD.default_value = 0
P_ESCORT_ROLE_ID_FIELD.type = 3
P_ESCORT_ROLE_ID_FIELD.cpp_type = 2

P_ESCORT_END_TIME_FIELD.name = "end_time"
P_ESCORT_END_TIME_FIELD.full_name = ".p_escort.end_time"
P_ESCORT_END_TIME_FIELD.number = 3
P_ESCORT_END_TIME_FIELD.index = 2
P_ESCORT_END_TIME_FIELD.label = 1
P_ESCORT_END_TIME_FIELD.has_default_value = true
P_ESCORT_END_TIME_FIELD.default_value = 0
P_ESCORT_END_TIME_FIELD.type = 5
P_ESCORT_END_TIME_FIELD.cpp_type = 1

P_ESCORT_FIGHT_FIELD.name = "fight"
P_ESCORT_FIGHT_FIELD.full_name = ".p_escort.fight"
P_ESCORT_FIGHT_FIELD.number = 4
P_ESCORT_FIGHT_FIELD.index = 3
P_ESCORT_FIGHT_FIELD.label = 1
P_ESCORT_FIGHT_FIELD.has_default_value = true
P_ESCORT_FIGHT_FIELD.default_value = 0
P_ESCORT_FIGHT_FIELD.type = 3
P_ESCORT_FIGHT_FIELD.cpp_type = 2

P_ESCORT_ROLE_NAME_FIELD.name = "role_name"
P_ESCORT_ROLE_NAME_FIELD.full_name = ".p_escort.role_name"
P_ESCORT_ROLE_NAME_FIELD.number = 5
P_ESCORT_ROLE_NAME_FIELD.index = 4
P_ESCORT_ROLE_NAME_FIELD.label = 1
P_ESCORT_ROLE_NAME_FIELD.has_default_value = false
P_ESCORT_ROLE_NAME_FIELD.default_value = ""
P_ESCORT_ROLE_NAME_FIELD.type = 9
P_ESCORT_ROLE_NAME_FIELD.cpp_type = 9

P_ESCORT_TYPE_FIELD.name = "type"
P_ESCORT_TYPE_FIELD.full_name = ".p_escort.type"
P_ESCORT_TYPE_FIELD.number = 6
P_ESCORT_TYPE_FIELD.index = 5
P_ESCORT_TYPE_FIELD.label = 1
P_ESCORT_TYPE_FIELD.has_default_value = true
P_ESCORT_TYPE_FIELD.default_value = 0
P_ESCORT_TYPE_FIELD.type = 5
P_ESCORT_TYPE_FIELD.cpp_type = 1

P_ESCORT_SERVER_NAME_FIELD.name = "server_name"
P_ESCORT_SERVER_NAME_FIELD.full_name = ".p_escort.server_name"
P_ESCORT_SERVER_NAME_FIELD.number = 7
P_ESCORT_SERVER_NAME_FIELD.index = 6
P_ESCORT_SERVER_NAME_FIELD.label = 1
P_ESCORT_SERVER_NAME_FIELD.has_default_value = false
P_ESCORT_SERVER_NAME_FIELD.default_value = ""
P_ESCORT_SERVER_NAME_FIELD.type = 9
P_ESCORT_SERVER_NAME_FIELD.cpp_type = 9

P_ESCORT.name = "p_escort"
P_ESCORT.full_name = ".p_escort"
P_ESCORT.nested_types = {}
P_ESCORT.enum_types = {}
P_ESCORT.fields = {P_ESCORT_ID_FIELD, P_ESCORT_ROLE_ID_FIELD, P_ESCORT_END_TIME_FIELD, P_ESCORT_FIGHT_FIELD, P_ESCORT_ROLE_NAME_FIELD, P_ESCORT_TYPE_FIELD, P_ESCORT_SERVER_NAME_FIELD}
P_ESCORT.is_extendable = false
P_ESCORT.extensions = {}

p_escort = protobuf.Message(P_ESCORT)

