--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_summit_tower_rank_pb = require("Protol.p_summit_tower_rank_pb")
module('Protol.m_summit_tower_rank_toc_pb')

M_SUMMIT_TOWER_RANK_TOC = protobuf.Descriptor();
M_SUMMIT_TOWER_RANK_TOC_RANKS_FIELD = protobuf.FieldDescriptor();
M_SUMMIT_TOWER_RANK_TOC_USE_TIME_FIELD = protobuf.FieldDescriptor();

M_SUMMIT_TOWER_RANK_TOC_RANKS_FIELD.name = "ranks"
M_SUMMIT_TOWER_RANK_TOC_RANKS_FIELD.full_name = ".m_summit_tower_rank_toc.ranks"
M_SUMMIT_TOWER_RANK_TOC_RANKS_FIELD.number = 1
M_SUMMIT_TOWER_RANK_TOC_RANKS_FIELD.index = 0
M_SUMMIT_TOWER_RANK_TOC_RANKS_FIELD.label = 3
M_SUMMIT_TOWER_RANK_TOC_RANKS_FIELD.has_default_value = false
M_SUMMIT_TOWER_RANK_TOC_RANKS_FIELD.default_value = {}
M_SUMMIT_TOWER_RANK_TOC_RANKS_FIELD.message_type = p_summit_tower_rank_pb.P_SUMMIT_TOWER_RANK
M_SUMMIT_TOWER_RANK_TOC_RANKS_FIELD.type = 11
M_SUMMIT_TOWER_RANK_TOC_RANKS_FIELD.cpp_type = 10

M_SUMMIT_TOWER_RANK_TOC_USE_TIME_FIELD.name = "use_time"
M_SUMMIT_TOWER_RANK_TOC_USE_TIME_FIELD.full_name = ".m_summit_tower_rank_toc.use_time"
M_SUMMIT_TOWER_RANK_TOC_USE_TIME_FIELD.number = 2
M_SUMMIT_TOWER_RANK_TOC_USE_TIME_FIELD.index = 1
M_SUMMIT_TOWER_RANK_TOC_USE_TIME_FIELD.label = 1
M_SUMMIT_TOWER_RANK_TOC_USE_TIME_FIELD.has_default_value = true
M_SUMMIT_TOWER_RANK_TOC_USE_TIME_FIELD.default_value = 0
M_SUMMIT_TOWER_RANK_TOC_USE_TIME_FIELD.type = 5
M_SUMMIT_TOWER_RANK_TOC_USE_TIME_FIELD.cpp_type = 1

M_SUMMIT_TOWER_RANK_TOC.name = "m_summit_tower_rank_toc"
M_SUMMIT_TOWER_RANK_TOC.full_name = ".m_summit_tower_rank_toc"
M_SUMMIT_TOWER_RANK_TOC.nested_types = {}
M_SUMMIT_TOWER_RANK_TOC.enum_types = {}
M_SUMMIT_TOWER_RANK_TOC.fields = {M_SUMMIT_TOWER_RANK_TOC_RANKS_FIELD, M_SUMMIT_TOWER_RANK_TOC_USE_TIME_FIELD}
M_SUMMIT_TOWER_RANK_TOC.is_extendable = false
M_SUMMIT_TOWER_RANK_TOC.extensions = {}

m_summit_tower_rank_toc = protobuf.Message(M_SUMMIT_TOWER_RANK_TOC)

