--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_role_nature_opt_tos_pb')

M_ROLE_NATURE_OPT_TOS = protobuf.Descriptor();
M_ROLE_NATURE_OPT_TOS_QUALITY_FIELD = protobuf.FieldDescriptor();
M_ROLE_NATURE_OPT_TOS_STAR_FIELD = protobuf.FieldDescriptor();

M_ROLE_NATURE_OPT_TOS_QUALITY_FIELD.name = "quality"
M_ROLE_NATURE_OPT_TOS_QUALITY_FIELD.full_name = ".m_role_nature_opt_tos.quality"
M_ROLE_NATURE_OPT_TOS_QUALITY_FIELD.number = 1
M_ROLE_NATURE_OPT_TOS_QUALITY_FIELD.index = 0
M_ROLE_NATURE_OPT_TOS_QUALITY_FIELD.label = 1
M_ROLE_NATURE_OPT_TOS_QUALITY_FIELD.has_default_value = true
M_ROLE_NATURE_OPT_TOS_QUALITY_FIELD.default_value = 0
M_ROLE_NATURE_OPT_TOS_QUALITY_FIELD.type = 5
M_ROLE_NATURE_OPT_TOS_QUALITY_FIELD.cpp_type = 1

M_ROLE_NATURE_OPT_TOS_STAR_FIELD.name = "star"
M_ROLE_NATURE_OPT_TOS_STAR_FIELD.full_name = ".m_role_nature_opt_tos.star"
M_ROLE_NATURE_OPT_TOS_STAR_FIELD.number = 2
M_ROLE_NATURE_OPT_TOS_STAR_FIELD.index = 1
M_ROLE_NATURE_OPT_TOS_STAR_FIELD.label = 1
M_ROLE_NATURE_OPT_TOS_STAR_FIELD.has_default_value = true
M_ROLE_NATURE_OPT_TOS_STAR_FIELD.default_value = 0
M_ROLE_NATURE_OPT_TOS_STAR_FIELD.type = 5
M_ROLE_NATURE_OPT_TOS_STAR_FIELD.cpp_type = 1

M_ROLE_NATURE_OPT_TOS.name = "m_role_nature_opt_tos"
M_ROLE_NATURE_OPT_TOS.full_name = ".m_role_nature_opt_tos"
M_ROLE_NATURE_OPT_TOS.nested_types = {}
M_ROLE_NATURE_OPT_TOS.enum_types = {}
M_ROLE_NATURE_OPT_TOS.fields = {M_ROLE_NATURE_OPT_TOS_QUALITY_FIELD, M_ROLE_NATURE_OPT_TOS_STAR_FIELD}
M_ROLE_NATURE_OPT_TOS.is_extendable = false
M_ROLE_NATURE_OPT_TOS.extensions = {}

m_role_nature_opt_tos = protobuf.Message(M_ROLE_NATURE_OPT_TOS)

