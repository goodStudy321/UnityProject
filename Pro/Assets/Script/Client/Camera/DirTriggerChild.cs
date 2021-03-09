using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

/// <summary>
/// 角色进入/退出Collider旋转摄像机Y轴位置
/// </summary>
public class DirTriggerChild : MonoBehaviour
{
    private GameObject mParent = null;
    private CameraRotateBind mCRB = null;


    private void Awake()
    {
        if (transform.parent == null)
            return;

        mParent = transform.parent.gameObject;
        mCRB = mParent.GetComponent<CameraRotateBind>();
    }

    private void Start()
    {
        
    }

    private void OnTriggerEnter(Collider other)
    {
        if (mCRB == null)
            return;

        if (InputVectorMove.instance.MoveUnit == null || InputVectorMove.instance.MoveUnit.mUnitMove == null)
            return;

        //if (!IsTrigger && InputVectorMove.instance.MoveUnit.mUnitMove.InPathFinding == false) return;

        if (other.name != InputVectorMove.instance.MoveUnit.UnitTrans.name)
            return;

        mCRB.EnterChildChecker(this);
    }

    private void OnTriggerExit(Collider other)
    {
        if (mCRB == null)
            return;

        if (InputVectorMove.instance.MoveUnit == null || InputVectorMove.instance.MoveUnit.mUnitMove == null)
            return;

        if (InputVectorMove.instance.MoveUnit.mUnitMove.InPathFinding == false)
            return;

        if (other.name != InputVectorMove.instance.MoveUnit.UnitTrans.name)
            return;

        mCRB.ExitChildChecker(this);
    }
}
