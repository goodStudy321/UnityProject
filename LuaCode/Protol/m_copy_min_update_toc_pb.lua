--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_copy_min_update_toc_pb')

M_COPY_MIN_UPDATE_TOC = protobuf.Descriptor();
M_COPY_MIN_UPDATE_TOC_ILLUSION_FIELD = protobuf.FieldDescriptor();
M_COPY_MIN_UPDATE_TOC_NAT_INTENSIFY_FIELD = protobuf.FieldDescriptor();

M_COPY_MIN_UPDATE_TOC_ILLUSION_FIELD.name = "illusion"
M_COPY_MIN_UPDATE_TOC_ILLUSION_FIELD.full_name = ".m_copy_min_update_toc.illusion"
M_COPY_MIN_UPDATE_TOC_ILLUSION_FIELD.number = 1
M_COPY_MIN_UPDATE_TOC_ILLUSION_FIELD.index = 0
M_COPY_MIN_UPDATE_TOC_ILLUSION_FIELD.label = 1
M_COPY_MIN_UPDATE_TOC_ILLUSION_FIELD.has_default_value = true
M_COPY_MIN_UPDATE_TOC_ILLUSION_FIELD.default_value = 0
M_COPY_MIN_UPDATE_TOC_ILLUSION_FIELD.type = 5
M_COPY_MIN_UPDATE_TOC_ILLUSION_FIELD.cpp_type = 1

M_COPY_MIN_UPDATE_TOC_NAT_INTENSIFY_FIELD.name = "nat_intensify"
M_COPY_MIN_UPDATE_TOC_NAT_INTENSIFY_FIELD.full_name = ".m_copy_min_update_toc.nat_intensify"
M_COPY_MIN_UPDATE_TOC_NAT_INTENSIFY_FIELD.number = 2
M_COPY_MIN_UPDATE_TOC_NAT_INTENSIFY_FIELD.index = 1
M_COPY_MIN_UPDATE_TOC_NAT_INTENSIFY_FIELD.label = 1
M_COPY_MIN_UPDATE_TOC_NAT_INTENSIFY_FIELD.has_default_value = true
M_COPY_MIN_UPDATE_TOC_NAT_INTENSIFY_FIELD.default_value = 0
M_COPY_MIN_UPDATE_TOC_NAT_INTENSIFY_FIELD.type = 5
M_COPY_MIN_UPDATE_TOC_NAT_INTENSIFY_FIELD.cpp_type = 1

M_COPY_MIN_UPDATE_TOC.name = "m_copy_min_update_toc"
M_COPY_MIN_UPDATE_TOC.full_name = ".m_copy_min_update_toc"
M_COPY_MIN_UPDATE_TOC.nested_types = {}
M_COPY_MIN_UPDATE_TOC.enum_types = {}
M_COPY_MIN_UPDATE_TOC.fields = {M_COPY_MIN_UPDATE_TOC_ILLUSION_FIELD, M_COPY_MIN_UPDATE_TOC_NAT_INTENSIFY_FIELD}
M_COPY_MIN_UPDATE_TOC.is_extendable = false
M_COPY_MIN_UPDATE_TOC.extensions = {}

m_copy_min_update_toc = protobuf.Message(M_COPY_MIN_UPDATE_TOC)
