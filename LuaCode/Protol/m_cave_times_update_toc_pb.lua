--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_cave_times_update_toc_pb')

M_CAVE_TIMES_UPDATE_TOC = protobuf.Descriptor();
M_CAVE_TIMES_UPDATE_TOC_CAVE_TIMES_FIELD = protobuf.FieldDescriptor();
M_CAVE_TIMES_UPDATE_TOC_CAVE_ASSIST_TIMES_FIELD = protobuf.FieldDescriptor();

M_CAVE_TIMES_UPDATE_TOC_CAVE_TIMES_FIELD.name = "cave_times"
M_CAVE_TIMES_UPDATE_TOC_CAVE_TIMES_FIELD.full_name = ".m_cave_times_update_toc.cave_times"
M_CAVE_TIMES_UPDATE_TOC_CAVE_TIMES_FIELD.number = 1
M_CAVE_TIMES_UPDATE_TOC_CAVE_TIMES_FIELD.index = 0
M_CAVE_TIMES_UPDATE_TOC_CAVE_TIMES_FIELD.label = 1
M_CAVE_TIMES_UPDATE_TOC_CAVE_TIMES_FIELD.has_default_value = true
M_CAVE_TIMES_UPDATE_TOC_CAVE_TIMES_FIELD.default_value = 0
M_CAVE_TIMES_UPDATE_TOC_CAVE_TIMES_FIELD.type = 5
M_CAVE_TIMES_UPDATE_TOC_CAVE_TIMES_FIELD.cpp_type = 1

M_CAVE_TIMES_UPDATE_TOC_CAVE_ASSIST_TIMES_FIELD.name = "cave_assist_times"
M_CAVE_TIMES_UPDATE_TOC_CAVE_ASSIST_TIMES_FIELD.full_name = ".m_cave_times_update_toc.cave_assist_times"
M_CAVE_TIMES_UPDATE_TOC_CAVE_ASSIST_TIMES_FIELD.number = 2
M_CAVE_TIMES_UPDATE_TOC_CAVE_ASSIST_TIMES_FIELD.index = 1
M_CAVE_TIMES_UPDATE_TOC_CAVE_ASSIST_TIMES_FIELD.label = 1
M_CAVE_TIMES_UPDATE_TOC_CAVE_ASSIST_TIMES_FIELD.has_default_value = true
M_CAVE_TIMES_UPDATE_TOC_CAVE_ASSIST_TIMES_FIELD.default_value = 0
M_CAVE_TIMES_UPDATE_TOC_CAVE_ASSIST_TIMES_FIELD.type = 5
M_CAVE_TIMES_UPDATE_TOC_CAVE_ASSIST_TIMES_FIELD.cpp_type = 1

M_CAVE_TIMES_UPDATE_TOC.name = "m_cave_times_update_toc"
M_CAVE_TIMES_UPDATE_TOC.full_name = ".m_cave_times_update_toc"
M_CAVE_TIMES_UPDATE_TOC.nested_types = {}
M_CAVE_TIMES_UPDATE_TOC.enum_types = {}
M_CAVE_TIMES_UPDATE_TOC.fields = {M_CAVE_TIMES_UPDATE_TOC_CAVE_TIMES_FIELD, M_CAVE_TIMES_UPDATE_TOC_CAVE_ASSIST_TIMES_FIELD}
M_CAVE_TIMES_UPDATE_TOC.is_extendable = false
M_CAVE_TIMES_UPDATE_TOC.extensions = {}

m_cave_times_update_toc = protobuf.Message(M_CAVE_TIMES_UPDATE_TOC)

