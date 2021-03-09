using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;


/// <summary>
/// 质量显示控制器
/// </summary>
public class QualityDisplayCtrl
{
    /// <summary>
    /// 显示怪物记录
    /// </summary>
    private List<Unit> mShowUnitList = new List<Unit>();


    private float mTimer = 0f;
    private List<Unit> mInViewUnits = new List<Unit>();


    public QualityDisplayCtrl()
    {
        Init();
    }

    public void Update(float dTime)
    {
        if (IsNoLimit() == true)
            return;

        mTimer += dTime;
        if(mTimer >= 1)
        {
            mTimer = 0f;
            CheckEvilShowState();
        }
    }

    public void Clear()
    {
        mShowUnitList.Clear();
        mInViewUnits.Clear();
        mTimer = 0f;
    }

    public void Dispose()
    {

    }

    public bool IsNoLimit()
    {
        int showNum = QualityMgr.instance.ShowEvilNum;
        if (showNum < 0)
        {
            return true;
        }

        return false;
    }

    public bool CanAddDisplayUnit()
    {
        if(IsNoLimit() == true)
        {
            return true;
        }

        int showNum = QualityMgr.instance.ShowEvilNum;
        if (showNum > mShowUnitList.Count)
        {
            return true;
        }

        return false;
    }

    /// <summary>
    /// 添加可视怪物
    /// </summary>
    public void AddShowUnit(Unit addUnit)
    {
        if (IsNoLimit() == true)
            return;

        if(addUnit.UnitTrans == null)
        {
            return;
        }

        if (addUnit.mUnitAttInfo.UnitType != UnitType.Monster)
        {
            return;
        }

        if (SettingMgr.instance.IsInView(addUnit.UnitTrans.position) == false)
        {
            return;
        }

        //CheckEvilShowState();

        int showNum = QualityMgr.instance.ShowEvilNum;
        if (showNum <= mShowUnitList.Count)
        {
            UnitMgr.instance.SetUnitActive(addUnit, false, false, true);
            return;
        }

        if (mShowUnitList.Contains(addUnit) == false)
        {
            UnitMgr.instance.SetUnitActive(addUnit, true, true);
            mShowUnitList.Add(addUnit);
        }
        mTimer = 0f;
    }

    /// <summary>
    /// 强制添加可视怪物
    /// </summary>
    /// <param name="addUnit"></param>
    public void ForceAddShowUnit(Unit addUnit)
    {
        if (IsNoLimit() == true)
            return;

        if (addUnit == null || addUnit.mUnitAttInfo.UnitType != UnitType.Monster)
        {
            return;
        }

        if (mShowUnitList.Contains(addUnit) == false)
        {
            int showNum = QualityMgr.instance.ShowEvilNum;
            if (showNum <= mShowUnitList.Count)
            {
                Unit tUnit = mShowUnitList[mShowUnitList.Count - 1];
                UnitMgr.instance.SetUnitActive(addUnit, false, true, true);
                mShowUnitList.RemoveAt(mShowUnitList.Count - 1);
            }

            UnitMgr.instance.SetUnitActive(addUnit, true, true);
            mShowUnitList.Add(addUnit);
        }

        mTimer = 0f;
    }

    /// <summary>
    /// 删除可视怪物
    /// </summary>
    /// <param name="reUnit"></param>
    public void RemoveShowUnit(Unit reUnit)
    {
        if (IsNoLimit() == true)
            return;

        if (mShowUnitList.Contains(reUnit) == true)
        {
            mShowUnitList.Remove(reUnit);
            CheckEvilShowState();
        }
    }


    private void Init()
    {
        mShowUnitList.Clear();
    }

    /// <summary>
    /// 检查怪物显示状态
    /// </summary>
    public void CheckEvilShowState()
    {
        if (UnitMgr.instance.UnitList == null || UnitMgr.instance.UnitList.Count <= 0)
            return;

        mInViewUnits.Clear();
        for (int a = 0; a < UnitMgr.instance.UnitList.Count; a++)
        {
            Unit tUnit = UnitMgr.instance.UnitList[a];
            if (UnitHelper.instance.CanUseUnit(tUnit) == false)
            {
                continue;
            }

            if (tUnit.mUnitAttInfo.UnitType == UnitType.Monster)
            {
                if(SettingMgr.instance.IsInView(tUnit.Position) == true)
                {
                    mInViewUnits.Add(tUnit);
                }
                //else
                //{
                //    UnitMgr.instance.SetUnitActive(tUnit, false, false, true);
                //}
            }
        }

        /// 剔除不在屏幕内的 ///
        for(int a = mShowUnitList.Count - 1; a >= 0; a--)
        {
            if(UnitHelper.instance.CanUseUnit(mShowUnitList[a]) == false
                || mInViewUnits.Contains(mShowUnitList[a]) == false
                || mShowUnitList[a].mUnitAttInfo.UnitType != UnitType.Monster)
            {
                //UnitMgr.instance.SetUnitActive(mShowUnitList[a], false, false, true);
                mShowUnitList.RemoveAt(a);
            }
            else
            {
                UnitMgr.instance.SetUnitActive(mShowUnitList[a], true, true);
            }
        }
        int showNum = QualityMgr.instance.ShowEvilNum;
        if (showNum < 0)
        {
            for (int a = 0; a < mInViewUnits.Count; a++)
            {
                UnitMgr.instance.SetUnitActive(mInViewUnits[a], true, true);
            }
            return;
        }

        for (int a = 0; a < mInViewUnits.Count; a++)
        {
            if (showNum > mShowUnitList.Count)
            {
                if(mShowUnitList.Contains(mInViewUnits[a]) == false)
                {
                    UnitMgr.instance.SetUnitActive(mInViewUnits[a], true, true);
                    mShowUnitList.Add(mInViewUnits[a]);
                }
            }
            else
            {
                if (mShowUnitList.Contains(mInViewUnits[a]) == false)
                {
                    UnitMgr.instance.SetUnitActive(mInViewUnits[a], false, false, true);
                }
            }
        }

        if(showNum < mShowUnitList.Count)
        {
            int tNum = mShowUnitList.Count;
            for (int a = tNum - 1; a >= tNum - showNum; a--)
            {
                Unit tUnit = mShowUnitList[a];
                UnitMgr.instance.SetUnitActive(tUnit, false, false, true);
                mShowUnitList.RemoveAt(a);
            }
        }
    }
}