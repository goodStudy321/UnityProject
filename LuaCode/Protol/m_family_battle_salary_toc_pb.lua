--Generated By protoc-gen-lua Do not Edit
local protobuf = require "protobuf.protobuf"
module('Protol.m_family_battle_salary_toc_pb')

M_FAMILY_BATTLE_SALARY_TOC = protobuf.Descriptor();
M_FAMILY_BATTLE_SALARY_TOC_ERR_CODE_FIELD = protobuf.FieldDescriptor();
M_FAMILY_BATTLE_SALARY_TOC_SALARY_FIELD = protobuf.FieldDescriptor();

M_FAMILY_BATTLE_SALARY_TOC_ERR_CODE_FIELD.name = "err_code"
M_FAMILY_BATTLE_SALARY_TOC_ERR_CODE_FIELD.full_name = ".m_family_battle_salary_toc.err_code"
M_FAMILY_BATTLE_SALARY_TOC_ERR_CODE_FIELD.number = 1
M_FAMILY_BATTLE_SALARY_TOC_ERR_CODE_FIELD.index = 0
M_FAMILY_BATTLE_SALARY_TOC_ERR_CODE_FIELD.label = 1
M_FAMILY_BATTLE_SALARY_TOC_ERR_CODE_FIELD.has_default_value = true
M_FAMILY_BATTLE_SALARY_TOC_ERR_CODE_FIELD.default_value = 0
M_FAMILY_BATTLE_SALARY_TOC_ERR_CODE_FIELD.type = 5
M_FAMILY_BATTLE_SALARY_TOC_ERR_CODE_FIELD.cpp_type = 1

M_FAMILY_BATTLE_SALARY_TOC_SALARY_FIELD.name = "salary"
M_FAMILY_BATTLE_SALARY_TOC_SALARY_FIELD.full_name = ".m_family_battle_salary_toc.salary"
M_FAMILY_BATTLE_SALARY_TOC_SALARY_FIELD.number = 2
M_FAMILY_BATTLE_SALARY_TOC_SALARY_FIELD.index = 1
M_FAMILY_BATTLE_SALARY_TOC_SALARY_FIELD.label = 1
M_FAMILY_BATTLE_SALARY_TOC_SALARY_FIELD.has_default_value = true
M_FAMILY_BATTLE_SALARY_TOC_SALARY_FIELD.default_value = true
M_FAMILY_BATTLE_SALARY_TOC_SALARY_FIELD.type = 8
M_FAMILY_BATTLE_SALARY_TOC_SALARY_FIELD.cpp_type = 7

M_FAMILY_BATTLE_SALARY_TOC.name = "m_family_battle_salary_toc"
M_FAMILY_BATTLE_SALARY_TOC.full_name = ".m_family_battle_salary_toc"
M_FAMILY_BATTLE_SALARY_TOC.nested_types = {}
M_FAMILY_BATTLE_SALARY_TOC.enum_types = {}
M_FAMILY_BATTLE_SALARY_TOC.fields = {M_FAMILY_BATTLE_SALARY_TOC_ERR_CODE_FIELD, M_FAMILY_BATTLE_SALARY_TOC_SALARY_FIELD}
M_FAMILY_BATTLE_SALARY_TOC.is_extendable = false
M_FAMILY_BATTLE_SALARY_TOC.extensions = {}

m_family_battle_salary_toc = protobuf.Message(M_FAMILY_BATTLE_SALARY_TOC)

