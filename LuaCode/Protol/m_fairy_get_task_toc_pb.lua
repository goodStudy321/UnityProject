--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_fairy_get_task_toc_pb')

M_FAIRY_GET_TASK_TOC = protobuf.Descriptor();
M_FAIRY_GET_TASK_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_FAIRY_GET_TASK_TOC_TIMES_FIELD = protobuf.FieldDescriptor();

M_FAIRY_GET_TASK_TOC_ERR_CODE_FIELD.name = "err_code"
M_FAIRY_GET_TASK_TOC_ERR_CODE_FIELD.full_name = ".m_fairy_get_task_toc.err_code"
M_FAIRY_GET_TASK_TOC_ERR_CODE_FIELD.number = 1
M_FAIRY_GET_TASK_TOC_ERR_CODE_FIELD.index = 0
M_FAIRY_GET_TASK_TOC_ERR_CODE_FIELD.label = 1
M_FAIRY_GET_TASK_TOC_ERR_CODE_FIELD.has_default_value = true
M_FAIRY_GET_TASK_TOC_ERR_CODE_FIELD.default_value = 0
M_FAIRY_GET_TASK_TOC_ERR_CODE_FIELD.type = 5
M_FAIRY_GET_TASK_TOC_ERR_CODE_FIELD.cpp_type = 1

M_FAIRY_GET_TASK_TOC_TIMES_FIELD.name = "times"
M_FAIRY_GET_TASK_TOC_TIMES_FIELD.full_name = ".m_fairy_get_task_toc.times"
M_FAIRY_GET_TASK_TOC_TIMES_FIELD.number = 2
M_FAIRY_GET_TASK_TOC_TIMES_FIELD.index = 1
M_FAIRY_GET_TASK_TOC_TIMES_FIELD.label = 1
M_FAIRY_GET_TASK_TOC_TIMES_FIELD.has_default_value = true
M_FAIRY_GET_TASK_TOC_TIMES_FIELD.default_value = 0
M_FAIRY_GET_TASK_TOC_TIMES_FIELD.type = 5
M_FAIRY_GET_TASK_TOC_TIMES_FIELD.cpp_type = 1

M_FAIRY_GET_TASK_TOC.name = "m_fairy_get_task_toc"
M_FAIRY_GET_TASK_TOC.full_name = ".m_fairy_get_task_toc"
M_FAIRY_GET_TASK_TOC.nested_types = {}
M_FAIRY_GET_TASK_TOC.enum_types = {}
M_FAIRY_GET_TASK_TOC.fields = {M_FAIRY_GET_TASK_TOC_ERR_CODE_FIELD, M_FAIRY_GET_TASK_TOC_TIMES_FIELD}
M_FAIRY_GET_TASK_TOC.is_extendable = false
M_FAIRY_GET_TASK_TOC.extensions = {}

m_fairy_get_task_toc = protobuf.Message(M_FAIRY_GET_TASK_TOC)
