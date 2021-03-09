using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UnitFrMove : MonoBehaviour
{
    //单位
    private Unit mUnit;
    private Matrix4x4 mMatrix = Matrix4x4.identity;
    private Quaternion mQuat = Quaternion.identity;
    //起始点
    private Vector3 mStartPos;
    //目标点
    private Vector3 mDesPos;
    //移动方向
    private Vector3 mForward;
    //移动速度
    private float mMovSpeed;
    //段移动时间
    private float mSegTime;
    //当前时间
    private float mCurTime;
    //时间率
    private float mRadio;
    //移动时间
    public float mMoveTime = 5;
	// Use this for initialization
	void Start ()
    {
        mUnit = InputMgr.instance.mOwner;
        mCurTime = 0;
        SetMatrix(mUnit);
        SetMoveSpeed(mUnit);
        SetNextPosInfo();
	}

    /// <summary>
    /// 设置四元素
    /// </summary>
    /// <param name="pos"></param>
    /// <param name="orient"></param>
    private void SetMatrix(Unit unit)
    {
        if (unit == null)
            return;
        Vector3 forward = mUnit.UnitTrans.forward;
        float orient = Mathf.Atan2(forward.x, forward.z);
        mQuat = Quaternion.Euler(0, orient * Mathf.Rad2Deg, 0);
        mMatrix = Matrix4x4.TRS(mUnit.Position, mQuat, Vector3.one);
    }

    /// <summary>
    /// 设置移动速度
    /// </summary>
    /// <param name="unit"></param>
    private void SetMoveSpeed(Unit unit)
    {
        if (unit == null)
            return;
        mMovSpeed = unit.MoveSpeed * 2;
    }

    /// <summary>
    /// 设置自由移动点
    /// </summary>
    private Vector3 GetDeltaPoint()
    {
        float moveDisX = Random.Range(-3, 3);
        float moveDisZ = Random.Range(-3, 3);
        return new Vector3(moveDisX, 0, moveDisZ);
    }

    /// <summary>
    /// 获取随机位置
    /// </summary>
    /// <returns></returns>
    private Vector3 GetRmdPos()
    {
        Vector3 delPos = GetDeltaPoint();
        Vector3 pos = mMatrix.MultiplyPoint(delPos);
        return pos;
    }

    /// <summary>
    /// 移动
    /// </summary>
    private bool Move()
    {
        if (mUnit == null)
            return false;
        if (mRadio >= 1)
            return false;
        ExecuteRotation();
        mUnit.ActionStatus.ChangeMoveAction();
        mCurTime += Time.deltaTime;
        mRadio = mCurTime / mSegTime;
        Vector3 pos = BezierTool.GetLinearPoint(mStartPos, mDesPos, mRadio);
        mUnit.Position = pos;
        NetMove.SendMove(mUnit, pos, SendMoveType.SendStickMove);
        return true;
    }

    /// <summary>
    /// 执行旋转
    /// </summary>
    /// <param name="forward"></param>
    private void ExecuteRotation()
    {
        float fowardSqr = Vector3.SqrMagnitude(mUnit.UnitTrans.forward - mForward);
        if (fowardSqr < 0.01f)
            return;
        float rotateSpeed = mUnit.ActionStatus.ActiveAction.RotateSpeed;
        mUnit.SetOrientation(Mathf.Atan2(mForward.x, mForward.z), rotateSpeed);
    }

    /// <summary>
    /// 设置下一点
    /// </summary>
    private void SetNextPosInfo()
    {
        mStartPos = mUnit.Position;
        mDesPos = GetRmdPos();
        mForward = (mDesPos - mStartPos).normalized;
        mRadio = 0;
        mCurTime = 0;
        float dis = Vector3.Distance(mStartPos, mDesPos);
        mSegTime = dis / mMovSpeed;
    }

    // Update is called once per frame
    void Update ()
    {
        float yPos = FindHelper.instance.GetOwnerPos().y;
        mMoveTime -= Time.deltaTime;
        if (mMoveTime <= 0)
        {
            mUnit.ActionStatus.ChangeIdleAction();
            DestroyMy();
            return;
        }
        else if (yPos > 13.2f)
        {
            DestroyMy();
        }

        if (Move())
            return;
        SetNextPosInfo();
	}

    void DestroyMy()
    {
        long point = NetMove.GetPointInfo(mUnit.Position, mUnit.UnitTrans.localEulerAngles.y);
        NetMove.RequestStopMove(point);
        GameObject.Destroy(this);
    }

    private void OnDestroy()
    {
        if (mUnit == null)
            return;
        if (mUnit.ActionStatus == null)
            return;
        mUnit.ActionStatus.ChangeIdleAction();
    }
}
