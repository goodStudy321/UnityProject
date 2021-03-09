using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public partial class NPCMgr
{
    public static readonly NPCMgr instance = new NPCMgr();

    private NPCMgr()
    {

    }

    #region 变量
    /// <summary>
    /// 交互距离
    /// </summary>
    private float ActiveDis = 2.0f;
    #endregion

    #region 私有函数
    /// <summary>
    /// 点击NPC打开对应的面板
    /// </summary>
    //private void OpenUI(ulong unitID)
    private void OpenUI()
    {
//        if(TargetMission != null)
//        {
//             string talk = User.instance.GetMissionTalk(unitID, TargetMission);
//             if (!string.IsNullOrEmpty(talk))
//             {
//                 UIMgr.Open(UIName.UIDialog, OpenUIDialog);
//                 return;
//             }
//            if((MissionStatus)TargetMission.Status == MissionStatus.NOT_RECEIVE)
//            {
//                NetworkMgr.ReqMissionReceive(TargetMission.MissionID);
//                return;
//            }
//        }
        UIMgr.Open(UIName.UINPCPanel, null);
    }

    /// <summary>
    /// 打开对话UI
    /// </summary>
    /// <param name="args"></param>
    private void OpenUIDialog(params object[]  args)
    {
        if (args[0].ToString() != UIName.UIDialog) return;
        EventMgr.Remove(EventKey.UIOpen, OpenUIDialog);
        //RoleBase tabel = RoleBaseManager.instance.Find(mSelectNpc.ModelId);
    //    EventMgr.Trigger("UpdateDataUIDialog", mSelectNpc.mUnitAttInfo.Npc, TargetMission, tabel != null ? tabel.modelPath : string.Empty);
    }

    /// <summary>
    /// 打开任务UI
    /// </summary>
    private void OpenUINPCPanel(params object[] args)
    {
        if (args[0].ToString() != UIName.UINPCPanel) return;
        EventMgr.Remove(EventKey.UIOpen, OpenUINPCPanel);
        //EventMgr.Trigger("UpdateDataUINPCPanel", mSelectNpc.mUnitAttInfo.Npc, TargetMission);
   //     EventMgr.Trigger("UpdateDataUINPCPanel", mSelectNpc.mUnitAttInfo.Npc, TargetMission);
    }

    /// <summary>
    /// 刷新
    /// </summary>
    public void LateUpdate()
    {
        Unit owner = InputVectorMove.instance.MoveUnit;
        if (owner == null)
            return;
        ActionStatus atst = owner.ActionStatus;
        if (atst == null)
            return;
        if (atst.ActionState != ActionStatus.EActionStatus.EAS_Move)
            return;
        CheckNpcDic();
        if (mSelectNpc == null)
            return;
        Transform trans = mSelectNpc.UnitTrans;
        if (trans == null)
            return;
        UnitAttInfo unitAttInfo = mSelectNpc.mUnitAttInfo;
        if (unitAttInfo.Npc == null)
            return;
        if (unitAttInfo.Npc.rotation != 0)
            return;
        RotationNpc(trans.gameObject);
    }

    /// <summary>
    /// 旋转npc
    /// </summary>
    /// <param name="go"> npc gameobject</param>
    private void RotationNpc(GameObject go)
    {
        if (go == null) return;
        Unit owner = InputVectorMove.instance.MoveUnit;
        if (owner == null) return;
        Vector3 tmpForward = go.transform.forward.normalized;
        RotateScript rotateScript = go.GetComponent<RotateScript>();
        if (rotateScript == null)
            return;
        Vector3 desForward = owner.Position - go.transform.position;
        desForward = desForward.normalized;
        rotateScript.BeginRotate(tmpForward, desForward);
    }
    #endregion

    #region 公开函数

    public void SetClickNPC(uint npcid, bool isClick = false)
    {
        Unit npc = NPCMgr.instance.GetNPC(npcid);
        if (npc != null) NPCMgr.instance.OnClickNPCHandler(npc, isClick);
    }


    /// <summary>
    /// 点击NPC
    /// </summary>
    /// <param name="go"></param>
    public void OnClickNPCHandler(Unit unit, bool isClick = false)
    {
        if (unit == null || TransTool.IsNull(unit.UnitTrans) == true) return;
        if (InputVectorMove.instance.MoveUnit == null || TransTool.IsNull(InputVectorMove.instance.MoveUnit.UnitTrans) == true) return;
        if (Vector3.Distance(unit.UnitTrans.position, InputVectorMove.instance.MoveUnit.Position) > ActiveDis) return;
        if (mSelectNpc != null)
        {
            CheckNpcDic(true);
        }
        if (mSelectNpc != null && mSelectNpc.UnitUID == unit.UnitUID) return;
        mSelectNpc = mNPCDic[unit.TypeId];
        if (mSelectNpc != null)
        {
            NPCInfo info = unit.mUnitAttInfo.Npc;
            if (info != null && info.rotation == 0)
            {
                RotationNpc(mSelectNpc.UnitTrans.gameObject);
            }
            //CheckNPCRelatedMission(mSelectNpc.TypeId);
        }
        if(isClick) EventMgr.Trigger(EventKey.ClickNPC,mSelectNpc.TypeId);
    }

    /// <summary>
    /// 检测NPC和主角的距离/NPC方向还原
    /// </summary>
    public void CheckNpcDic(bool isClick = false)
    {
        if (mSelectNpc == null || mSelectNpc.UnitTrans == null || mSelectNpc.UnitTrans.name == "null" || mSelectNpc.UnitTrans.gameObject == null) return;
        Unit owner = InputVectorMove.instance.MoveUnit;
        if (owner == null || owner.UnitTrans == null|| owner.UnitTrans.name == "null" || owner.ActionStatus == null) return;
        if (!isClick && owner.ActionStatus.ActionState != ActionStatus.EActionStatus.EAS_Move) return;
        float dic = Vector3.Distance(mSelectNpc.Position, owner.UnitTrans.position);
        if (dic > ActiveDis || isClick)
        {
            Transform go = mSelectNpc.UnitTrans;
            if(go)
            {
                NPCInfo info = mSelectNpc.mUnitAttInfo.Npc;
                if (info != null && info.rotation == 0)
                {
                    RotateScript rotateScript = go.GetComponent<RotateScript>();
                    if (rotateScript == null)
                        return;
                    Vector3 desForward = go.forward.normalized;
                    rotateScript.BeginRotate(desForward, mOriForward);
                }
            }
            mSelectNpc = null;
            UIMgr.Close(UIName.UINPCPanel);
        }
    }

    /// <summary>
    /// 关闭UI
    /// </summary>
    public void CloaseUI()
    {
        CheckNpcDic(true);
    }
    #endregion
}
