--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_rune_pb = require("Protol.p_rune_pb")
module('Protol.m_rune_level_up_toc_pb')

M_RUNE_LEVEL_UP_TOC = protobuf.Descriptor();
M_RUNE_LEVEL_UP_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_RUNE_LEVEL_UP_TOC_RUNE_FIELD = protobuf.FieldDescriptor();

M_RUNE_LEVEL_UP_TOC_ERR_CODE_FIELD.name = "err_code"
M_RUNE_LEVEL_UP_TOC_ERR_CODE_FIELD.full_name = ".m_rune_level_up_toc.err_code"
M_RUNE_LEVEL_UP_TOC_ERR_CODE_FIELD.number = 1
M_RUNE_LEVEL_UP_TOC_ERR_CODE_FIELD.index = 0
M_RUNE_LEVEL_UP_TOC_ERR_CODE_FIELD.label = 1
M_RUNE_LEVEL_UP_TOC_ERR_CODE_FIELD.has_default_value = true
M_RUNE_LEVEL_UP_TOC_ERR_CODE_FIELD.default_value = 0
M_RUNE_LEVEL_UP_TOC_ERR_CODE_FIELD.type = 5
M_RUNE_LEVEL_UP_TOC_ERR_CODE_FIELD.cpp_type = 1

M_RUNE_LEVEL_UP_TOC_RUNE_FIELD.name = "rune"
M_RUNE_LEVEL_UP_TOC_RUNE_FIELD.full_name = ".m_rune_level_up_toc.rune"
M_RUNE_LEVEL_UP_TOC_RUNE_FIELD.number = 2
M_RUNE_LEVEL_UP_TOC_RUNE_FIELD.index = 1
M_RUNE_LEVEL_UP_TOC_RUNE_FIELD.label = 1
M_RUNE_LEVEL_UP_TOC_RUNE_FIELD.has_default_value = false
M_RUNE_LEVEL_UP_TOC_RUNE_FIELD.default_value = nil
M_RUNE_LEVEL_UP_TOC_RUNE_FIELD.message_type = p_rune_pb.P_RUNE
M_RUNE_LEVEL_UP_TOC_RUNE_FIELD.type = 11
M_RUNE_LEVEL_UP_TOC_RUNE_FIELD.cpp_type = 10

M_RUNE_LEVEL_UP_TOC.name = "m_rune_level_up_toc"
M_RUNE_LEVEL_UP_TOC.full_name = ".m_rune_level_up_toc"
M_RUNE_LEVEL_UP_TOC.nested_types = {}
M_RUNE_LEVEL_UP_TOC.enum_types = {}
M_RUNE_LEVEL_UP_TOC.fields = {M_RUNE_LEVEL_UP_TOC_ERR_CODE_FIELD, M_RUNE_LEVEL_UP_TOC_RUNE_FIELD}
M_RUNE_LEVEL_UP_TOC.is_extendable = false
M_RUNE_LEVEL_UP_TOC.extensions = {}

m_rune_level_up_toc = protobuf.Message(M_RUNE_LEVEL_UP_TOC)

