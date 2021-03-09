/// <summary>
/// key状态
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
/// key列表
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
/// 与动作编辑器的中断列表里面的输入操作里面的"按钮状态"对应
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
/// 与动作编辑器的中断列表里面的输入操作里面的"按钮名称"对应
/// </summary>
public enum EOperation
{
    EO_None = 0,    //无
    EO_Attack,      //普攻
    EO_SpAttack,    //机械
    EO_Move,        //移动
    EO_Dodge,       //移动
    EO_Last,        //最近
};


