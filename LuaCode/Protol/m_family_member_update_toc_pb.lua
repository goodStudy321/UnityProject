--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_family_member_pb = require("Protol.p_family_member_pb")
module('Protol.m_family_member_update_toc_pb')

M_FAMILY_MEMBER_UPDATE_TOC = protobuf.Descriptor();
M_FAMILY_MEMBER_UPDATE_TOC_MEMBER_FIELD = protobuf.FieldDescriptor();
M_FAMILY_MEMBER_UPDATE_TOC_DEL_MEMBER_ID_FIELD = protobuf.FieldDescriptor();

M_FAMILY_MEMBER_UPDATE_TOC_MEMBER_FIELD.name = "member"
M_FAMILY_MEMBER_UPDATE_TOC_MEMBER_FIELD.full_name = ".m_family_member_update_toc.member"
M_FAMILY_MEMBER_UPDATE_TOC_MEMBER_FIELD.number = 1
M_FAMILY_MEMBER_UPDATE_TOC_MEMBER_FIELD.index = 0
M_FAMILY_MEMBER_UPDATE_TOC_MEMBER_FIELD.label = 1
M_FAMILY_MEMBER_UPDATE_TOC_MEMBER_FIELD.has_default_value = false
M_FAMILY_MEMBER_UPDATE_TOC_MEMBER_FIELD.default_value = nil
M_FAMILY_MEMBER_UPDATE_TOC_MEMBER_FIELD.message_type = p_family_member_pb.P_FAMILY_MEMBER
M_FAMILY_MEMBER_UPDATE_TOC_MEMBER_FIELD.type = 11
M_FAMILY_MEMBER_UPDATE_TOC_MEMBER_FIELD.cpp_type = 10

M_FAMILY_MEMBER_UPDATE_TOC_DEL_MEMBER_ID_FIELD.name = "del_member_id"
M_FAMILY_MEMBER_UPDATE_TOC_DEL_MEMBER_ID_FIELD.full_name = ".m_family_member_update_toc.del_member_id"
M_FAMILY_MEMBER_UPDATE_TOC_DEL_MEMBER_ID_FIELD.number = 2
M_FAMILY_MEMBER_UPDATE_TOC_DEL_MEMBER_ID_FIELD.index = 1
M_FAMILY_MEMBER_UPDATE_TOC_DEL_MEMBER_ID_FIELD.label = 1
M_FAMILY_MEMBER_UPDATE_TOC_DEL_MEMBER_ID_FIELD.has_default_value = true
M_FAMILY_MEMBER_UPDATE_TOC_DEL_MEMBER_ID_FIELD.default_value = 0
M_FAMILY_MEMBER_UPDATE_TOC_DEL_MEMBER_ID_FIELD.type = 3
M_FAMILY_MEMBER_UPDATE_TOC_DEL_MEMBER_ID_FIELD.cpp_type = 2

M_FAMILY_MEMBER_UPDATE_TOC.name = "m_family_member_update_toc"
M_FAMILY_MEMBER_UPDATE_TOC.full_name = ".m_family_member_update_toc"
M_FAMILY_MEMBER_UPDATE_TOC.nested_types = {}
M_FAMILY_MEMBER_UPDATE_TOC.enum_types = {}
M_FAMILY_MEMBER_UPDATE_TOC.fields = {M_FAMILY_MEMBER_UPDATE_TOC_MEMBER_FIELD, M_FAMILY_MEMBER_UPDATE_TOC_DEL_MEMBER_ID_FIELD}
M_FAMILY_MEMBER_UPDATE_TOC.is_extendable = false
M_FAMILY_MEMBER_UPDATE_TOC.extensions = {}

m_family_member_update_toc = protobuf.Message(M_FAMILY_MEMBER_UPDATE_TOC)

