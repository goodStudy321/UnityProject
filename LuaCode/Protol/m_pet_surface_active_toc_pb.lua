--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_kv_pb = require("Protol.p_kv_pb")
module('Protol.m_pet_surface_active_toc_pb')

M_PET_SURFACE_ACTIVE_TOC = protobuf.Descriptor();
M_PET_SURFACE_ACTIVE_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_PET_SURFACE_ACTIVE_TOC_SURFACE_FIELD = protobuf.FieldDescriptor();

M_PET_SURFACE_ACTIVE_TOC_ERR_CODE_FIELD.name = "err_code"
M_PET_SURFACE_ACTIVE_TOC_ERR_CODE_FIELD.full_name = ".m_pet_surface_active_toc.err_code"
M_PET_SURFACE_ACTIVE_TOC_ERR_CODE_FIELD.number = 1
M_PET_SURFACE_ACTIVE_TOC_ERR_CODE_FIELD.index = 0
M_PET_SURFACE_ACTIVE_TOC_ERR_CODE_FIELD.label = 1
M_PET_SURFACE_ACTIVE_TOC_ERR_CODE_FIELD.has_default_value = true
M_PET_SURFACE_ACTIVE_TOC_ERR_CODE_FIELD.default_value = 0
M_PET_SURFACE_ACTIVE_TOC_ERR_CODE_FIELD.type = 5
M_PET_SURFACE_ACTIVE_TOC_ERR_CODE_FIELD.cpp_type = 1

M_PET_SURFACE_ACTIVE_TOC_SURFACE_FIELD.name = "surface"
M_PET_SURFACE_ACTIVE_TOC_SURFACE_FIELD.full_name = ".m_pet_surface_active_toc.surface"
M_PET_SURFACE_ACTIVE_TOC_SURFACE_FIELD.number = 2
M_PET_SURFACE_ACTIVE_TOC_SURFACE_FIELD.index = 1
M_PET_SURFACE_ACTIVE_TOC_SURFACE_FIELD.label = 1
M_PET_SURFACE_ACTIVE_TOC_SURFACE_FIELD.has_default_value = false
M_PET_SURFACE_ACTIVE_TOC_SURFACE_FIELD.default_value = nil
M_PET_SURFACE_ACTIVE_TOC_SURFACE_FIELD.message_type = p_kv_pb.P_KV
M_PET_SURFACE_ACTIVE_TOC_SURFACE_FIELD.type = 11
M_PET_SURFACE_ACTIVE_TOC_SURFACE_FIELD.cpp_type = 10

M_PET_SURFACE_ACTIVE_TOC.name = "m_pet_surface_active_toc"
M_PET_SURFACE_ACTIVE_TOC.full_name = ".m_pet_surface_active_toc"
M_PET_SURFACE_ACTIVE_TOC.nested_types = {}
M_PET_SURFACE_ACTIVE_TOC.enum_types = {}
M_PET_SURFACE_ACTIVE_TOC.fields = {M_PET_SURFACE_ACTIVE_TOC_ERR_CODE_FIELD, M_PET_SURFACE_ACTIVE_TOC_SURFACE_FIELD}
M_PET_SURFACE_ACTIVE_TOC.is_extendable = false
M_PET_SURFACE_ACTIVE_TOC.extensions = {}

m_pet_surface_active_toc = protobuf.Message(M_PET_SURFACE_ACTIVE_TOC)

