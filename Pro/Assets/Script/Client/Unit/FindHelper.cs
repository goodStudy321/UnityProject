using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FindHelper
{
    public static readonly FindHelper instance = new FindHelper();
    private FindHelper() { }
    /// <summary>
    /// 根据距离随机获取单位
    /// </summary>
    /// <param name="dis"></param>
    /// <returns></returns>
    public long GetRdmUnitByDis(float dis)
    {
        Unit unit = InputMgr.instance.mOwner;
        if (unit == null)
            return 0;
        List<long> list = new List<long>();
        for(int i = 0; i < UnitMgr.instance.UnitList.Count; i++)
        {
            Unit target = UnitMgr.instance.UnitList[i];
            if (target == null)
                continue;
            if (target.Dead)
                continue;
            if (unit == target)
                continue;
            UnitType unitType = UnitHelper.instance.GetUnitType(target.TypeId);
            if (unitType != UnitType.Role)
                continue;
            float distance = Vector3.Distance(unit.Position , target.Position);
            if (distance > dis)
                continue;
            list.Add(target.UnitUID);
        }
        int count = list.Count;
        if (count == 0)
            return 0;
        int index = Random.Range(0, count);
        return list[index];
    }

    /// <summary>
    /// 获取自己y轴位置
    /// </summary>
    /// <returns></returns>
    public Vector3 GetOwnerPos()
    {
        Unit unit = InputVectorMove.instance.MoveUnit;
        if (unit == null)
            return Vector3.zero;
        return unit.Position;
    }

    /// <summary>
    /// 获取自身游戏物体
    /// </summary>
    /// <returns></returns>
    public GameObject GetSelfGo()
    {
        Unit unit = InputMgr.instance.mOwner;
        return unit.UnitTrans.gameObject;
    }
}
