--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_role_addict_remain_toc_pb')

M_ROLE_ADDICT_REMAIN_TOC = protobuf.Descriptor();
M_ROLE_ADDICT_REMAIN_TOC_ONLINE_TIME_FIELD = protobuf.FieldDescriptor();
M_ROLE_ADDICT_REMAIN_TOC_BENEFIT_FIELD = protobuf.FieldDescriptor();

M_ROLE_ADDICT_REMAIN_TOC_ONLINE_TIME_FIELD.name = "online_time"
M_ROLE_ADDICT_REMAIN_TOC_ONLINE_TIME_FIELD.full_name = ".m_role_addict_remain_toc.online_time"
M_ROLE_ADDICT_REMAIN_TOC_ONLINE_TIME_FIELD.number = 1
M_ROLE_ADDICT_REMAIN_TOC_ONLINE_TIME_FIELD.index = 0
M_ROLE_ADDICT_REMAIN_TOC_ONLINE_TIME_FIELD.label = 1
M_ROLE_ADDICT_REMAIN_TOC_ONLINE_TIME_FIELD.has_default_value = true
M_ROLE_ADDICT_REMAIN_TOC_ONLINE_TIME_FIELD.default_value = 0
M_ROLE_ADDICT_REMAIN_TOC_ONLINE_TIME_FIELD.type = 5
M_ROLE_ADDICT_REMAIN_TOC_ONLINE_TIME_FIELD.cpp_type = 1

M_ROLE_ADDICT_REMAIN_TOC_BENEFIT_FIELD.name = "benefit"
M_ROLE_ADDICT_REMAIN_TOC_BENEFIT_FIELD.full_name = ".m_role_addict_remain_toc.benefit"
M_ROLE_ADDICT_REMAIN_TOC_BENEFIT_FIELD.number = 2
M_ROLE_ADDICT_REMAIN_TOC_BENEFIT_FIELD.index = 1
M_ROLE_ADDICT_REMAIN_TOC_BENEFIT_FIELD.label = 1
M_ROLE_ADDICT_REMAIN_TOC_BENEFIT_FIELD.has_default_value = false
M_ROLE_ADDICT_REMAIN_TOC_BENEFIT_FIELD.default_value = ""
M_ROLE_ADDICT_REMAIN_TOC_BENEFIT_FIELD.type = 9
M_ROLE_ADDICT_REMAIN_TOC_BENEFIT_FIELD.cpp_type = 9

M_ROLE_ADDICT_REMAIN_TOC.name = "m_role_addict_remain_toc"
M_ROLE_ADDICT_REMAIN_TOC.full_name = ".m_role_addict_remain_toc"
M_ROLE_ADDICT_REMAIN_TOC.nested_types = {}
M_ROLE_ADDICT_REMAIN_TOC.enum_types = {}
M_ROLE_ADDICT_REMAIN_TOC.fields = {M_ROLE_ADDICT_REMAIN_TOC_ONLINE_TIME_FIELD, M_ROLE_ADDICT_REMAIN_TOC_BENEFIT_FIELD}
M_ROLE_ADDICT_REMAIN_TOC.is_extendable = false
M_ROLE_ADDICT_REMAIN_TOC.extensions = {}

m_role_addict_remain_toc = protobuf.Message(M_ROLE_ADDICT_REMAIN_TOC)
