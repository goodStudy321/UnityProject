--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_chapter_reward_tos_pb')

M_CHAPTER_REWARD_TOS = protobuf.Descriptor();
M_CHAPTER_REWARD_TOS_CHAPTER_ID_FIELD = protobuf.FieldDescriptor();

M_CHAPTER_REWARD_TOS_CHAPTER_ID_FIELD.name = "chapter_id"
M_CHAPTER_REWARD_TOS_CHAPTER_ID_FIELD.full_name = ".m_chapter_reward_tos.chapter_id"
M_CHAPTER_REWARD_TOS_CHAPTER_ID_FIELD.number = 1
M_CHAPTER_REWARD_TOS_CHAPTER_ID_FIELD.index = 0
M_CHAPTER_REWARD_TOS_CHAPTER_ID_FIELD.label = 1
M_CHAPTER_REWARD_TOS_CHAPTER_ID_FIELD.has_default_value = true
M_CHAPTER_REWARD_TOS_CHAPTER_ID_FIELD.default_value = 0
M_CHAPTER_REWARD_TOS_CHAPTER_ID_FIELD.type = 5
M_CHAPTER_REWARD_TOS_CHAPTER_ID_FIELD.cpp_type = 1

M_CHAPTER_REWARD_TOS.name = "m_chapter_reward_tos"
M_CHAPTER_REWARD_TOS.full_name = ".m_chapter_reward_tos"
M_CHAPTER_REWARD_TOS.nested_types = {}
M_CHAPTER_REWARD_TOS.enum_types = {}
M_CHAPTER_REWARD_TOS.fields = {M_CHAPTER_REWARD_TOS_CHAPTER_ID_FIELD}
M_CHAPTER_REWARD_TOS.is_extendable = false
M_CHAPTER_REWARD_TOS.extensions = {}

m_chapter_reward_tos = protobuf.Message(M_CHAPTER_REWARD_TOS)

