--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_marry_propose_reply_toc_pb')

M_MARRY_PROPOSE_REPLY_TOC = protobuf.Descriptor();
M_MARRY_PROPOSE_REPLY_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_MARRY_PROPOSE_REPLY_TOC_ANSWER_TYPE_FIELD = protobuf.FieldDescriptor();

M_MARRY_PROPOSE_REPLY_TOC_ERR_CODE_FIELD.name = "err_code"
M_MARRY_PROPOSE_REPLY_TOC_ERR_CODE_FIELD.full_name = ".m_marry_propose_reply_toc.err_code"
M_MARRY_PROPOSE_REPLY_TOC_ERR_CODE_FIELD.number = 1
M_MARRY_PROPOSE_REPLY_TOC_ERR_CODE_FIELD.index = 0
M_MARRY_PROPOSE_REPLY_TOC_ERR_CODE_FIELD.label = 1
M_MARRY_PROPOSE_REPLY_TOC_ERR_CODE_FIELD.has_default_value = true
M_MARRY_PROPOSE_REPLY_TOC_ERR_CODE_FIELD.default_value = 0
M_MARRY_PROPOSE_REPLY_TOC_ERR_CODE_FIELD.type = 5
M_MARRY_PROPOSE_REPLY_TOC_ERR_CODE_FIELD.cpp_type = 1

M_MARRY_PROPOSE_REPLY_TOC_ANSWER_TYPE_FIELD.name = "answer_type"
M_MARRY_PROPOSE_REPLY_TOC_ANSWER_TYPE_FIELD.full_name = ".m_marry_propose_reply_toc.answer_type"
M_MARRY_PROPOSE_REPLY_TOC_ANSWER_TYPE_FIELD.number = 2
M_MARRY_PROPOSE_REPLY_TOC_ANSWER_TYPE_FIELD.index = 1
M_MARRY_PROPOSE_REPLY_TOC_ANSWER_TYPE_FIELD.label = 1
M_MARRY_PROPOSE_REPLY_TOC_ANSWER_TYPE_FIELD.has_default_value = true
M_MARRY_PROPOSE_REPLY_TOC_ANSWER_TYPE_FIELD.default_value = 0
M_MARRY_PROPOSE_REPLY_TOC_ANSWER_TYPE_FIELD.type = 5
M_MARRY_PROPOSE_REPLY_TOC_ANSWER_TYPE_FIELD.cpp_type = 1

M_MARRY_PROPOSE_REPLY_TOC.name = "m_marry_propose_reply_toc"
M_MARRY_PROPOSE_REPLY_TOC.full_name = ".m_marry_propose_reply_toc"
M_MARRY_PROPOSE_REPLY_TOC.nested_types = {}
M_MARRY_PROPOSE_REPLY_TOC.enum_types = {}
M_MARRY_PROPOSE_REPLY_TOC.fields = {M_MARRY_PROPOSE_REPLY_TOC_ERR_CODE_FIELD, M_MARRY_PROPOSE_REPLY_TOC_ANSWER_TYPE_FIELD}
M_MARRY_PROPOSE_REPLY_TOC.is_extendable = false
M_MARRY_PROPOSE_REPLY_TOC.extensions = {}

m_marry_propose_reply_toc = protobuf.Message(M_MARRY_PROPOSE_REPLY_TOC)

