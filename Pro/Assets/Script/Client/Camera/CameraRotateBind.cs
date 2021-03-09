using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

/// <summary>
/// 角色进入/退出Collider旋转摄像机Y轴位置
/// </summary>
public class CameraRotateBind : MonoBehaviour
{
    //private float OldEulerAngles = 0;
    /// <summary>
    /// 进入时Y轴的角度
    /// </summary>
    [SerializeField]
    public float TargetAngles = 0;
    [SerializeField]
    public bool Opposite = false;

    public DirTriggerChild dTrgger1;
    public DirTriggerChild dTrgger2;

    //private bool hasTrigger = false;
    private bool inTrigger1 = false;
    private bool inTrigger2 = false;

    private CameraPlayerNewOperation operation;
    private CameraPlayerNewOperation Operation
    {
        get
        {
            if (operation == null)
                GetOperation();
            return operation;
        }
    }





    //private bool IsBlack = false;
    public bool IsTrigger = false;

    public float Speed = 150f;

    

    private void Start()
    {
        GetOperation();
    }

    private void GetOperation()
    {
        if (CameraMgr.CamOperation is CameraPlayerNewOperation)
        {
            operation = CameraMgr.CamOperation as CameraPlayerNewOperation;
        }
    }

    //private void OnTriggerEnter(Collider other)
    //{
    //    if (InputVectorMove.instance.MoveUnit == null || InputVectorMove.instance.MoveUnit.mUnitMove == null) return;
    //    if (!IsTrigger && InputVectorMove.instance.MoveUnit.mUnitMove.InPathFinding == false) return;
    //    if (other.name != InputVectorMove.instance.MoveUnit.UnitTrans.name) return;
    //    //if (OldEulerAngles == 0) OldEulerAngles = Operation.mHorizontalAngle * 100.0f;
    //    if (OldEulerAngles == 0) OldEulerAngles = Operation.TarHrzAngle * 100.0f;
    //    Operation.ChangeCameraEulerY(IsBlack ? OldEulerAngles : TargetAngles * 100.0f, Speed, true);
    //}

    //private void OnTriggerExit(Collider other)
    //{
    //    if (InputVectorMove.instance.MoveUnit == null || InputVectorMove.instance.MoveUnit.mUnitMove == null) return;
    //    if (!IsTrigger && InputVectorMove.instance.MoveUnit.mUnitMove.InPathFinding == false) return;
    //    if (other.name != InputVectorMove.instance.MoveUnit.UnitTrans.name) return;
    //    if (IsBlack) OldEulerAngles = 0;
    //    IsBlack = !IsBlack;
    //}


    /// <summary>
    /// 子触发器触发
    /// </summary>
    /// <param name="dTChild"></param>
    public void EnterChildChecker(DirTriggerChild dTChild)
    {
        if (dTChild == null)
            return;

        if(dTChild == dTrgger1)
        {
            inTrigger1 = true;
            /// 触发反向 ///
            if (inTrigger2 == true)
            {
                if(Opposite == true)
                {
                    Operation.ChangeCameraEulerY(/*IsBlack ? OldEulerAngles :*/ TargetAngles * 100.0f, Speed, true);
                }
                else
                {
                    Operation.ChangeCameraEulerY( Operation.DefHrzAngle * 100.0f, Speed, true);
                }
                //hasTrigger = true;
            }
        }
        else if(dTChild == dTrgger2)
        {
            inTrigger2 = true;
            /// 触发正向 ///
            if (inTrigger1 == true)
            {
                if (Opposite == true)
                {
                    Operation.ChangeCameraEulerY(Operation.DefHrzAngle * 100.0f, Speed, true);
                }
                else
                {
                    Operation.ChangeCameraEulerY(/*IsBlack ? OldEulerAngles :*/ TargetAngles * 100.0f, Speed, true);
                }
                //hasTrigger = true;
            }
        }
    }

    public void ExitChildChecker(DirTriggerChild dTChild)
    {
        if (dTChild == null)
            return;

        if (dTChild == dTrgger1)
        {
            inTrigger1 = false;
        }
        else if (dTChild == dTrgger2)
        {
            inTrigger2 = false;
        }

        //if(inTrigger1 == false && inTrigger2 == false)
        //{
        //    if (hasTrigger == true)
        //    {
        //        hasTrigger = false;
        //    }
        //}
    }
}
