--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_dkv_pb = require("Protol.p_dkv_pb")
module('Protol.m_role_asset_change_toc_pb')

M_ROLE_ASSET_CHANGE_TOC = protobuf.Descriptor();
M_ROLE_ASSET_CHANGE_TOC_CHANGE_LIST_FIELD = protobuf.FieldDescriptor();

M_ROLE_ASSET_CHANGE_TOC_CHANGE_LIST_FIELD.name = "change_list"
M_ROLE_ASSET_CHANGE_TOC_CHANGE_LIST_FIELD.full_name = ".m_role_asset_change_toc.change_list"
M_ROLE_ASSET_CHANGE_TOC_CHANGE_LIST_FIELD.number = 1
M_ROLE_ASSET_CHANGE_TOC_CHANGE_LIST_FIELD.index = 0
M_ROLE_ASSET_CHANGE_TOC_CHANGE_LIST_FIELD.label = 3
M_ROLE_ASSET_CHANGE_TOC_CHANGE_LIST_FIELD.has_default_value = false
M_ROLE_ASSET_CHANGE_TOC_CHANGE_LIST_FIELD.default_value = {}
M_ROLE_ASSET_CHANGE_TOC_CHANGE_LIST_FIELD.message_type = p_dkv_pb.P_DKV
M_ROLE_ASSET_CHANGE_TOC_CHANGE_LIST_FIELD.type = 11
M_ROLE_ASSET_CHANGE_TOC_CHANGE_LIST_FIELD.cpp_type = 10

M_ROLE_ASSET_CHANGE_TOC.name = "m_role_asset_change_toc"
M_ROLE_ASSET_CHANGE_TOC.full_name = ".m_role_asset_change_toc"
M_ROLE_ASSET_CHANGE_TOC.nested_types = {}
M_ROLE_ASSET_CHANGE_TOC.enum_types = {}
M_ROLE_ASSET_CHANGE_TOC.fields = {M_ROLE_ASSET_CHANGE_TOC_CHANGE_LIST_FIELD}
M_ROLE_ASSET_CHANGE_TOC.is_extendable = false
M_ROLE_ASSET_CHANGE_TOC.extensions = {}

m_role_asset_change_toc = protobuf.Message(M_ROLE_ASSET_CHANGE_TOC)
