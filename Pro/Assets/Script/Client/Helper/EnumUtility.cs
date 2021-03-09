using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnumUtility
{


    #region ͨ��ö�ٻ�ȡ
    #endregion
}

public enum GameSceneType
{
    GST_Three = 0,            /* ���������� */
    GST_MainScene,              /* ���� */
    GST_Copy,
    GST_Unknown
}

/// <summary>
/// ����������
/// </summary>
public enum SceneSubType
{
    None = 0,
    WordBoss = 1,       //1 ����Boss��ͼ
    HomeOfBoss = 2,     //2 ���츣��Boss��ͼ
    PersonalBoss = 3,   //3 ����Boss��ͼ
    WildFBoss = 4,      //4 ���Ľ���Boss��ͼ
    AnswerMap = 5,      //5 ���⸱����ͼ
    CampMap = 6,        //6 ����Ӫ��ս��ͼ
    OVOMap = 7,         //7 1v1��ս��ͼ
    OffL1V1Map = 8,        //8 ����1v1��ս��ͼ
    DftMap = 9,         //9 ��ͥ����
    TopFight = 12,       //12 ����֮��
    ImmotalSoul = 13,   //�ɻ긱����ͼ
    CrossServer = 15,   //15 ���������ͼ
    DemonBoss = 18,   //ħ��BOSS
    WorldBossGuid = 19, //19 ����Boss������ͼ
}

public enum CopyType
{
    None = -1,                      //���ڸ���
    FlowChart = 0,                  /* ���������� */
    Exp = 1,                        /* ���鸱�� */
    Glod = 2,                       /* ��Ҹ��� */
    Equip = 3,                      /* װ������ */
    Tower = 4,                      /* �������� */
    Light = 5,                      /* ����ͼ���� */
    PsnalBoss = 6,                  //Vip����boss����
    SingleTD = 7,                   //������������
    Offl1v1 = 8,                    //����1v1����
    EvilSpirits = 9,                //��ħ����
    HjkCopy = 14,                   //�ɽٸ���
    Online1v1 = 25,                 //����1v1����
}

public enum CameraType
{
    Player = 0,
    Camp = 1
}

public enum FightValueType
{
    None = 0,
    Level = 1,      //�ȼ�ս����
    Equip = 2,      //װ��ս����
}


public enum PropertyBaseType
{
    HP                              = 1,
    Attack                          = 2,
    Defence                         = 3,                            //����
    Arp                             = 4,                            //�Ƽ�
    Hit                             = 5,                            //����
    Miss                            = 6,                            //����
    Crit                            = 7,                            //����
    Crit_Anti                       = 8,                            //����
    Crit_Multi                      = 9,                            //����
    Hurt_Rate                       = 11,                           //����
    Hurt_Derate                     = 12,                           //����
    Cirt_Doubel                     = 13,                           //��������
    Miss_Double                     = 14,                            //��������
    Crit_Multi_anti                 = 15,                            //����
    Skill_Add                       = 16,                            //�����˺�����
    Skill_Reduce                    = 17,                            //�����˺�����
    Kill_Monster_Exp_Add_Buff       = 26,                            //����ӳ�
    ATTR_MOVE_SPEED                 = 27,                            //�ƶ��ٶ�
    Role_Def                        = 28,                            //���ﻤ��



    Kill_Monster_Pick = 202                            //����ӳ�

    /**
    Crit_Max                        = 12,                           //����һ��
    Crit_Max_Def                    = 13,                           //���ĵֿ�
    Parry_Odds                      = 14,                           //�񵲼���
    Parry_Def                       = 15,                           //�ֿ���
    Ignore_Def                      = 16,                           //���ӷ���
    Ignore_Def_Resistance           = 17,                           //���ӷ����ֿ�
    FEAttack                        = 18,                           //���й���
    FEDefence                       = 19,                           //���з���
    Poison                          = 20,                           //�ж�
    Poison_Anti                     = 21,                           //�ж��ֿ�
    Slow                            = 22,                           //�ٻ�
    Slow_Anti                       = 23,                           //�ٻ��ֿ�
    Dizzy                           = 24,                           //ѣ��
    Dizzy_Anti                      = 25,                           //ѣ�εֿ�"
    ATTR_RATE_ADD_HP = 35,                //����������ֱ�
    ATTR_RATE_REDUCE_HP = 36,             //����������ֱ�
    ATTR_RATE_ADD_ATTACK = 37,            //����������ֱ�
    ATTR_RATE_REDUCE_ATTACK = 38,         //����������ֱ�
    ATTR_RATE_ADD_DEFENCE = 39,           //����������ֱ�
    ATTR_RATE_REDUCE_DEFENCE = 40,        //����������ֱ�
    ATTR_RATE_ADD_ARP = 41,               //�Ƽ�������ֱ�
    ATTR_RATE_REDUCE_ARP = 42,            //�Ƽ׼�����ֱ�
    ATTR_RATE_ADD_HIT = 43,               //����������ֱ�
    ATTR_RATE_REDUCE_HIT = 44,            //���м�����ֱ�
    ATTR_RATE_ADD_MISS = 45,              //����������ֱ�
    ATTR_RATE_REDUCE_MISS = 46,           //���ܼ�����ֱ�
    ATTR_RATE_ADD_DOUBLE = 47,            //����������ֱ�
    ATTR_RATE_REDUCE_DOUBLE = 48,         //����������ֱ�
    ATTR_RATE_ADD_DOUBLE_A = 49,          //����������ֱ�
    ATTR_RATE_REDUCE_DOUBLE_A = 50,       //���Լ�����ֱ�
    */
}

