using UnityEngine;
using ProtoBuf;

public class KeyInput 
{
    public static readonly KeyInput instance = new KeyInput();

    private KeyInput()
    {

    }
    #region 私有变量

    #endregion

    #region 公有变量
    /// <summary>
    /// 按键列表
    /// </summary>
    public KeyState[] KeyStates = new KeyState[(int)EKeyList.KL_Max];
    /// <summary>
    /// 双击时间
    /// </summary>
    public float DoubleClickTime = 0.2f;
    #endregion

    #region 属性

    #endregion

    #region 公有方法
    /// <summary>
    /// 初始化
    /// </summary>
    public void Init()
    {
        for (int i = 0; i < KeyStates.Length; i++)
            KeyStates[i] = new KeyState();
        KeyStates[(int)EKeyList.KL_Jump].AxisName = "Jump";
        KeyStates[(int)EKeyList.KL_Attack].AxisName = "Attack";
        KeyStates[(int)EKeyList.KL_SubAttack].AxisName = "SubAttack";
        KeyStates[(int)EKeyList.KL_SkillAttack].AxisName = "SkillAttack";
        KeyStates[(int)EKeyList.KL_Dodge].AxisName = "Dodge";
        KeyStates[(int)EKeyList.KL_AuxKey].AxisName = "AuxKey";
    }
    
    /// <summary>
    /// 按下
    /// </summary>
    /// <param name="keyStatus"></param>
    public bool OnKeyDown(KeyState keyStatus)
    {
        bool result = false;
        if (!InputMgr.instance.CanInput) return result;
        keyStatus.Pressed = keyStatus.PressedTime < DoubleClickTime ? 2 : 1;
        keyStatus.PressedTime = 0.0f;
        result = CheckActionInput(0); // 处理按下瞬间
        return result;
    }

    /// <summary>
    /// 弹起
    /// </summary>
    /// <param name="keyStatus"></param>
    public bool OnKeyUp(KeyState keyStatus)
    {
        bool result = false;
        if (!InputMgr.instance.CanInput) return result;
        keyStatus.Pressed = 0;
        keyStatus.ReleasedTime = 0.0f;
        result = CheckActionInput(0); // 处理松开瞬间
        return result;
    }

    /// <summary>
    /// 检查动作中断
    /// </summary>
    /// <param name="deltaTime"></param>
    public bool CheckActionInput(float deltaTime)
    {
        Unit owner = InputVectorMove.instance.MoveUnit;
        if (owner == null)
            return false;
        ActionStatus actionStatus = owner.ActionStatus;
        if (actionStatus == null || actionStatus.ActiveAction == null || actionStatus.HasQueuedAction)
            return false;

        for (int interruptIdx = 0; interruptIdx < actionStatus.ActiveAction.InterruptList.Count; interruptIdx++)
        {
            ActionInterruptData interrupt = actionStatus.ActiveAction.InterruptList[interruptIdx];

            bool checker = false;
            if (interrupt.NoInput)
                checker = true;
            else
            {
                checker = CheckInterruptInput(interrupt, deltaTime);
            }

            // pass the key input, then check the other conditions.
            if (checker && (!interrupt.CheckAllCondition || actionStatus.CheckActionInterrupt(interrupt)))
            {
                bool success = actionStatus.LinkAction(interrupt);
                return success;
            }
        }
        return false;
    }

    /// <summary>
    /// 重置
    /// </summary>
    public void Reset()
    {
        for (int i = 0; i < KeyStates.Length; i++)
        {
            if (KeyStates[i] == null)
                continue;
            KeyStates[i].Reset();
        }
    }

