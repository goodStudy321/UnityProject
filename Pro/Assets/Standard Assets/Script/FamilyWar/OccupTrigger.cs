using Loong.Game;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class OccupTrigger : MonoBehaviour {
    //占领区域index
    public int Index;

    private void OnTriggerEnter(Collider other)
    {
        if (other.tag == "FamilyWarSelf")
        {
            EventMgr.Trigger("OccupPlayerEnter", Index);
        }
    }

    private void OnTriggerExit(Collider other)
    {
        if (other.tag == "FamilyWarSelf")
        {
            EventMgr.Trigger("OccupPlayerExit", Index);
        }
    }
}
