--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_auction_detail_tos_pb')

M_AUCTION_DETAIL_TOS = protobuf.Descriptor();
M_AUCTION_DETAIL_TOS_CLASS_FIELD = protobuf.FieldDescriptor();
M_AUCTION_DETAIL_TOS_QUALITY_FIELD = protobuf.FieldDescriptor();
M_AUCTION_DETAIL_TOS_STEP_FIELD = protobuf.FieldDescriptor();

M_AUCTION_DETAIL_TOS_CLASS_FIELD.name = "class"
M_AUCTION_DETAIL_TOS_CLASS_FIELD.full_name = ".m_auction_detail_tos.class"
M_AUCTION_DETAIL_TOS_CLASS_FIELD.number = 1
M_AUCTION_DETAIL_TOS_CLASS_FIELD.index = 0
M_AUCTION_DETAIL_TOS_CLASS_FIELD.label = 1
M_AUCTION_DETAIL_TOS_CLASS_FIELD.has_default_value = true
M_AUCTION_DETAIL_TOS_CLASS_FIELD.default_value = 0
M_AUCTION_DETAIL_TOS_CLASS_FIELD.type = 5
M_AUCTION_DETAIL_TOS_CLASS_FIELD.cpp_type = 1

M_AUCTION_DETAIL_TOS_QUALITY_FIELD.name = "quality"
M_AUCTION_DETAIL_TOS_QUALITY_FIELD.full_name = ".m_auction_detail_tos.quality"
M_AUCTION_DETAIL_TOS_QUALITY_FIELD.number = 2
M_AUCTION_DETAIL_TOS_QUALITY_FIELD.index = 1
M_AUCTION_DETAIL_TOS_QUALITY_FIELD.label = 1
M_AUCTION_DETAIL_TOS_QUALITY_FIELD.has_default_value = true
M_AUCTION_DETAIL_TOS_QUALITY_FIELD.default_value = 0
M_AUCTION_DETAIL_TOS_QUALITY_FIELD.type = 3
M_AUCTION_DETAIL_TOS_QUALITY_FIELD.cpp_type = 2

M_AUCTION_DETAIL_TOS_STEP_FIELD.name = "step"
M_AUCTION_DETAIL_TOS_STEP_FIELD.full_name = ".m_auction_detail_tos.step"
M_AUCTION_DETAIL_TOS_STEP_FIELD.number = 3
M_AUCTION_DETAIL_TOS_STEP_FIELD.index = 2
M_AUCTION_DETAIL_TOS_STEP_FIELD.label = 1
M_AUCTION_DETAIL_TOS_STEP_FIELD.has_default_value = true
M_AUCTION_DETAIL_TOS_STEP_FIELD.default_value = 0
M_AUCTION_DETAIL_TOS_STEP_FIELD.type = 5
M_AUCTION_DETAIL_TOS_STEP_FIELD.cpp_type = 1

M_AUCTION_DETAIL_TOS.name = "m_auction_detail_tos"
M_AUCTION_DETAIL_TOS.full_name = ".m_auction_detail_tos"
M_AUCTION_DETAIL_TOS.nested_types = {}
M_AUCTION_DETAIL_TOS.enum_types = {}
M_AUCTION_DETAIL_TOS.fields = {M_AUCTION_DETAIL_TOS_CLASS_FIELD, M_AUCTION_DETAIL_TOS_QUALITY_FIELD, M_AUCTION_DETAIL_TOS_STEP_FIELD}
M_AUCTION_DETAIL_TOS.is_extendable = false
M_AUCTION_DETAIL_TOS.extensions = {}

m_auction_detail_tos = protobuf.Message(M_AUCTION_DETAIL_TOS)

