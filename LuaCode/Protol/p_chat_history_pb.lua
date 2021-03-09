--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
local p_chat_role_pb = require("Protol.p_chat_role_pb")
local p_goods_pb = require("Protol.p_goods_pb")
module('Protol.p_chat_history_pb')

P_CHAT_HISTORY = protobuf.Descriptor();
P_CHAT_HISTORY_CHANNEL_TYPE_FIELD = protobuf.FieldDescriptor();
P_CHAT_HISTORY_CHANNEL_ID_FIELD = protobuf.FieldDescriptor();
P_CHAT_HISTORY_ROLE_INFO_FIELD = protobuf.FieldDescriptor();
P_CHAT_HISTORY_VOICE_SEC_FIELD = protobuf.FieldDescriptor();
P_CHAT_HISTORY_MSG_FIELD = protobuf.FieldDescriptor();
P_CHAT_HISTORY_GOODS_LIST_FIELD = protobuf.FieldDescriptor();
P_CHAT_HISTORY_TIME_FIELD = protobuf.FieldDescriptor();
P_CHAT_HISTORY_VOICE_URL_FIELD = protobuf.FieldDescriptor();

P_CHAT_HISTORY_CHANNEL_TYPE_FIELD.name = "channel_type"
P_CHAT_HISTORY_CHANNEL_TYPE_FIELD.full_name = ".p_chat_history.channel_type"
P_CHAT_HISTORY_CHANNEL_TYPE_FIELD.number = 1
P_CHAT_HISTORY_CHANNEL_TYPE_FIELD.index = 0
P_CHAT_HISTORY_CHANNEL_TYPE_FIELD.label = 1
P_CHAT_HISTORY_CHANNEL_TYPE_FIELD.has_default_value = true
P_CHAT_HISTORY_CHANNEL_TYPE_FIELD.default_value = 0
P_CHAT_HISTORY_CHANNEL_TYPE_FIELD.type = 5
P_CHAT_HISTORY_CHANNEL_TYPE_FIELD.cpp_type = 1

P_CHAT_HISTORY_CHANNEL_ID_FIELD.name = "channel_id"
P_CHAT_HISTORY_CHANNEL_ID_FIELD.full_name = ".p_chat_history.channel_id"
P_CHAT_HISTORY_CHANNEL_ID_FIELD.number = 2
P_CHAT_HISTORY_CHANNEL_ID_FIELD.index = 1
P_CHAT_HISTORY_CHANNEL_ID_FIELD.label = 1
P_CHAT_HISTORY_CHANNEL_ID_FIELD.has_default_value = true
P_CHAT_HISTORY_CHANNEL_ID_FIELD.default_value = 0
P_CHAT_HISTORY_CHANNEL_ID_FIELD.type = 3
P_CHAT_HISTORY_CHANNEL_ID_FIELD.cpp_type = 2

P_CHAT_HISTORY_ROLE_INFO_FIELD.name = "role_info"
P_CHAT_HISTORY_ROLE_INFO_FIELD.full_name = ".p_chat_history.role_info"
P_CHAT_HISTORY_ROLE_INFO_FIELD.number = 3
P_CHAT_HISTORY_ROLE_INFO_FIELD.index = 2
P_CHAT_HISTORY_ROLE_INFO_FIELD.label = 1
P_CHAT_HISTORY_ROLE_INFO_FIELD.has_default_value = false
P_CHAT_HISTORY_ROLE_INFO_FIELD.default_value = nil
P_CHAT_HISTORY_ROLE_INFO_FIELD.message_type = p_chat_role_pb.P_CHAT_ROLE
P_CHAT_HISTORY_ROLE_INFO_FIELD.type = 11
P_CHAT_HISTORY_ROLE_INFO_FIELD.cpp_type = 10

P_CHAT_HISTORY_VOICE_SEC_FIELD.name = "voice_sec"
P_CHAT_HISTORY_VOICE_SEC_FIELD.full_name = ".p_chat_history.voice_sec"
P_CHAT_HISTORY_VOICE_SEC_FIELD.number = 4
P_CHAT_HISTORY_VOICE_SEC_FIELD.index = 3
P_CHAT_HISTORY_VOICE_SEC_FIELD.label = 1
P_CHAT_HISTORY_VOICE_SEC_FIELD.has_default_value = true
P_CHAT_HISTORY_VOICE_SEC_FIELD.default_value = 0
P_CHAT_HISTORY_VOICE_SEC_FIELD.type = 5
P_CHAT_HISTORY_VOICE_SEC_FIELD.cpp_type = 1

