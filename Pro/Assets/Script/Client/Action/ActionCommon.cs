using UnityEngine;
using System.Collections.Generic;

public static class ActionCommon
{
    /// <summary>
    /// 高度状态
    /// </summary>
    public enum HeightStatusFlag
    {
        None = 0,
        Stand = 1,  //  站立 
        Ground = 2,
        LowAir = 4, //  空中

    }

    /// <summary>
    /// 攻击定义框类型
    /// </summary>
    public enum HitDefnitionFramType
    {
        CuboidType = 0,  //长方体
        CylinderType = 1,  //圆柱体
        RingType = 2,  //圆环体
        SomatoType = 3,  //受击体
        FanType = 4,  //扇形体
    };
    
    /// <summary>
    /// 受击结果类型
    /// </summary>
    public enum HitResultType
    {
        StandHit,           // 一般受击
        KnockOut,           // 击飞
        KnockBack,          // 击退
        KnockDown,          // 击倒
        DiagUp,             // 浮空
        Hold,               // 抓住
        AirHit,             // 浮空追击
        DownHit,            // 倒地追击
        FallDown,           // 跌倒
    }

    /// <summary>
    /// 事件类型
    /// </summary>
    public enum EventType
    {
        None = 0,
        PlayEffect,         // 播放特效	
        PlaySound,          // 播放音效	
        StatusOn,           // 打开状态
        StatusOff,          // 关闭状态
        SetVelocity,        // 设定位移速度
        SetVelocity_X,      // 设定位移速度X
        SetVelocity_Y,      // 设定位移速度Y
        SetVelocity_Z,      // 设定位移速度Z
        SetDirection,       // 设定方向
        ExeScript,          // 执行脚本
        SetGravity,         // 设置重力
        AddUnit,            // 添加单位
        RemoveMyself,       // 自我毁灭
        SetColor,           // 设置颜色
        PickUp,             // 拾取
        CameraEffect,       // 摄像机
        ListTargets,        // 列举目标
        FaceTargets,        // 面向目标
        Chat,
        SetMaterial,        // 设置材质
        FollowParent,       // 跟随父级
        CameraShake,        // 设置摄像机振动
        SetOutlineSkin,     // 设置外发光
        ResetNormalSkin,    // 设置内发光
        ForceStop,          //冲量刹车
        ForceRush,          //冲量
        NewListTarget,      //新版本listtarget
        SetDirectSpeed,     //设置转向速度
        ShowSkin,           //设置mesh显示和隐藏
        Scale,
        ShowEffect,
        HideEffect,
        ForceRushRange,
    }

    /// <summary>
    /// 击中事件类型
    /// </summary>
    public enum AttackEventType
    {
        None = 0,
        AddUnit,            // 添加单位
    }

    /// <summary>
    /// 攻击数据
    /// </summary>
    public struct HitData
    {
        public uint Target;
        public int HitX;
        public int HitY;
        public int HitZ;
        public short HitDir;
        public int StraightTime;
        public int LashX;
        public int LashY;
        public int LashZ;
        public int LashTime;
        public string HitAction;
        public byte AttackLevel;
        public bool IsRemoteAttacks;
        public bool HeatEnergyHit;
        public float mHurtRate;
    }
}