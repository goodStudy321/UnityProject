--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_item_sell_toc_pb')

M_ITEM_SELL_TOC = protobuf.Descriptor();
M_ITEM_SELL_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();

M_ITEM_SELL_TOC_ERR_CODE_FIELD.name = "err_code"
M_ITEM_SELL_TOC_ERR_CODE_FIELD.full_name = ".m_item_sell_toc.err_code"
M_ITEM_SELL_TOC_ERR_CODE_FIELD.number = 1
M_ITEM_SELL_TOC_ERR_CODE_FIELD.index = 0
M_ITEM_SELL_TOC_ERR_CODE_FIELD.label = 1
M_ITEM_SELL_TOC_ERR_CODE_FIELD.has_default_value = true
M_ITEM_SELL_TOC_ERR_CODE_FIELD.default_value = 0
M_ITEM_SELL_TOC_ERR_CODE_FIELD.type = 5
M_ITEM_SELL_TOC_ERR_CODE_FIELD.cpp_type = 1

M_ITEM_SELL_TOC.name = "m_item_sell_toc"
M_ITEM_SELL_TOC.full_name = ".m_item_sell_toc"
M_ITEM_SELL_TOC.nested_types = {}
M_ITEM_SELL_TOC.enum_types = {}
M_ITEM_SELL_TOC.fields = {M_ITEM_SELL_TOC_ERR_CODE_FIELD}
M_ITEM_SELL_TOC.is_extendable = false
M_ITEM_SELL_TOC.extensions = {}

m_item_sell_toc = protobuf.Message(M_ITEM_SELL_TOC)

