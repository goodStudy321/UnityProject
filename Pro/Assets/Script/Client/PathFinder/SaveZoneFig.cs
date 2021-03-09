using UnityEngine;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;


public class SaveZoneFig : MonoBehaviour
{
    /// <summary>
    /// 检测进入标记
    /// </summary>
    private static int mCheckEnterTime = 0;
	
    private void Awake()
    {
        if (mCheckEnterTime <= 0)
        {
            mCheckEnterTime = 0;
        }
    }

    private void Start()
    {
        
    }

    private void OnDestroy()
    {
        
    }

    void OnTriggerEnter(Collider other)
    {
        if (InputMgr.instance.mOwner == null)
            return;

        if (other.transform != InputMgr.instance.mOwner.UnitTrans)
        {
            return;
        }
        
        mCheckEnterTime++;
        if (mCheckEnterTime == 1)
        {
            EventMgr.Trigger("EnterSaveZone");
            UITip.LocalLog(690011);
            return;
        }
    }

    void OnTriggerExit(Collider other)
    {
        if (other.transform == InputMgr.instance.mOwner.UnitTrans)
        {
            mCheckEnterTime--;
            if(mCheckEnterTime == 0)
            {
                EventMgr.Trigger("ExitSaveZone");
                UITip.LocalLog(690012);
            }
            if (mCheckEnterTime < 0)
            {
                mCheckEnterTime = 0;
            }
        }
    }
}
