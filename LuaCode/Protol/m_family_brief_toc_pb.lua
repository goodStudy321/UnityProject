--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_family_brief_pb = require("Protol.p_family_brief_pb")
module('Protol.m_family_brief_toc_pb')

M_FAMILY_BRIEF_TOC = protobuf.Descriptor();
M_FAMILY_BRIEF_TOC_BRIEFS_FIELD = protobuf.FieldDescriptor();
M_FAMILY_BRIEF_TOC_ALL_NUM_FIELD = protobuf.FieldDescriptor();

M_FAMILY_BRIEF_TOC_BRIEFS_FIELD.name = "briefs"
M_FAMILY_BRIEF_TOC_BRIEFS_FIELD.full_name = ".m_family_brief_toc.briefs"
M_FAMILY_BRIEF_TOC_BRIEFS_FIELD.number = 1
M_FAMILY_BRIEF_TOC_BRIEFS_FIELD.index = 0
M_FAMILY_BRIEF_TOC_BRIEFS_FIELD.label = 3
M_FAMILY_BRIEF_TOC_BRIEFS_FIELD.has_default_value = false
M_FAMILY_BRIEF_TOC_BRIEFS_FIELD.default_value = {}
M_FAMILY_BRIEF_TOC_BRIEFS_FIELD.message_type = p_family_brief_pb.P_FAMILY_BRIEF
M_FAMILY_BRIEF_TOC_BRIEFS_FIELD.type = 11
M_FAMILY_BRIEF_TOC_BRIEFS_FIELD.cpp_type = 10

M_FAMILY_BRIEF_TOC_ALL_NUM_FIELD.name = "all_num"
M_FAMILY_BRIEF_TOC_ALL_NUM_FIELD.full_name = ".m_family_brief_toc.all_num"
M_FAMILY_BRIEF_TOC_ALL_NUM_FIELD.number = 2
M_FAMILY_BRIEF_TOC_ALL_NUM_FIELD.index = 1
M_FAMILY_BRIEF_TOC_ALL_NUM_FIELD.label = 1
M_FAMILY_BRIEF_TOC_ALL_NUM_FIELD.has_default_value = true
M_FAMILY_BRIEF_TOC_ALL_NUM_FIELD.default_value = 0
M_FAMILY_BRIEF_TOC_ALL_NUM_FIELD.type = 5
M_FAMILY_BRIEF_TOC_ALL_NUM_FIELD.cpp_type = 1

M_FAMILY_BRIEF_TOC.name = "m_family_brief_toc"
M_FAMILY_BRIEF_TOC.full_name = ".m_family_brief_toc"
M_FAMILY_BRIEF_TOC.nested_types = {}
M_FAMILY_BRIEF_TOC.enum_types = {}
M_FAMILY_BRIEF_TOC.fields = {M_FAMILY_BRIEF_TOC_BRIEFS_FIELD, M_FAMILY_BRIEF_TOC_ALL_NUM_FIELD}
M_FAMILY_BRIEF_TOC.is_extendable = false
M_FAMILY_BRIEF_TOC.extensions = {}

m_family_brief_toc = protobuf.Message(M_FAMILY_BRIEF_TOC)

