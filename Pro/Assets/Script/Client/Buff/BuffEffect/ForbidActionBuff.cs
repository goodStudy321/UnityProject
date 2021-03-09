using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ForbidActionBuff : BuffUnit
{
    #region ˽���ֶ�
    private byte mForbidBit = 0;
    #endregion

    #region ���з���
    public ForbidActionBuff(BufSetup bufSetup, Unit owner, object[] param) :
        base(bufSetup, owner, param)
    {
        mForbidBit = BuffTypeDefine.mForbidActionDic[bufSetup.mBufBaseInfo.effectType];
    }

    public override void Update(float DeltaTime)
    {
        byte ownerBit = mOwner.mUnitBuffStateInfo.ForbidType;
        ownerBit |= mForbidBit;
        mOwner.mUnitBuffStateInfo.ForbidType = ownerBit;

    }

    public override void OnDestroy()
    {
        byte ownerBit = mOwner.mUnitBuffStateInfo.ForbidType;
        ownerBit &= (byte)~mForbidBit;
        mOwner.mUnitBuffStateInfo.ForbidType = ownerBit;
    }
    #endregion
}
