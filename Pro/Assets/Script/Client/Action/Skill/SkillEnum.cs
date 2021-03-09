using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// ��������������
/// </summary>
public enum SkillEnum
{
    NormalAtk = 0,  //��ͨ����
    Active = 1,     //��������
    passtive = 2,   //��������
}

/// <summary>
/// �������ö��
/// </summary>
public enum PreSkillEnum
{
    NormalAttack = 1,    //��ͨ����
    Skill_1 = 2,         //����1
    Skill_2 = 3,         //����2
    Skill_3 = 4,         //����3
    Skill_4 = 5,         //����4
    Skill_5 = 6,         //����5
    Skill_6 = 7,         //����6
    Skill_7 = 8,         //����7
    Skill_8 = 9,         //����8
}

/// <summary>
/// �˺�����
/// </summary>
public enum HarmType
{
    Normal = 0x01,     //��ͨ�˺�
    Dodge = 0x02,      //����
    Critical = 0x04,   //����
    Knowing = 0x08,    //����
    Parry = 0x10,       //��
    Cure = 0x20,        //���ƣ���Ѫ��
    Absorb = 0x40,      //�����˺�



    PoisonReductionHp = 9,    //buff�ж���Ѫ
    CureAddHp = 10,            //buff���Ƽ�Ѫ
}

/// <summary>
/// ���ܹ���
/// </summary>
public enum SkillBelongEnum
{
    RoleSkill = 1,      //��ɫ����
    MonsterSkill = 2,   //���＼��
    PetSkill = 3,       //���＼��
    MountSkill = 4,     //���＼��
    MagicWeaponSkill = 5,//��������
    Wing = 6,           //�����
    Fashion = 13,           //�����
}