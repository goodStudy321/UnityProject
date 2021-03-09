using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class CameraPlayerOldOperation : CameraOperationBase
{
    private CameraInfo.vector3 mCamPos;
    private CameraInfo.vector3 mCamEuler;
    /// <summary>
    /// 摄像机配置表ID
    /// </summary>
    private uint CAMERA_ID;
    /// <summary>
    /// 角色对象控制器
    /// </summary>
    private Transform mPlayerTrans;
    /// <summary>
    /// 相机数据
    /// </summary>
    private CameraInfo mCameraInfo;
    private float mMaxRadius;
    private float mMinHeight;
    private float mMaxHeight;
    /// <summary>
    /// 半径
    /// </summary>
    private float mRadius;
    /// <summary>
    /// 高度
    /// </summary>
    private float mHeight;
    /// <summary>
    /// 摄像机竖直方向的角度
    /// </summary>
    public float mVerticalAngle;
    /// <summary>
    /// 摄像机水平环绕角色的角度
    /// </summary>
    public float mHorizontalAngle;
    /// <summary>
    /// 镜头旋转速度比率
    /// </summary>
    public float mRotateFactor = 0.5f;
    /// <summary>
    /// 持续抖动的时长
    /// </summary>
    public float mShake = 0.0f;
    /// <summary>
    /// 振幅越大抖动越厉害
    /// 抖动幅度（振幅）
    /// </summary>
    public float shakeAmount = 0.1f;
    public float decreaseFactor = 1.0f;
    /// <summary>
    /// 调试状态
    /// </summary>
    public bool IsDebug = false;
    private bool mIsChangeRadius = false;
    private bool mIsChange = false;
    /// 摄像机改变需要的速率
    private float mRadiusSpeed;
    private float mHeightSpeed;
    private float mVerticalSpeed;
    private float mHorizontalSpeed;
    private float mFOVSpeed;
    ///记录原来的参数
    private float mRestoreRadius;
    private float mRestoreHeight;
    private float mRestoreVerticalAngle;
    private float mRestoreHorizontalAngle;
    private float mRestoreFOV;
    private float mRestoreFCP;
    private float mRestoreNCP;
    /// <summary>
    /// 新的参数
    /// </summary>
    private float mNewRadius;
    private float mNewHeight;
    private float mNewVerticalAngle;
    private float mNewHorizontalAngle;
    private float mNewFOV;
    //暂未使用
    //private float mNewFCP;      
    //暂未使用  
    //private float mNewNCP;

    public CameraPlayerOldOperation(Camera camera):base(camera)
    {

    }

    #region 私有函数

    /// <summary>
    /// 更新水平角度移动
    /// </summary>
    private void UpdateHorizontalAngle()
    {
        if (JoyStickCtrl.instance.IsTouch) return;
        float axis = 0f;
#if UNITY_EDITOR                                
        if (Input.GetMouseButton(1))
        {
            axis = Input.GetAxis("Mouse X");
        }
#elif UNITY_IPHONE || UNITY_ANDROID || UNITY_WP8 || UNITY_WP_8_1 || UNITY_BLACKBERRY
        if (Input.touchCount > 0 && Input.GetTouch(0).phase == TouchPhase.Moved)
        {
            Vector2 delta = Input.GetTouch(0).deltaPosition;
            axis = delta.x;
        }
#endif
        mHorizontalAngle += axis * mRotateFactor;
    }
    #endregion

    #region 保护函数
    protected override bool Check()
    {
        if (mPlayerTrans == null)
        {
            iTrace.eError("HS", "角色摄像机没有目标，mPlayerObj is null!!");
            return false;
        }
        if (!IsDebug && mCameraInfo == null)
        {
            iTrace.eError("HS", string.Format("摄像机配置表为空,CameraInfo id = {0} is null!!", CAMERA_ID));
            return false;
        }
        return true;
    }

    protected override void UpdateCustom()
    {
        if (mPlayerTrans == null || mPlayerTrans.ToString() == "null") return;
        if (transform == null) return; 
        IsRaycastHit();
        if(!User.instance.IsLockCameraRota) UpdateHorizontalAngle();
        Vector3 targetPos = mPlayerTrans.position;
        var x = targetPos.x + mRadius * Mathf.Sin((180 + mHorizontalAngle) * Mathf.Deg2Rad);
        var y = targetPos.y + mHeight;
        var z = targetPos.z + mRadius * Mathf.Cos(( 180 - mHorizontalAngle) * Mathf.Deg2Rad);
        transform.position = new Vector3(x, y, z);
        transform.eulerAngles = new Vector3(mVerticalAngle, mHorizontalAngle, 0);
        if (mShake > 0)
        {
            transform.position = transform.position + UnityEngine.Random.insideUnitSphere * shakeAmount;
            mShake -= Time.deltaTime * decreaseFactor;
        }
        else
        {
            mShake = 0f;
        }
    }
    #endregion

    #region 公开函数

    public bool IsShaking
    {
        set
        {
            if (value) mShake = 1.5f;
        }
    }

    /// <summary>
    /// 更新摄像机锁定对象
    /// </summary>
    public void UpdatePlayerObj(GameObject go)
    {
        if (go == null)
        {
            iTrace.eError("HS", "传入角色摄像机控制的角色对象为null!!");
            return;
        }
        mPlayerTrans = go.transform;
        CapsuleCollider cc = go.GetComponent<CapsuleCollider>();
        mMinHeight = cc != null ? go.transform.position.y + cc.center.y + cc.height: go.transform.position.y;
        CameraInfo info = CameraInfoManager.instance.Find(GameSceneManager.instance.SceneInfo.camSet);
        UpdateCameraData(info);
    }

    /// <summary>
    /// 更新摄像机配置数据
    /// </summary>
    public void UpdateCameraData(CameraInfo info)
    {
        Clean();
        if (info == null) return;
        mCameraInfo = info;
        CAMERA_ID = mCameraInfo.id;
        if (!Check()) return;
        if (IsDebug) return;
        if ((CameraType)info.type == CameraType.Player)
        {
            mCamPos = info.start.list[0];
            mCamEuler = info.euler.list[0];
        }
        else if ((CameraType)info.type == CameraType.Camp)
        {
            int camp = User.instance.MapData.Camp - 1;
            if (info.start.list.Count <= camp || info.euler.list.Count <= camp)
            {
                iTrace.eError("hs", "阵营摄像机缺少配置");
                return;
            }
            mCamPos = info.start.list[camp];
            mCamEuler = info.euler.list[camp];
        }
        Vector3 pos = new Vector3(mCamPos.x, mCamPos.y, mCamPos.z);
        Vector3 euler = new Vector3(mCamEuler.x, mCamEuler.y, mCamEuler.z);
        UpdateCameraInfo(pos, euler);
    }

    #region 修改相对位置
    /// <summary>
    /// 修改X坐标
    /// </summary>
    public void ChangeCameraPosX(float x, float time)
    {
        time *= 100;
        RestoreData();
        Vector3 pos = CameraMgr.Main.transform.position - transform.position;
        pos.x = x / 100.0f;
        mNewRadius = Vector3.Distance(Vector3.zero, new Vector3(pos.x, 0, pos.z));
        mRadiusSpeed = mNewRadius != 0 ? (mNewRadius - mRadius) / time : 0;
        StartCoroutine();
    }

    /// <summary>
    /// 修改X坐标
    /// </summary>
    public void ChangeCameraPosY(float y, float time)
    {
        time *= 100;
        RestoreData();
        Vector3 pos = CameraMgr.Main.transform.position - transform.position;
        pos.y = y / 100.0f;
        mNewHeight = pos.y;
        mHeightSpeed = mNewHeight != 0 ? (mNewHeight - mHeight) / time : 0;
        StartCoroutine();
    }

    /// <summary>
    /// 修改X坐标
    /// </summary>
    public void ChangeCameraPosZ(float z, float time)
    {
        time *= 100;
        RestoreData();
        Vector3 pos = CameraMgr.Main.transform.position - transform.position;
        pos.z = z / 100.0f;
        mNewRadius = Vector3.Distance(Vector3.zero, new Vector3(pos.x, 0, pos.z));
        mRadiusSpeed = mNewRadius != 0 ? (mNewRadius - mRadius) / time : 0;
        StartCoroutine();
    }

    /// <summary>
    /// 改变x轴角度
    /// </summary>
    public void ChangeCameraEulerX(float x, float time)
    {
        time *= 100;
        RestoreData();
        mNewVerticalAngle = x / 100.0f;
        mVerticalSpeed = mNewVerticalAngle != 0 ? (mNewVerticalAngle - mVerticalAngle) / time : 0;
        StartCoroutine();
    }

    /// <summary>
    /// 改变y轴角度
    /// </summary>
    public void ChangeCameraEulerY(float y, float time)
    {
        time *= 100;
        RestoreData();
        mNewHorizontalAngle = y / 100.0f;
        mHorizontalSpeed = mNewHorizontalAngle != 0 ? (mNewHorizontalAngle - mHorizontalAngle) / time : 0;
        StartCoroutine();
    }

    /// <summary>
    /// 修改坐标
    /// </summary>
    public void ChangeCameraPos(Vector3 pos, float time = 2.0f)
    {
        time *= 100;
        RestoreData();
        pos = pos / 100.0f;
        mNewRadius = Vector3.Distance(Vector3.zero, new Vector3(pos.x, 0, pos.z));
        mNewHeight = pos.y;
        mRadiusSpeed = mNewRadius != 0 ? (mNewRadius - mRadius) / time : 0;
        mHeightSpeed = mNewHeight != 0 ? (mNewHeight - mHeight) / time : 0;
        StartCoroutine();
    }

    public void ChangeCameraEuler(Vector3 euler, float time = 2.0f)
    {
        time *= 100;
        RestoreData();
        euler = euler / 100.0f;
        mNewVerticalAngle = euler.x;
        mNewHorizontalAngle = euler.y;
        mVerticalSpeed = mNewVerticalAngle != 0 ? (mNewVerticalAngle - mVerticalAngle) / time : 0;
        mHorizontalSpeed = mNewHorizontalAngle != 0 ? (mNewHorizontalAngle - mHorizontalAngle) / time : 0;
        StartCoroutine();
    }

    /// <summary>
    /// 修改fov
    /// </summary>
    public void ChangeCameraFOV(float fov, float time = 2.0f)
    {
        time *= 100;
        RestoreData();
        mNewFOV = fov;
        mFOVSpeed = mNewFOV != 0 ? (mNewFOV - Camera.fieldOfView) / time : 0;
        StartCoroutine();
    }

    public void ChangeCameraRadius(float radius, float height, float time = 2.0f)
    {
        time *= 100;
        RestoreData();
        mNewRadius = radius;
        mNewHeight = height;
        mRadiusSpeed = mNewRadius != 0 ? (mNewRadius - mRadius) / time : 0;
        mHeightSpeed = mNewHeight != 0 ? (mNewHeight - mHeight) / time : 0;
        StartCoroutine();
    }

    /// <summary>
    /// 缓存数据
    /// </summary>
    private void RestoreData()
    {
        mRestoreRadius = mRadius;
        mRestoreHeight = mHeight;
        mRestoreVerticalAngle = mVerticalAngle;
        mRestoreHorizontalAngle = mHorizontalAngle;
        float curFOV = this.Camera.fieldOfView;
        float curFCP = this.Camera.farClipPlane;
        float curNCP = this.Camera.nearClipPlane;
        mRestoreFOV = curFOV;
        mRestoreFCP = curFCP;
        mRestoreNCP = curNCP;
    }
    #endregion

    #region 射线碰撞
    /// <summary>
    /// 射线碰撞
    /// </summary>
    /// <returns></returns>
    private void IsRaycastHit()
    {


        //这里是计算射线的方向，从主角发射方向是射线机方向
        Vector3 aim = mPlayerTrans.position;
        Vector3 startPos = new Vector3(mPlayerTrans.position.x, mMinHeight, mPlayerTrans.position.z);
        //Vector3 camPos = new Vector3(transform.position.x, mMinHeight, transform.position.z);
        //得到方向
        Vector3 ve = (startPos - transform.position).normalized;
        float an = transform.eulerAngles.y;
        aim -= an * ve;
        //在场景视图中可以看到这条射线
        Debug.DrawLine(startPos, aim, Color.red);
        //主角朝着这个方向发射射线
        RaycastHit hit;
        if (Physics.Linecast(startPos, aim, out hit, 1 << LayerTool.CameraWall))
        {
            if(hit.distance < mMaxRadius)
            {
                float radius = hit.distance;
                float height = Mathf.Abs(radius / Mathf.Tan(Mathf.Abs( 90 - mVerticalAngle)));
                if (height < mMinHeight) height = mMinHeight;
                ChangeCameraRadius(radius, height, height < mHeight ? height / mHeight : mHeight / height);
                mIsChangeRadius = true;
            }
            else if (mIsChangeRadius == true)
            {
                mIsChangeRadius = false;
                mRestoreRadius = mMaxRadius;
                mRestoreHeight = mMaxHeight;
                RestoreCamearInfo(0.7f, 0.7f, 0.7f, 0.7f, 0.7f);
            }
        }
        else if(mIsChangeRadius == true)
        {
            mIsChangeRadius = false;
            mRestoreRadius = mMaxRadius;
            mRestoreHeight = mMaxHeight;
            RestoreCamearInfo(0.2f);
        }
    }

    #endregion

    private void StartCoroutine()
    {
        if (mIsChange == true) return;
        mIsChange = true;
        ITweenCallbackTool.Instance.StartCoroutine(ChanageCamera());
    }

    IEnumerator ChanageCamera()
    {
        while (mRadius != mNewRadius || mHeight != mNewHeight || mVerticalAngle != mNewVerticalAngle || mHorizontalAngle != mNewHorizontalAngle || this.Camera.fieldOfView != mNewFOV)
        {
            yield return new WaitForFixedUpdate();
            mRadius += mRadiusSpeed;
            if (mRadiusSpeed > 0 && mRadius > mNewRadius || mRadiusSpeed < 0 && mRadius < mNewRadius) mRadius = mNewRadius;
            mHeight += mHeightSpeed;
            if (mHeightSpeed > 0 && mHeight > mNewHeight || mHeightSpeed < 0 && mHeight < mNewHeight) mHeight = mNewHeight;
            mVerticalAngle += mVerticalSpeed;
            if (mVerticalSpeed > 0 && mVerticalAngle > mNewVerticalAngle || mVerticalSpeed < 0 && mVerticalAngle < mNewVerticalAngle) mVerticalAngle = mNewVerticalAngle;
            mHorizontalAngle += mHorizontalSpeed;
            if (mHorizontalSpeed > 0 && mHorizontalAngle > mNewHorizontalAngle || mHorizontalSpeed < 0 && mHorizontalAngle < mNewHorizontalAngle) mHorizontalAngle = mNewHorizontalAngle;
            this.Camera.fieldOfView += mFOVSpeed;
            if (this.Camera.fieldOfView != mFOVSpeed)
                CameraMgr.Refresh();
            if (mFOVSpeed > 0 && this.Camera.fieldOfView > mNewFOV || mFOVSpeed < 0 && this.Camera.fieldOfView < mNewFOV)
            {
                this.Camera.fieldOfView = mNewFOV;
            }
        }
        mIsChange = false;
    }

    /// <summary>
    /// 还原摄像机配置
    /// </summary>
    public void RestoreCamearInfo(float radiusTimer = 2.0f, float heightTimer = 2.0f, float verticalTimer = 2.0f, float horizontalTimer = 2.0f, float fovTimer = 2.0f)
    {
        radiusTimer *= 100;
        heightTimer *= 100;
        verticalTimer *= 100;
        horizontalTimer *= 100;
        fovTimer *= 100;


        mNewRadius = mRestoreRadius;
        mNewHeight = mRestoreHeight;
        mNewVerticalAngle = mRestoreVerticalAngle;
        mNewHorizontalAngle = mRestoreHorizontalAngle;
        mNewFOV = mRestoreFOV;

        mRadiusSpeed = mNewRadius != 0 ? (mNewRadius - mRadius) / radiusTimer : 0;
        mHeightSpeed = mNewHeight != 0 ? (mNewHeight - mHeight) / heightTimer : 0;
        mVerticalSpeed = mNewVerticalAngle != 0 ? (mNewVerticalAngle - mVerticalAngle) / verticalTimer : 0;
        mHorizontalSpeed = mNewHorizontalAngle != 0 ? (mNewHorizontalAngle - mHorizontalAngle) / horizontalTimer : 0;
        mFOVSpeed = mNewFOV != 0 ? (mNewFOV - Camera.fieldOfView) / fovTimer : 0;


        Camera.farClipPlane = mRestoreFCP;
        Camera.nearClipPlane = mRestoreNCP;
        if (mIsChange == true) return;
        mIsChange = true;
        ITweenCallbackTool.Instance.StartCoroutine(ChanageCamera());
    }

    /// <summary>
    /// 更新摄像机配置数据
    /// </summary>
    public void UpdateCameraInfo(Vector3 pos, Vector3 euler)
    {
        pos = pos / 100.0f;
        euler = euler / 100.0f;
        mRadius = Vector3.Distance(Vector3.zero, new Vector3(pos.x, 0, pos.z));
        mMaxRadius = mRadius;
        mHeight = pos.y;
        mMaxHeight = mHeight;
        mVerticalAngle = euler.x;
        mHorizontalAngle = euler.y;
//         if (info == null) return;
//          mCameraInfo = info;
//          Vector3 pos = new Vector3(info.start.x, 0, info.start.z) / 100.0f;
//          mRadius = Vector3.Distance(Vector3.zero, pos);
//          mHeight = info.start.y != 0 ? info.start.y / 100.0f : info.heightMin;
//          mVerticalAngle = info.euler.x / 100.0f;
//          mHorizontalAngle = info.euler.y / 100.0f;
    }

    public override void Focus()
    {
        if (!Check()) return;
        UpdateCustom();
    }

    public override void Focus(Vector3 position)
    {
    }

    public override void FocusSelf()
    {
        Focus();
    }

    private void Clean()
    {
        mRadiusSpeed = 0;
        mHeightSpeed = 0;
        mVerticalSpeed = 0;
        mHorizontalSpeed = 0;
        mFOVSpeed = 0;
        mRestoreRadius = 0;
        mRestoreHeight = 0;
        mRestoreVerticalAngle = 0;
        mRestoreHorizontalAngle = 0;
        mRestoreFOV = 0;
        mRestoreFCP = 0.3f;
        mRestoreNCP = 1000f;
        mNewRadius = 0;
        mNewHeight = 0;
        mNewVerticalAngle = 0;
        mNewHorizontalAngle = 0;
        mNewFOV = 0;
        //mNewFCP = 0;
        //mNewNCP = 0;
}
    #endregion
}
