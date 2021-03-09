using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EndPoint : MonoBehaviour {

	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		
	}

    private void OnTriggerEnter(Collider other)
    {
        if (InputVectorMove.instance.MoveUnit == null || InputVectorMove.instance.MoveUnit.mUnitMove == null) return;
        if (other.name != InputVectorMove.instance.MoveUnit.UnitTrans.name) return;
        if (HangupMgr.instance.IsAutoHangup == true) return;
        EventMgr.Trigger(EventKey.MissNavPathTrigger);  
    }
}