public enum PropertyType
{
    ATTR_HP = 1,                    //Ѫ��
    ATTR_STATUS = 2,                //״̬ ��Ӧֵ1������״̬
    ATTR_MOVE_SPEED = 3,            //����
    ATTR_BUFF_UPDATE = 4,           //buff����
    ATTR_BUFF_DEL = 5,              //buffɾ��
    ATTR_CAMP_ID = 6,               //��Ӫ�仯
    ATTR_PK_MODE = 7,               //pkģʽ�仯
    ATTR_RE_NAME = 8,               //���ַ����仯
    ATTR_LEVEL_CHANGE = 101,        //��ɫ�ȼ��仯
    ATTR_WEAPON_CHANGE = 102,       //����״̬�仯
    ATTR_PENDANT_CHANGE = 103,      //�Ҽ���۱仯
    ATTR_PK_VALUE = 104,            //PKֵ�仯
    ATTR_FAMILY_ID_CHANGE = 105,    //��ɫ����ID�仯
    ATTR_FAMILY_NAME_CHANGE = 106,  //��ɫ�������ֱ仯
    ATTR_TEAM_ID = 107,             //��ɫ����ID�仯
    ATTR_POWER_CHANGE = 108,        //��ɫս�����仯
    ATTR_CONFINE_CHANGE = 109,      //����仯
    ATTR_TITLE_CHANGE = 110,        //�ƺű仯
    ATTR_POSITION_CHANGE = 111,     //��ְͥλ�仯
    ATTR_MarryID_CHANGE = 112,        //���±仯
    ATTR_Marry_CHANGE = 113,        //���±仯
    ATTR_LEVEL_REBIRTH = 114,       //ת���ȼ�
    ATTR_ORNAMENT_LIST = 115,       //��ɫװ���б�仯
    ATTR_BATTLE_OWNER = 201,        //ս������
    ATTR_COUNTDOWN = 203,           //����ʱ����
}

/// <summary>
/// ������������
/// </summary>
public enum PersonalProType
{
    ATTR_LSTLEVUP = 2,              //�ϴ�����ʱ��
    ATTR_OFFLFIGHTTIME = 3,         //���߹һ�ʱ��
}

/// <summary>
/// ��������
/// </summary>
public enum MissionType
{
    Main = 1,                           //��������\
    Turn = 101,                         //ѭ������
}

/// <summary>
/// ����״̬
/// </summary>
public enum MissionStatus
{
    None       = 0,
    NOT_RECEIVE= 1,             //δ��ȡ
    EXECUTE = 2,                //δ��ɣ�ִ����
    ALLOW_SUBMIT = 3,           //����ɣ�δ�ύ
    COMPLETE = 4                //�Ѿ����
}

/// <summary>
/// ����Ŀ������
/// </summary>
public enum MissionTargetType
{
    KILL_MONSTER = 0,
    TALK,
    COLLECTION,
    PATHFINDING = 4, 
    KLL_MONSTER_PR = 5,
    FLOW_CHART
}


public enum PendantSystemEnum
{
    Mount = 1,              //����
    MagicWeapon = 2,        //���� 
    Pet = 3,                //����
    Artifact = 4,           //���
    Wing = 5,               //���
    FashionableDress = 6,   //ʱװ
    PetMount = 8,           //��������
    FootPrint = 9,          //�㼣
}

/// <summary>
/// ʱװ����
/// </summary>
public enum FashionType
{
    None = 0,       
    Cloth = 1,      //�·�
    Weapon = 2,     //����
}

/// <summary>
/// ����״̬����
/// </summary>
public enum OpStateType
{
    Jump = 0,       //��Ծ
    Revive = 1,     //����
    ChangeScene = 2,//�л�����
    MoveToPoint = 3,//��ͨ��ת����ת
    SetUnitActive = 4, //���õ�λ��ʾ����
}

/// <summary>
/// ��������
/// </summary>
public enum CurrencyType
{
    Silver = 1,         //����
    Gold = 2,           //Ԫ��
    Bin_Gold = 3,       //��Ԫ��
    Honor = 11,         //����
    HontIntegral = 12,  //Ѱ������
    FamilyCon = 99,     //���ɹ���
}

/// <summary>
/// ��������
/// </summary>
public enum ConsumeType
{
    Silver = 1,         //��������
    Gold = 2,           //���Ĳ���Ԫ��
    Any_Gold = 3,       //�������İ�Ԫ��
    Honor = 11,         //��������
    HontIntegral = 12,  //Ѱ������
    FamilyCon = 99,     //���İ��ɹ���
}

public enum SceneStatus
{
    Normal = 0,
    LoadMod,
    LoadData
}
