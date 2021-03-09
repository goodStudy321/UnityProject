using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using ProtoBuf;

public class AttackSummonUnitEvent : SummonUnitEvent
{
    public AttackSummonUnitEvent(EventData data, Unit parentUnit, Vector3 targetPosition) :
        base(data, targetPosition, parentUnit)
    {
        if (parentUnit != null)
            mCamp = parentUnit.Camp;
        else
            mCamp = CampType.CampType1;
    }
}