P_CHAT_HISTORY_MSG_FIELD.name = "msg"
P_CHAT_HISTORY_MSG_FIELD.full_name = ".p_chat_history.msg"
P_CHAT_HISTORY_MSG_FIELD.number = 5
P_CHAT_HISTORY_MSG_FIELD.index = 4
P_CHAT_HISTORY_MSG_FIELD.label = 1
P_CHAT_HISTORY_MSG_FIELD.has_default_value = false
P_CHAT_HISTORY_MSG_FIELD.default_value = ""
P_CHAT_HISTORY_MSG_FIELD.type = 9
P_CHAT_HISTORY_MSG_FIELD.cpp_type = 9

P_CHAT_HISTORY_GOODS_LIST_FIELD.name = "goods_list"
P_CHAT_HISTORY_GOODS_LIST_FIELD.full_name = ".p_chat_history.goods_list"
P_CHAT_HISTORY_GOODS_LIST_FIELD.number = 6
P_CHAT_HISTORY_GOODS_LIST_FIELD.index = 5
P_CHAT_HISTORY_GOODS_LIST_FIELD.label = 3
P_CHAT_HISTORY_GOODS_LIST_FIELD.has_default_value = false
P_CHAT_HISTORY_GOODS_LIST_FIELD.default_value = {}
P_CHAT_HISTORY_GOODS_LIST_FIELD.message_type = p_goods_pb.P_GOODS
P_CHAT_HISTORY_GOODS_LIST_FIELD.type = 11
P_CHAT_HISTORY_GOODS_LIST_FIELD.cpp_type = 10

P_CHAT_HISTORY_TIME_FIELD.name = "time"
P_CHAT_HISTORY_TIME_FIELD.full_name = ".p_chat_history.time"
P_CHAT_HISTORY_TIME_FIELD.number = 7
P_CHAT_HISTORY_TIME_FIELD.index = 6
P_CHAT_HISTORY_TIME_FIELD.label = 1
P_CHAT_HISTORY_TIME_FIELD.has_default_value = true
P_CHAT_HISTORY_TIME_FIELD.default_value = 0
P_CHAT_HISTORY_TIME_FIELD.type = 5
P_CHAT_HISTORY_TIME_FIELD.cpp_type = 1

P_CHAT_HISTORY_VOICE_URL_FIELD.name = "voice_url"
P_CHAT_HISTORY_VOICE_URL_FIELD.full_name = ".p_chat_history.voice_url"
P_CHAT_HISTORY_VOICE_URL_FIELD.number = 8
P_CHAT_HISTORY_VOICE_URL_FIELD.index = 7
P_CHAT_HISTORY_VOICE_URL_FIELD.label = 1
P_CHAT_HISTORY_VOICE_URL_FIELD.has_default_value = false
P_CHAT_HISTORY_VOICE_URL_FIELD.default_value = ""
P_CHAT_HISTORY_VOICE_URL_FIELD.type = 9
P_CHAT_HISTORY_VOICE_URL_FIELD.cpp_type = 9

P_CHAT_HISTORY.name = "p_chat_history"
P_CHAT_HISTORY.full_name = ".p_chat_history"
P_CHAT_HISTORY.nested_types = {}
P_CHAT_HISTORY.enum_types = {}
P_CHAT_HISTORY.fields = {P_CHAT_HISTORY_CHANNEL_TYPE_FIELD, P_CHAT_HISTORY_CHANNEL_ID_FIELD, P_CHAT_HISTORY_ROLE_INFO_FIELD, P_CHAT_HISTORY_VOICE_SEC_FIELD, P_CHAT_HISTORY_MSG_FIELD, P_CHAT_HISTORY_GOODS_LIST_FIELD, P_CHAT_HISTORY_TIME_FIELD, P_CHAT_HISTORY_VOICE_URL_FIELD}
P_CHAT_HISTORY.is_extendable = false
P_CHAT_HISTORY.extensions = {}

p_chat_history = protobuf.Message(P_CHAT_HISTORY)

