using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public interface IPendant
{
    #region �ӿ�
    /// <summary>
    /// ����
    /// </summary>
    Unit PutOn(Unit mountpointParent, uint unitTypeId, PendantStateEnum state,ActorData data = null);

    /// <summary>
    /// ����
    /// </summary>
    void TakeOff(ActorData data);

    /// <summary>
    /// ���Ӽ���
    /// </summary>
    void AddSkills(List<Phantom.Protocal.p_skill> pSkillList);

    /// <summary>
    /// ����λ��
    /// </summary>
    void SetPosition();

    /// <summary>
    /// �ı䶯��
    /// </summary>
    void ChangePendantAction(Unit pendant, PendantStateEnum state);

    /// <summary>
    /// ����
    /// </summary>
    void Update();
    #endregion
}