    /// <summary>
    /// 更新按键状态
    /// </summary>
    /// <param name="deltaTime"></param>
    public void UpdateKeyStatus(float deltaTime)
    {
        if (InputMgr.instance.mOwner == null)
            return;
        // check the key status.
        for (int idx = 0; idx < KeyStates.Length; idx++)
        {
            KeyState keyStatus = KeyStates[idx];
            keyStatus.PressedTime += deltaTime;
            keyStatus.ReleasedTime += deltaTime;

            if (string.IsNullOrEmpty(keyStatus.AxisName))
                continue;

            // check the key state.
            if (Application.platform == RuntimePlatform.WindowsEditor || Application.platform == RuntimePlatform.OSXEditor)
            {
                bool pressed = Input.GetAxis(keyStatus.AxisName) > 0;
                if (pressed && keyStatus.Pressed == 0)
                    OnKeyDown(keyStatus);

                if (!pressed && keyStatus.Pressed != 0)
                    OnKeyUp(keyStatus);
            }
        }
    }
    #endregion

    #region 私有方法
    /// <summary>
    /// 检查中断输入
    /// </summary>
    /// <param name="interrupt"></param>
    /// <param name="deltaTime"></param>
    /// <returns></returns>
    private bool CheckInterruptInput(ActionInterruptData interrupt, float deltaTime)
    {
        if (interrupt.IsCheckInput1 == false)
            return false;

        if (!interrupt.AndCondition)
        {
            // or
            return
                (HasInput(interrupt.CheckInput1.InputKey, interrupt.CheckInput1.InputType, deltaTime) ||
                 HasInput(interrupt.CheckInput2.InputKey, interrupt.CheckInput2.InputType, deltaTime));
        }
        else
        {
            // and
            return
                ((HasInput(interrupt.CheckInput1.InputKey, interrupt.CheckInput1.InputType, deltaTime)) &&
                (HasInput(interrupt.CheckInput2.InputKey, interrupt.CheckInput2.InputType, deltaTime)));
        }
    }

    /// <summary>
    /// 检查输入类型
    /// </summary>
    /// <param name="inpuKey"></param>
    /// <param name="inputType"></param>
    /// <param name="deltaTime"></param>
    /// <returns></returns>
    private bool checkInputType(EKeyList inpuKey, EInputType inputType, float deltaTime)
    {
        int pressed = KeyStates[(int)inpuKey].Pressed;
        float pressedTime = KeyStates[(int)inpuKey].PressedTime;
        float releasedTime = KeyStates[(int)inpuKey].ReleasedTime;

        bool ret = false;
        switch (inputType)
        {
            case EInputType.EIT_Click:
                ret = (/*pressed == 1 && */pressedTime == 0);
                break;
            case EInputType.EIT_DoubleClick:
                ret = (pressed == 2 && pressedTime == 0);
                break;
            case EInputType.EIT_Release:
                ret = (pressed == 0 && releasedTime == 0);
                break;
            case EInputType.EIT_Pressing:
                ret = (pressed != 0);
                break;
            case EInputType.EIT_Releasing:
                ret = (pressed == 0);
                break;

        }
        return ret;
    }

    /// <summary>
    /// 判断是否有输入
    /// </summary>
    /// <param name="operation"></param>
    /// <param name="inputType"></param>
    /// <param name="deltaTime"></param>
    /// <returns></returns>
    private bool HasInput(int operation, int inputType, float deltaTime)
    {
        return HasInput((EOperation)operation, (EInputType)inputType, deltaTime);
    }

    /// <summary>
    /// 判断是否有输入
    /// </summary>
    /// <param name="operation"></param>
    /// <param name="inputType"></param>
    /// <param name="deltaTime"></param>
    /// <returns></returns>
    private bool HasInput(EOperation operation, EInputType inputType, float deltaTime)
    {
        bool ret = false;
        switch (operation)
        {
            case EOperation.EO_Attack:
                ret = checkInputType(EKeyList.KL_Attack, inputType, deltaTime);
                break;
            case EOperation.EO_SpAttack:
                ret = checkInputType(EKeyList.KL_SubAttack, inputType, deltaTime);
                break;
            case EOperation.EO_Move:
                ret = checkInputType(EKeyList.KL_Move, inputType, deltaTime);
                break;
            case EOperation.EO_Dodge:
                ret = checkInputType(EKeyList.KL_Dodge, inputType, deltaTime);
                break;
            case EOperation.EO_Last:
                ret = checkInputType(EKeyList.KL_LastKey, inputType, deltaTime);
                break;
        }
        return ret;
    }

    #endregion
}
