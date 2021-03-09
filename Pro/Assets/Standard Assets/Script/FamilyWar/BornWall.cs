using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BornWall : MonoBehaviour {

    private void Awake()
    {
        EventMgr.Add("FamilyWarBornChg", ChgWallState);
    }

    private void ChgWallState(params object[] args)
    {
        bool state = (bool)args[0];
        gameObject.SetActive(state);
    }

    private void OnDestroy()
    {
        EventMgr.Remove("FamilyWarBornChg", ChgWallState);
    }

}
