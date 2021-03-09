/// <summary>
/// key״̬
/// </summary>
public class KeyState
{
    public string AxisName;
    public float PressedTime = 10.0f;
    public float ReleasedTime = 10.0f;
    public int Pressed = 0;			// 0=release 1=click 2=double click
    public int Operation = 0;		// for action input binding...
    public bool isForUI = false;

    public void Reset()
    {
        PressedTime = 10;
        ReleasedTime = 10;
        Pressed = 0;
        Operation = 0;
    }
}

/// <summary>
/// key�б�
/// </summary>
public enum EKeyList
{
    KL_Attack = 0,
    KL_SubAttack,
    KL_Dodge,
    KL_SkillAttack,
    KL_AuxKey,

    KL_Move,
    KL_Grab,
    KL_Jump,
    KL_CameraUp,
    KL_CameraDown,
    KL_LastKey,
    KL_Max,
};

/// <summary>
/// �붯���༭�����ж��б������������������"��ť״̬"��Ӧ
/// </summary>
public enum EInputType
{
    EIT_Click = 0,
    EIT_DoubleClick,
    EIT_Release,
    EIT_Pressing,
    EIT_Releasing,
};

/// <summary>
/// �붯���༭�����ж��б������������������"��ť����"��Ӧ
/// </summary>
public enum EOperation
{
    EO_None = 0,    //��
    EO_Attack,      //�չ�
    EO_SpAttack,    //��е
    EO_Move,        //�ƶ�
    EO_Dodge,       //�ƶ�
    EO_Last,        //���
};


