--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_bag_depot_toc_pb')

M_BAG_DEPOT_TOC = protobuf.Descriptor();
M_BAG_DEPOT_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();

M_BAG_DEPOT_TOC_ERR_CODE_FIELD.name = "err_code"
M_BAG_DEPOT_TOC_ERR_CODE_FIELD.full_name = ".m_bag_depot_toc.err_code"
M_BAG_DEPOT_TOC_ERR_CODE_FIELD.number = 1
M_BAG_DEPOT_TOC_ERR_CODE_FIELD.index = 0
M_BAG_DEPOT_TOC_ERR_CODE_FIELD.label = 1
M_BAG_DEPOT_TOC_ERR_CODE_FIELD.has_default_value = true
M_BAG_DEPOT_TOC_ERR_CODE_FIELD.default_value = 0
M_BAG_DEPOT_TOC_ERR_CODE_FIELD.type = 5
M_BAG_DEPOT_TOC_ERR_CODE_FIELD.cpp_type = 1

M_BAG_DEPOT_TOC.name = "m_bag_depot_toc"
M_BAG_DEPOT_TOC.full_name = ".m_bag_depot_toc"
M_BAG_DEPOT_TOC.nested_types = {}
M_BAG_DEPOT_TOC.enum_types = {}
M_BAG_DEPOT_TOC.fields = {M_BAG_DEPOT_TOC_ERR_CODE_FIELD}
M_BAG_DEPOT_TOC.is_extendable = false
M_BAG_DEPOT_TOC.extensions = {}

m_bag_depot_toc = protobuf.Message(M_BAG_DEPOT_TOC)

