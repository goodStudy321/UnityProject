--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_talent_skill_toc_pb')

M_TALENT_SKILL_TOC = protobuf.Descriptor();
M_TALENT_SKILL_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_TALENT_SKILL_TOC_TALENT_POINTS_FIELD = protobuf.FieldDescriptor();
M_TALENT_SKILL_TOC_LEARN_SKILL_FIELD = protobuf.FieldDescriptor();

M_TALENT_SKILL_TOC_ERR_CODE_FIELD.name = "err_code"
M_TALENT_SKILL_TOC_ERR_CODE_FIELD.full_name = ".m_talent_skill_toc.err_code"
M_TALENT_SKILL_TOC_ERR_CODE_FIELD.number = 1
M_TALENT_SKILL_TOC_ERR_CODE_FIELD.index = 0
M_TALENT_SKILL_TOC_ERR_CODE_FIELD.label = 1
M_TALENT_SKILL_TOC_ERR_CODE_FIELD.has_default_value = true
M_TALENT_SKILL_TOC_ERR_CODE_FIELD.default_value = 0
M_TALENT_SKILL_TOC_ERR_CODE_FIELD.type = 5
M_TALENT_SKILL_TOC_ERR_CODE_FIELD.cpp_type = 1

M_TALENT_SKILL_TOC_TALENT_POINTS_FIELD.name = "talent_points"
M_TALENT_SKILL_TOC_TALENT_POINTS_FIELD.full_name = ".m_talent_skill_toc.talent_points"
M_TALENT_SKILL_TOC_TALENT_POINTS_FIELD.number = 2
M_TALENT_SKILL_TOC_TALENT_POINTS_FIELD.index = 1
M_TALENT_SKILL_TOC_TALENT_POINTS_FIELD.label = 1
M_TALENT_SKILL_TOC_TALENT_POINTS_FIELD.has_default_value = true
M_TALENT_SKILL_TOC_TALENT_POINTS_FIELD.default_value = 0
M_TALENT_SKILL_TOC_TALENT_POINTS_FIELD.type = 5
M_TALENT_SKILL_TOC_TALENT_POINTS_FIELD.cpp_type = 1

M_TALENT_SKILL_TOC_LEARN_SKILL_FIELD.name = "learn_skill"
M_TALENT_SKILL_TOC_LEARN_SKILL_FIELD.full_name = ".m_talent_skill_toc.learn_skill"
M_TALENT_SKILL_TOC_LEARN_SKILL_FIELD.number = 3
M_TALENT_SKILL_TOC_LEARN_SKILL_FIELD.index = 2
M_TALENT_SKILL_TOC_LEARN_SKILL_FIELD.label = 1
M_TALENT_SKILL_TOC_LEARN_SKILL_FIELD.has_default_value = true
M_TALENT_SKILL_TOC_LEARN_SKILL_FIELD.default_value = 0
M_TALENT_SKILL_TOC_LEARN_SKILL_FIELD.type = 5
M_TALENT_SKILL_TOC_LEARN_SKILL_FIELD.cpp_type = 1

M_TALENT_SKILL_TOC.name = "m_talent_skill_toc"
M_TALENT_SKILL_TOC.full_name = ".m_talent_skill_toc"
M_TALENT_SKILL_TOC.nested_types = {}
M_TALENT_SKILL_TOC.enum_types = {}
M_TALENT_SKILL_TOC.fields = {M_TALENT_SKILL_TOC_ERR_CODE_FIELD, M_TALENT_SKILL_TOC_TALENT_POINTS_FIELD, M_TALENT_SKILL_TOC_LEARN_SKILL_FIELD}
M_TALENT_SKILL_TOC.is_extendable = false
M_TALENT_SKILL_TOC.extensions = {}

m_talent_skill_toc = protobuf.Message(M_TALENT_SKILL_TOC)

