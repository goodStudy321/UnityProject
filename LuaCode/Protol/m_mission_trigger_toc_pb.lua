--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_mission_trigger_toc_pb')

M_MISSION_TRIGGER_TOC = protobuf.Descriptor();
M_MISSION_TRIGGER_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();

M_MISSION_TRIGGER_TOC_ERR_CODE_FIELD.name = "err_code"
M_MISSION_TRIGGER_TOC_ERR_CODE_FIELD.full_name = ".m_mission_trigger_toc.err_code"
M_MISSION_TRIGGER_TOC_ERR_CODE_FIELD.number = 1
M_MISSION_TRIGGER_TOC_ERR_CODE_FIELD.index = 0
M_MISSION_TRIGGER_TOC_ERR_CODE_FIELD.label = 1
M_MISSION_TRIGGER_TOC_ERR_CODE_FIELD.has_default_value = true
M_MISSION_TRIGGER_TOC_ERR_CODE_FIELD.default_value = 0
M_MISSION_TRIGGER_TOC_ERR_CODE_FIELD.type = 5
M_MISSION_TRIGGER_TOC_ERR_CODE_FIELD.cpp_type = 1

M_MISSION_TRIGGER_TOC.name = "m_mission_trigger_toc"
M_MISSION_TRIGGER_TOC.full_name = ".m_mission_trigger_toc"
M_MISSION_TRIGGER_TOC.nested_types = {}
M_MISSION_TRIGGER_TOC.enum_types = {}
M_MISSION_TRIGGER_TOC.fields = {M_MISSION_TRIGGER_TOC_ERR_CODE_FIELD}
M_MISSION_TRIGGER_TOC.is_extendable = false
M_MISSION_TRIGGER_TOC.extensions = {}

m_mission_trigger_toc = protobuf.Message(M_MISSION_TRIGGER_TOC)

