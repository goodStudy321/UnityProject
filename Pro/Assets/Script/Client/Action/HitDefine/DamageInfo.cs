using UnityEngine;
using System.Collections;
using Loong.Game;

/// <summary>
/// 伤害buff的数据类，用于计算伤害时候，各种buff叠加的最终伤害
/// </summary>
public class DamageInfo
{

    public enum DamageType
    {
        NormalSelf,
        NormalEnemy,        //正常伤害
        CriticalStrike,     //暴击
        DefenseBroken,      //破防
        Dodge,              //闪避
        Heal,               //治疗
        Parry               //格挡

    }
    /// <summary>
    /// 编辑器输入伤害
    /// </summary>
    public static int EditorInputDamage = 0;

    private int mFinalDamage;
    public int finalDamage { get { return mFinalDamage; } }
    
    /// <summary>
    /// 初始化info类型
    /// </summary>
    /// <param name="attacker">攻击者</param>
    /// <param name="target">目标</param>
    /// <param name="criticalStrike">是否重击</param>
    public DamageInfo(Unit attacker, Unit target, ActionCommon.HitData hitData)
    {
        float dam = attacker.FightVal / target.FightVal;
        dam /= 10;
        dam *= target.MaxHP;
        mFinalDamage = -(int)dam;
        if (EditorInputDamage != 0)
            mFinalDamage = EditorInputDamage;
    }
}
