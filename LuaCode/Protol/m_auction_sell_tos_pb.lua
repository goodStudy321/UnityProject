--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_kv_pb = require("Protol.p_kv_pb")
module('Protol.m_auction_sell_tos_pb')

M_AUCTION_SELL_TOS = protobuf.Descriptor();
M_AUCTION_SELL_TOS_SELL_GOODS_FIELD = protobuf.FieldDescriptor();

M_AUCTION_SELL_TOS_SELL_GOODS_FIELD.name = "sell_goods"
M_AUCTION_SELL_TOS_SELL_GOODS_FIELD.full_name = ".m_auction_sell_tos.sell_goods"
M_AUCTION_SELL_TOS_SELL_GOODS_FIELD.number = 1
M_AUCTION_SELL_TOS_SELL_GOODS_FIELD.index = 0
M_AUCTION_SELL_TOS_SELL_GOODS_FIELD.label = 3
M_AUCTION_SELL_TOS_SELL_GOODS_FIELD.has_default_value = false
M_AUCTION_SELL_TOS_SELL_GOODS_FIELD.default_value = {}
M_AUCTION_SELL_TOS_SELL_GOODS_FIELD.message_type = p_kv_pb.P_KV
M_AUCTION_SELL_TOS_SELL_GOODS_FIELD.type = 11
M_AUCTION_SELL_TOS_SELL_GOODS_FIELD.cpp_type = 10

M_AUCTION_SELL_TOS.name = "m_auction_sell_tos"
M_AUCTION_SELL_TOS.full_name = ".m_auction_sell_tos"
M_AUCTION_SELL_TOS.nested_types = {}
M_AUCTION_SELL_TOS.enum_types = {}
M_AUCTION_SELL_TOS.fields = {M_AUCTION_SELL_TOS_SELL_GOODS_FIELD}
M_AUCTION_SELL_TOS.is_extendable = false
M_AUCTION_SELL_TOS.extensions = {}

m_auction_sell_tos = protobuf.Message(M_AUCTION_SELL_TOS)
