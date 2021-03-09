using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using ProtoBuf;
using Object = UnityEngine.Object;
using Random = UnityEngine.Random;
using Loong.Game;

/// <summary>
/// 召唤单位
/// </summary>
public class SummonUnitEvent : GameEvent
{
    Vector3 mPos = Vector3.zero;
    EventData mData = null;
    Unit mParentUnit = null;
    protected CampType mCamp;
    int mAddTarNum = 0;

    public SummonUnitEvent(EventData data, Vector3 targetPos, Unit parentUnit = null, ulong unitID = 0)
    {
        if (parentUnit != null)
            mCamp = parentUnit.Camp;
        else
            mCamp = CampType.CampType1;

        mParentUnit = parentUnit;
        mData = data;
        mAddTarNum = 0;
        float factor = 0.01f;
        mPos.Set(data.PosX * factor, data.PosY * factor, data.PosZ * factor);

        //如果data.Local 为true，使用的mPos是以释放者为root再加偏移值的一个位置，否则是以目标点为root再加偏移值的一个位置
        if (!data.Local)
        {
            mPos = targetPos;
            Vector3 forward = parentUnit.Position - mPos;
            Quaternion quaternion = Quaternion.LookRotation(forward);
            Vector3 offset = new Vector3(data.PosX * factor, data.PosY * factor, data.PosZ * factor);
            Matrix4x4 matrix = Matrix4x4.TRS(mPos, quaternion, Vector3.one);
            mPos = matrix.MultiplyPoint(offset);

            Ray ray = new Ray(mPos + new Vector3(0, 50, 0), Vector3.down);
            RaycastHit hit;
            if (Physics.Raycast(ray, out hit, 100, 1 << LayerMask.NameToLayer("Ground")))
                mPos.y = hit.point.y;
        }
    }

    /// <summary>
    /// 设置增加数量
    /// </summary>
    /// <param name="addTarNum"></param>
    public void SetAddTarNum(int addTarNum)
    {
        mAddTarNum = addTarNum;
    }

    public override void Execute()
    {
        if (!mData.RandomRange)
            CreateAddUnit();
        else
            CreateUnitWithoutModel();

    }

    /// <summary>
    /// 对没有模型的单位创建数据
    /// </summary>
    private void CreateAddUnit()
    {
        uint unitTypeId = (uint)mData.UnitID;
        string actionID = mData.ActionId;
        Unit unit = ObjPool.Instance.Get<Unit>();
        unit.Reset();
        unit.TypeId = unitTypeId;
        unit.ModelId = UnitHelper.instance.GetUnitModeId(unitTypeId);
        unit.ActGroupId = unit.ModelId;
        unit.MaxHP = 100000;
        unit.HP = 100000;
        unit.FightType = mParentUnit.FightType;

        Vector3 vPos = mPos;
        if (mParentUnit != null && mParentUnit.UnitTrans != null && mData.Local)
            vPos = mParentUnit.UnitTrans.localToWorldMatrix.MultiplyPoint(mPos);

        RoleBase roleInfo = RoleBaseManager.instance.Find(unit.ModelId);
        string modelPath = roleInfo.modelPath;

        AssetMgr.LoadPrefab(modelPath, (obj) =>
        {
            Transform trans = obj.transform;
            trans.parent = null;
            obj.SetActive(true);
            SetCamp(unit);
            unit.Init(trans);
            unit.SetOrientation(mParentUnit.Orientation);
            unit.Position = vPos;
            CheckParentUnit(unit, roleInfo);
            unit.ActionStatus.ChangeActionGroup(0, actionID);
            uint skillId = (uint)mData.SkillId;
            SkillManager.instance.AddSkill(unit, skillId, 0);
            GameSkill skill = SkillManager.instance.FindSkillBySkLvID(unit, skillId);
            unit.ActionStatus.SetSkill(skill.SkillLevelID,mAddTarNum);
            UnitMgr.instance.AddUnit(unit);
        });
    }

    /// <summary>
    /// 检查父体
    /// </summary>
    private void CheckParentUnit(Unit unit,RoleBase roleInfo)
    {
        if (mParentUnit == null)
            return;
        List<Unit> children = mParentUnit.Children.FindAll((Unit u) => { return u.ModelId == roleInfo.baseid; });
        if ((mData.MaxChildren != 0 && children.Count > 0) && children.Count >= mData.MaxChildren)//判断有没有超过父体最大召唤数
        {
            if (string.IsNullOrEmpty(mData.DeleteAction))
                children[0].Destroy();
            else
                children[0].ActionStatus.ChangeAction(mData.DeleteAction, 0);
        }
        mParentUnit.AddChildUnit(unit);
        if (!mData.FollowParent)
            return;
        unit.FollowParent = true;
        Transform parent = null;
        parent = mParentUnit.UnitTrans;
        unit.UnitTrans.parent = parent;
        unit.UnitTrans.localScale = Vector3.one;
    }

    /// <summary>
    /// 对已经有模型的单位创建数据
    /// </summary>
    private void CreateUnitWithoutModel()
    {
        ushort modelID = (ushort)mData.UnitID;
        Unit unit = ObjPool.Instance.Get<Unit>();
        unit.Reset();
        unit.ModelId = modelID;
        SetCamp(unit);
        RoleBase roleInfo = RoleBaseManager.instance.Find(modelID);
        string modelPath = roleInfo.modelPath;
        Transform tran = Utility.FindNode<Transform>(mParentUnit.UnitTrans.gameObject, modelPath);
        unit.Init(tran);
        mParentUnit.AddChildUnit(unit);
        unit.FollowParent = mData.FollowParent;
        if (mData.ActionId != "")
            unit.ActionStatus.ChangeAction(mData.ActionId, 0);

        UnitMgr.instance.AddUnit(unit);
    }

    private void SetCamp(Unit unit)
    {
        if (unit == null)
            return;
        unit.Camp = mCamp;
    }
}
