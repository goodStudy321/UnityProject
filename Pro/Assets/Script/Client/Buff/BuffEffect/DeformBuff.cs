using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class DeformBuff : BuffUnit
{
    #region 公有方法
    public DeformBuff(BufSetup bufSetup, Unit owner, object[] param)
        : base(bufSetup, owner, param)
    {
        if (!SatifyCon())
            return;
        bUsing = true;
        LoadModel();
    }

    public override void OnDestroy()
    {
        bUsing = false;
        DestroyModel();
    }
    #endregion

    #region 私有变量
    /// <summary>
    /// 是否在使用
    /// </summary>
    private bool bUsing = false;
    /// <summary>
    /// 原有变换
    /// </summary>
    private Transform mOrigTrans;
    /// <summary>
    /// 原模型Id
    /// </summary>
    private ushort mOrigModelId;
    /// <summary>
    /// 原动作组Id
    /// </summary>
    private ushort mOrigActGroupId;
    /// <summary>
    /// 模型Id
    /// </summary>
    private ushort mModelId;
    /// <summary>
    /// 模型名
    /// </summary>
    private string mModelName;
    /// <summary>
    /// 跳跃完成
    /// </summary>
    private bool bJumpDone = false;
    #endregion

    #region 私有方法
    /// <summary>
    /// 满足条件
    /// </summary>
    /// <returns></returns>
    private bool SatifyCon()
    {
        if (mOwner == null)
            return false;
        if (mBuffSetup.mBufBaseInfo == null)
            return false;
        return true;
    }
    /// <summary>
    /// 加载模型
    /// </summary>
    private void LoadModel()
    {

        int modId = GetValItem();
        mModelId = (ushort)modId;
        string modName = GetModName(mModelId);
        mModelName = modName;
        if (string.IsNullOrEmpty(modName))
            return;
        RcdJumpDoneState();
        AssetMgr.LoadPrefab(modName, LoadMDone);
    }

    /// <summary>
    /// 加载模型完成
    /// </summary>
    /// <param name="go"></param>
    private void LoadMDone(GameObject go)
    {
        go.transform.parent = null;
        go.SetActive(true);
        DealJumpState();
        if (bUsing == false)
        {
            ReleaseGo(go);
            return;
        }
        RcdOrigInfo();
        mOwner.ModelId = mModelId;
        mOwner.ActGroupId = mModelId;
        //go.transform.name = mOrigTrans.name;
        ChgPosFwd(go.transform, mOrigTrans);
        ReSetUnitData(go.transform);
        SetShowState(mOrigTrans);

        if (PJShadowMgr.Instance.FSShadow != null)
        {
            PJShadowMgr.Instance.FSShadow.FollowTarget = go;
        }
    }

    /// <summary>
    /// 销毁模型
    /// </summary>
    private void DestroyModel()
    {
        if (mOwner == null)
            return;
        if (mOrigTrans == null)
            return;
        RcdJumpDoneState();
        mOwner.ModelId = mOrigModelId;
        mOwner.ActGroupId = mOrigActGroupId;
        Transform trans = mOwner.UnitTrans;
        GameObject go = null;
        if (trans != null)
            go = trans.gameObject;
        ChgPosFwd(mOrigTrans, trans);
        ReSetUnitData(mOrigTrans);
        SetShowState(trans);
        ReleaseGo(go);
        DealJumpState();
    }

    /// <summary>
    /// 记录原有信息
    /// </summary>
    private void RcdOrigInfo()
    {
        mOrigTrans = mOwner.UnitTrans;
        mOrigModelId = mOwner.ModelId;
        mOrigActGroupId = mOwner.ActGroupId;
    }

    /// <summary>
    /// 交换位置和方向
    /// </summary>
    /// <param name="trans"></param>
    /// <param name="trans1"></param>
    private void ChgPosFwd(Transform trans, Transform trans1)
    {
        if (trans == null)
            return;
        if (trans1 == null)
            return;
        trans.position = trans1.position;
        trans.forward = trans1.forward;
    }

    /// <summary>
    /// 重置单位数据
    /// </summary>
    private void ReSetUnitData(Transform trans)
    {
        mOwner.SetUnitTransInfo(trans);
        mOwner.ActionStatus.ChangeActionGroup(0);
        //初始化攻击脚本
        mOwner.InitHitComponent();
        //摄像机跟随对象重置
        if (mOwner.UnitUID == User.instance.MapData.UID)
            CameraMgr.UpdateOperation(CameraType.Player, mOwner.UnitTrans, true);
        //血条或名称条重置
        TopBarFty.ResetTopObject(mOwner);
        UnitShadowMgr.instance.SetShadow(mOwner);
    }

    /// <summary>
    /// 设置单位模型显示状态
    /// </summary>
    /// <param name="oldTrans"></param>
    private void SetShowState(Transform oldTrans)
    {
        if (oldTrans == null)
            return;
        bool isShow = oldTrans.gameObject.activeSelf;
        if (isShow)
        {
            if (mOwner.UnitTrans != null)
                mOwner.UnitTrans.gameObject.SetActive(true);
        }
        else
            SettingMgr.instance.HideRole(mOwner);
        oldTrans.gameObject.SetActive(false);
    }

    /// <summary>
    /// 获取模型名
    /// </summary>
    /// <returns></returns>
    private string GetModName(ushort modId)
    {
        if (modId == 0)
            return string.Empty;
        RoleBase roleInfo = RoleBaseManager.instance.Find((ushort)modId);
        if (roleInfo != null)
            return roleInfo.modelPath;
        return string.Empty;
    }

    /// <summary>
    /// 获取参数值
    /// </summary>
    /// <returns></returns>
    private int GetValItem()
    {
        BuffBase info = mBuffSetup.mBufBaseInfo;
        List<BuffBase.Val> attrLst = info.items.list;
        int count = attrLst.Count;
        if (count == 0)
            return 0;
        return attrLst[0].k;
    }

    /// <summary>
    /// 销毁对象
    /// </summary>
    /// <param name="go"></param>
    private void ReleaseGo(GameObject go)
    {
        if (string.IsNullOrEmpty(mModelName))
            AssetMgr.Instance.Unload(mModelName, ".prefab", false);
        if (go != null)
            GameObject.Destroy(go);
    }

    /// <summary>
    /// 记录跳跃完成
    /// </summary>
    private void RcdJumpDoneState()
    {
        bJumpDone = false;
        if (mOwner == null)
            return;
        if (mOwner.ActionStatus == null)
            return;
        if (mOwner.ActionStatus.ActiveAction == null)
            return;
        if (mOwner.ActionStatus.ActiveAction.AnimID != "N0033")
            return;
        bJumpDone = true;
    }

    /// <summary>
    /// 记录跳跃状态
    /// </summary>
    private void DealJumpState()
    {
        if (bJumpDone == false)
            return;
        if (mOwner == null)
            return;
        mOwner.mNetUnitMove.LandAnimFinish();
    }
    #endregion
}
