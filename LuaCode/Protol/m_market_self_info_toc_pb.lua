--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_market_goods_pb = require("Protol.p_market_goods_pb")
module('Protol.m_market_self_info_toc_pb')

M_MARKET_SELF_INFO_TOC = protobuf.Descriptor();
M_MARKET_SELF_INFO_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_MARKET_SELF_INFO_TOC_PROHIBIT_TIME_FIELD = protobuf.FieldDescriptor();
M_MARKET_SELF_INFO_TOC_SELL_GRID_FIELD = protobuf.FieldDescriptor();
M_MARKET_SELF_INFO_TOC_DEMAND_GRID_FIELD = protobuf.FieldDescriptor();

M_MARKET_SELF_INFO_TOC_ERR_CODE_FIELD.name = "err_code"
M_MARKET_SELF_INFO_TOC_ERR_CODE_FIELD.full_name = ".m_market_self_info_toc.err_code"
M_MARKET_SELF_INFO_TOC_ERR_CODE_FIELD.number = 1
M_MARKET_SELF_INFO_TOC_ERR_CODE_FIELD.index = 0
M_MARKET_SELF_INFO_TOC_ERR_CODE_FIELD.label = 1
M_MARKET_SELF_INFO_TOC_ERR_CODE_FIELD.has_default_value = true
M_MARKET_SELF_INFO_TOC_ERR_CODE_FIELD.default_value = 0
M_MARKET_SELF_INFO_TOC_ERR_CODE_FIELD.type = 5
M_MARKET_SELF_INFO_TOC_ERR_CODE_FIELD.cpp_type = 1

M_MARKET_SELF_INFO_TOC_PROHIBIT_TIME_FIELD.name = "prohibit_time"
M_MARKET_SELF_INFO_TOC_PROHIBIT_TIME_FIELD.full_name = ".m_market_self_info_toc.prohibit_time"
M_MARKET_SELF_INFO_TOC_PROHIBIT_TIME_FIELD.number = 2
M_MARKET_SELF_INFO_TOC_PROHIBIT_TIME_FIELD.index = 1
M_MARKET_SELF_INFO_TOC_PROHIBIT_TIME_FIELD.label = 1
M_MARKET_SELF_INFO_TOC_PROHIBIT_TIME_FIELD.has_default_value = true
M_MARKET_SELF_INFO_TOC_PROHIBIT_TIME_FIELD.default_value = 0
M_MARKET_SELF_INFO_TOC_PROHIBIT_TIME_FIELD.type = 5
M_MARKET_SELF_INFO_TOC_PROHIBIT_TIME_FIELD.cpp_type = 1

M_MARKET_SELF_INFO_TOC_SELL_GRID_FIELD.name = "sell_grid"
M_MARKET_SELF_INFO_TOC_SELL_GRID_FIELD.full_name = ".m_market_self_info_toc.sell_grid"
M_MARKET_SELF_INFO_TOC_SELL_GRID_FIELD.number = 3
M_MARKET_SELF_INFO_TOC_SELL_GRID_FIELD.index = 2
M_MARKET_SELF_INFO_TOC_SELL_GRID_FIELD.label = 3
M_MARKET_SELF_INFO_TOC_SELL_GRID_FIELD.has_default_value = false
M_MARKET_SELF_INFO_TOC_SELL_GRID_FIELD.default_value = {}
M_MARKET_SELF_INFO_TOC_SELL_GRID_FIELD.message_type = p_market_goods_pb.P_MARKET_GOODS
M_MARKET_SELF_INFO_TOC_SELL_GRID_FIELD.type = 11
M_MARKET_SELF_INFO_TOC_SELL_GRID_FIELD.cpp_type = 10

M_MARKET_SELF_INFO_TOC_DEMAND_GRID_FIELD.name = "demand_grid"
M_MARKET_SELF_INFO_TOC_DEMAND_GRID_FIELD.full_name = ".m_market_self_info_toc.demand_grid"
M_MARKET_SELF_INFO_TOC_DEMAND_GRID_FIELD.number = 4
M_MARKET_SELF_INFO_TOC_DEMAND_GRID_FIELD.index = 3
M_MARKET_SELF_INFO_TOC_DEMAND_GRID_FIELD.label = 3
M_MARKET_SELF_INFO_TOC_DEMAND_GRID_FIELD.has_default_value = false
M_MARKET_SELF_INFO_TOC_DEMAND_GRID_FIELD.default_value = {}
M_MARKET_SELF_INFO_TOC_DEMAND_GRID_FIELD.message_type = p_market_goods_pb.P_MARKET_GOODS
M_MARKET_SELF_INFO_TOC_DEMAND_GRID_FIELD.type = 11
M_MARKET_SELF_INFO_TOC_DEMAND_GRID_FIELD.cpp_type = 10

M_MARKET_SELF_INFO_TOC.name = "m_market_self_info_toc"
M_MARKET_SELF_INFO_TOC.full_name = ".m_market_self_info_toc"
M_MARKET_SELF_INFO_TOC.nested_types = {}
M_MARKET_SELF_INFO_TOC.enum_types = {}
M_MARKET_SELF_INFO_TOC.fields = {M_MARKET_SELF_INFO_TOC_ERR_CODE_FIELD, M_MARKET_SELF_INFO_TOC_PROHIBIT_TIME_FIELD, M_MARKET_SELF_INFO_TOC_SELL_GRID_FIELD, M_MARKET_SELF_INFO_TOC_DEMAND_GRID_FIELD}
M_MARKET_SELF_INFO_TOC.is_extendable = false
M_MARKET_SELF_INFO_TOC.extensions = {}

m_market_self_info_toc = protobuf.Message(M_MARKET_SELF_INFO_TOC)
