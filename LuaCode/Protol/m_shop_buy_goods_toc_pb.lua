--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_shop_buy_goods_toc_pb')

M_SHOP_BUY_GOODS_TOC = protobuf.Descriptor();
M_SHOP_BUY_GOODS_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_SHOP_BUY_GOODS_TOC_TYPE_ID_FIELD = protobuf.FieldDescriptor();

M_SHOP_BUY_GOODS_TOC_ERR_CODE_FIELD.name = "err_code"
M_SHOP_BUY_GOODS_TOC_ERR_CODE_FIELD.full_name = ".m_shop_buy_goods_toc.err_code"
M_SHOP_BUY_GOODS_TOC_ERR_CODE_FIELD.number = 1
M_SHOP_BUY_GOODS_TOC_ERR_CODE_FIELD.index = 0
M_SHOP_BUY_GOODS_TOC_ERR_CODE_FIELD.label = 1
M_SHOP_BUY_GOODS_TOC_ERR_CODE_FIELD.has_default_value = true
M_SHOP_BUY_GOODS_TOC_ERR_CODE_FIELD.default_value = 0
M_SHOP_BUY_GOODS_TOC_ERR_CODE_FIELD.type = 5
M_SHOP_BUY_GOODS_TOC_ERR_CODE_FIELD.cpp_type = 1

M_SHOP_BUY_GOODS_TOC_TYPE_ID_FIELD.name = "type_id"
M_SHOP_BUY_GOODS_TOC_TYPE_ID_FIELD.full_name = ".m_shop_buy_goods_toc.type_id"
M_SHOP_BUY_GOODS_TOC_TYPE_ID_FIELD.number = 2
M_SHOP_BUY_GOODS_TOC_TYPE_ID_FIELD.index = 1
M_SHOP_BUY_GOODS_TOC_TYPE_ID_FIELD.label = 1
M_SHOP_BUY_GOODS_TOC_TYPE_ID_FIELD.has_default_value = true
M_SHOP_BUY_GOODS_TOC_TYPE_ID_FIELD.default_value = 0
M_SHOP_BUY_GOODS_TOC_TYPE_ID_FIELD.type = 5
M_SHOP_BUY_GOODS_TOC_TYPE_ID_FIELD.cpp_type = 1

M_SHOP_BUY_GOODS_TOC.name = "m_shop_buy_goods_toc"
M_SHOP_BUY_GOODS_TOC.full_name = ".m_shop_buy_goods_toc"
M_SHOP_BUY_GOODS_TOC.nested_types = {}
M_SHOP_BUY_GOODS_TOC.enum_types = {}
M_SHOP_BUY_GOODS_TOC.fields = {M_SHOP_BUY_GOODS_TOC_ERR_CODE_FIELD, M_SHOP_BUY_GOODS_TOC_TYPE_ID_FIELD}
M_SHOP_BUY_GOODS_TOC.is_extendable = false
M_SHOP_BUY_GOODS_TOC.extensions = {}

m_shop_buy_goods_toc = protobuf.Message(M_SHOP_BUY_GOODS_TOC)

