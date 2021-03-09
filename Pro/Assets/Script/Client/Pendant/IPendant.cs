using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public interface IPendant
{
    #region 接口
    /// <summary>
    /// 穿戴
    /// </summary>
    Unit PutOn(Unit mountpointParent, uint unitTypeId, PendantStateEnum state,ActorData data = null);

    /// <summary>
    /// 脱下
    /// </summary>
    void TakeOff(ActorData data);

    /// <summary>
    /// 增加技能
    /// </summary>
    void AddSkills(List<Phantom.Protocal.p_skill> pSkillList);

    /// <summary>
    /// 设置位置
    /// </summary>
    void SetPosition();

    /// <summary>
    /// 改变动画
    /// </summary>
    void ChangePendantAction(Unit pendant, PendantStateEnum state);

    /// <summary>
    /// 更新
    /// </summary>
    void Update();
    #endregion
}
