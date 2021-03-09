using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;
using System;

public class CameraPlayerNewOperation : CameraOperationBase
{
    #region 参数

    /// <summary>
    /// 镜头旋转速度比率
    /// </summary>
    public float mRotateFactor = 1f;
    /// <summary>
    /// 改变高度速率
    /// </summary>
    public float mHeightFactor = 10.0f;
    /// <summary>
    /// 改变竖直方向的角度速率
    /// </summary>
    public float mVAngleFactor = 10.0f;

    /// <summary>
    /// 持续抖动的时长
    /// </summary>
    public float mShake = 0.0f;
    /// <summary>
    /// 振幅越大抖动越厉害
    /// 抖动幅度（振幅）
    /// </summary>
    public float shakeAmount = 0.1f;
    /// <summary>
    /// 消长因素
    /// </summary>
    public float decreaseFactor = 1.0f;

    public float value = 100.0f;

    public float mVAngleDis = 0;

    #endregion

    /// <summary>
    /// 相机配置表
    /// </summary>
    private CameraInfo mCameraInfo = null;
    /// <summary>
    /// 摄像机初始位置结构
    /// </summary>
    private CameraInfo.vector3 mCamPosStruct;
    /// <summary>
    /// 摄像机初始欧拉角结构
    /// </summary>
    private CameraInfo.vector3 mCamEulerStruct;
    /// <summary>
    /// 摄像机初始位置
    /// </summary>
    private Vector3 mCamPos;
    /// <summary>
    /// 摄像机初始欧拉角
    /// </summary>
    private Vector3 mCamEuler;

    /// <summary>
    /// 相对目标最小半径
    /// </summary>
    private float mMinRToTar;
    /// <summary>
    /// 相对目标最大半径
    /// </summary>
    private float mMaxRToTar;
    /// <summary>
    /// 相对半径距离
    /// </summary>
    private float mRLen;
    
    /// <summary>
    /// 相对目标最小高度
    /// </summary>
    private float mMinHToTar = 0;
    /// <summary>
    /// 相对目标最大高度
    /// </summary>
    private float mMaxHToTar = 0;
    /// <summary>
    /// 相对高度距离
    /// </summary>
    private float mHLen = 0;

    /// <summary>
    /// 默认相对高度
    /// </summary>
    //private float mDefH = 0;
    /// <summary>
    /// 默认相机水平环绕角色角度
    /// </summary>
    private float mDefHrzAngle = 0;
    /// <summary>
    /// 默认相机垂直环绕角色角度
    /// </summary>
    private float mDefVtlAngle = 0;
    /// <summary>
    /// 默认Fov
    /// </summary>
    private float mDefFov = 50;

    /// <summary>
    /// 角色控制器
    /// </summary>
    private Transform mUnitTrans;
    /// <summary>
    /// 摄像机目标水平环绕角色的角度
    /// </summary>
    private float mTarHrzAngle;
    /// <summary>
    /// 
    /// </summary>
    private float mCurHrzAngle;
    private float mHrzV = 0.0f;

    /// <summary>
    /// 摄像机目标垂直角度
    /// </summary>
    private float mTarVtlAngle;
    /// <summary>
    /// 
    /// </summary>
    private float mCurVtlAngle;
    private float mVtlV = 0.0f;

    /// <summary>
    /// 
    /// </summary>
    private float mTarFov;
    private float mCurFov;
    private float mFovV = 0f;

    /// <summary>
    /// 目标高度
    /// </summary>
    private float mTarHeight;
    /// <summary>
    /// 
    /// </summary>
    private float mCurHeight;
    private float mHeightV = 0.0f;

    /// <summary>
    /// 当前半径
    /// </summary>
    private float mCurRadius;
    /// <summary>
    /// 角色高度
    /// </summary>
    private float mUnitHeight = 0f;
    /// <summary>
    /// 对焦中心点高度
    /// </summary>
    private float mLookAtHeight = 0f;
    /// <summary>
    /// 摄像机操作缓存信息
    /// </summary>
    private CameraOperationInfo mInfo;

    private bool mIsChange = false;
    private bool mInResetCam = false;
    private bool mLockAutoCam = false;
    /// <summary>
    /// 自动解锁控制
    /// </summary>
    private bool mAutoUnlock = false;
    /// <summary>
    /// 锁定水平旋转角度
    /// </summary>
    private bool mLockHrzAngle = false;
    /// <summary>
    /// 锁定旋转高度权重
    /// </summary>
    private float mLockRotHW = 0.25f;
    /// <summary>
    /// 旋转锁定高度
    /// </summary>
    private float mLockRotH = 0f;
    /// <summary>
    /// 开启水平角度旋转
    /// </summary>
    private bool useLockHrzRot = false;


    public bool UseLockHrzRot
    {
        get { return useLockHrzRot; }
        set { useLockHrzRot = value; }
    }
    /// <summary>
    /// 是否抖动摄像机
    /// </summary>
    public bool IsShaking
    {
        set
        {
            if (value) mShake = 1.5f;
            else mShake = 0.0f;
        }
    }
    /// <summary>
    /// 
    /// </summary>
    public float TarHrzAngle
    {
        get { return mTarHrzAngle; }
    }
    /// <summary>
    /// 
    /// </summary>
    public float DefHrzAngle
    {
        get { return mDefHrzAngle; }
    }
    /// <summary>
    /// 目标高度设置（判断锁定值）
    /// </summary>
    public float TarHeight
    {
        get { return mTarHeight; }
        set
        {
            mTarHeight = value;

            if (useLockHrzRot == false)
                return;

            if(mTarHeight <= mLockRotH)
            {
                mLockHrzAngle = false;
            }
            else
            {
                if(mLockHrzAngle == false)
                {
                    mTarHrzAngle = mDefHrzAngle;
                }
                mLockHrzAngle = true;
            }
        }
    }
    public float UnitHeight
    {
        get { return mUnitHeight; }
    }


    /// <summary>
    /// 初始化
    /// </summary>
    protected void Init()
    {
        mInfo = new CameraOperationInfo();

    }

    protected override bool Check()
    {
        if (mCameraInfo == null)
        {
            //iTrace.eError("hs", "摄像机数据为null");
            return false;
        }
        /// 摄像机不锁定角色 ///
        if (mCameraInfo.focus == 1)
        {
            return false;
        }
        if (mUnitTrans == null)
        {
            //iTrace.eError("hs", "没有角色目标");
            return false;
        }
        else if (mUnitTrans.name.ToString() == "null")
        {
            //iTrace.eError("hs", "角色目标已销毁");
            return false;
        }
        if (transform == null)
        {
            //iTrace.eError("hs", "没有场景摄像机");
            return false;
        }
        return true;
    }

    /// <summary>
    /// 重置摄像机参数
    /// </summary>
    protected void ResetCameraState()
    {
        mTarHrzAngle = mDefHrzAngle;
        mTarVtlAngle = mDefVtlAngle;
        TarHeight = mMaxHToTar;
        mTarFov = mDefFov;

        mCurHrzAngle = mTarHrzAngle;
        mCurHeight = TarHeight;
        mCurVtlAngle = mTarVtlAngle;
        mCurFov = mTarFov;
    }
    
    protected void CalCurRadius()
    {
        float hW = (mCurHeight - mMinHToTar) / mHLen;
        mCurRadius = (mRLen * hW) + mMinRToTar;
        if(mCurRadius > mMaxRToTar)
        {
            mCurRadius = mMaxRToTar;
        }
    }

    protected bool CanCtrlCam()
    {
        SceneInfo tInfo = GameSceneManager.instance.SceneInfo;
        if (tInfo != null && tInfo.forbidCamCtrl > 0)
        {
            return false;
        }

        return true;
    }

    /// <summary>
    /// 更新水平角度移动
    /// </summary>
    protected void UpdateHorizontalAngle()
    {
        if (mIsChange == true || mLockHrzAngle == true)
            return;

        //if (JoyStickCtrl.instance.IsTouch) return;
        if (JoyStickCtrl.instance.IsTouch || UITool.On == true || mLockAutoCam == true)
        {
            return;
        }
        float axis = 0f;
#if UNITY_EDITOR                                
        if (Input.GetMouseButton(1))
        {
            if (CanCtrlCam() == false)
            {
                return;
            }
            axis = Input.GetAxis("Mouse X");
        }
#elif UNITY_IPHONE || UNITY_ANDROID || UNITY_WP8 || UNITY_WP_8_1 || UNITY_BLACKBERRY
        if (Input.touchCount == 1 && Input.GetTouch(0).phase == TouchPhase.Moved)
        {
            if (CanCtrlCam() == false)
            {
                return;
            }
            Vector2 delta = Input.GetTouch(0).deltaPosition;
            axis = delta.x * 0.2f;
        }
#endif
        mTarHrzAngle += axis * mRotateFactor;
    }

    private void UpdateHight()
    {
        if (mIsChange == true)
            return;

        //if (JoyStickCtrl.instance.IsTouch) return;
        if (JoyStickCtrl.instance.IsTouch || UITool.On == true || mLockAutoCam == true)
        {
            return;
        }
        if (CanCtrlCam() == false)
        {
            return;
        }

        float axis = 0f;
#if UNITY_EDITOR
        axis = -Input.GetAxis("Mouse ScrollWheel");
        //iTrace.eLog("hs", "------------>>  " + axis);
#elif UNITY_IPHONE || UNITY_ANDROID || UNITY_WP8 || UNITY_WP_8_1 || UNITY_BLACKBERRY
            if(Input.touchCount > 1 )
            {
                if(Input.GetTouch(0).phase == TouchPhase.Moved && Input.GetTouch(1).phase == TouchPhase.Moved)
                {
                    float dis = Vector2.Distance(Input.GetTouch(0).position, Input.GetTouch(1).position);
                    if (mVAngleDis == 0)
                    {
                        mVAngleDis = dis;
                    }
                    else
                    {
                        if (dis != mVAngleDis)
                        {
                            //axis = mVAngleDis - dis > 0 ? -0.1f : 0.1f;
                            axis = mVAngleDis - dis > 0 ? 0.1f : -0.1f;
                        }
                    }
                }
                else
                {
                    mVAngleDis = 0;
                }
            }
#endif
        if (axis == 0)
            return;

        TarHeight += axis * mHeightFactor;
        if(TarHeight > mMaxHToTar)
        {
            TarHeight = mMaxHToTar;
        }
        if(TarHeight < mMinHToTar)
        {
            TarHeight = mMinHToTar;
        }
        //CalCurRadius();

        /// 计算垂直欧拉角 ///
        CalCurVtl();
    }

    /// <summary>
    /// 计算当前垂直欧拉角
    /// </summary>
    protected void CalCurVtl()
    {
        float hW = (TarHeight - mMinHToTar) / mHLen;
        float calR = (mRLen * hW) + mMinRToTar;
        if (calR > mMaxRToTar)
        {
            calR = mMaxRToTar;
        }

        Vector3 targetPos = mUnitTrans.position;
        var x = targetPos.x + calR * Mathf.Sin((180 + mTarHrzAngle) * Mathf.Deg2Rad);
        var y = targetPos.y + TarHeight;
        var z = targetPos.z + calR * Mathf.Cos((180 - mTarHrzAngle) * Mathf.Deg2Rad);
        Vector3 tCamPos = new Vector3(x, y, z);

        Vector3 tCamDesPos = new Vector3(targetPos.x, y, targetPos.z);
        //Vector3 tLookAtPos = new Vector3(targetPos.x, targetPos.y + mUnitHeight / 2, targetPos.z);
        Vector3 tLookAtPos = new Vector3(targetPos.x, targetPos.y + mLookAtHeight, targetPos.z);

        mTarVtlAngle = Vector3.Angle(tCamDesPos - tCamPos, tLookAtPos - tCamPos);
    }

    /// <summary>
    /// 计算总包围盒大小
    /// </summary>
    /// <param name="go"></param>
    /// <returns></returns>
    private float CalHeight(GameObject go)
    {
        if (go == null)
            return 4f;

        float retH = 4;
        CapsuleCollider[] cols = go.GetComponentsInChildren<CapsuleCollider>();
        if (cols != null)
        {
            for (int a = 0; a < cols.Length; a++)
            {
                float tH = cols[a].center.y + cols[a].height * 2;
                if(a == 0)
                {
                    retH = tH;
                }
                else
                {
                    if(tH > retH)
                    {
                        retH = tH;
                    }
                }
            }
        }

        return retH;
    }

    /// <summary>
    /// 更新摄像机状态
    /// </summary>
    protected void UpdateCameraStatus()
    {
        if (mUnitTrans == null)
            return;

        if(mIsChange == false && mLockAutoCam == false)
        {
            mCurHrzAngle = Mathf.SmoothDampAngle(mCurHrzAngle, mTarHrzAngle, ref mHrzV, 0.1f);
            mCurHeight = Mathf.SmoothDampAngle(mCurHeight, TarHeight, ref mHeightV, 0.15f);
            CalCurRadius();
            mCurVtlAngle = Mathf.SmoothDampAngle(mCurVtlAngle, mTarVtlAngle, ref mVtlV, 0.2f);
            mCurFov = Mathf.SmoothDampAngle(mCurFov, mTarFov, ref mFovV, 0.2f);

            //Vector3 targetPos = mUnitTrans.position;
            Vector3 targetPos = mUnitTrans.position;
            var x = targetPos.x + mCurRadius * Mathf.Sin((180 + mCurHrzAngle) * Mathf.Deg2Rad);
            var y = targetPos.y + mCurHeight;
            var z = targetPos.z + mCurRadius * Mathf.Cos((180 - mCurHrzAngle) * Mathf.Deg2Rad);
            transform.position = new Vector3(x, y, z);
            transform.eulerAngles = new Vector3(mCurVtlAngle, mCurHrzAngle, 0);
            Camera.fieldOfView = mCurFov;
        }
        else
        {
            Vector3 targetPos = mUnitTrans.position;
            var x = targetPos.x + mCurRadius * Mathf.Sin((180 + mCurHrzAngle) * Mathf.Deg2Rad);
            var y = targetPos.y + mCurHeight;
            var z = targetPos.z + mCurRadius * Mathf.Cos((180 - mCurHrzAngle) * Mathf.Deg2Rad);
            transform.position = new Vector3(x, y, z);
            transform.eulerAngles = new Vector3(mCurVtlAngle, mCurHrzAngle, 0);
            Camera.fieldOfView = mCurFov;
        }
    }

    /// <summary>
    /// 帧更新事件
    /// </summary>
    protected override void UpdateCustom()
    {
        if (!User.instance.IsLockCameraRota)
        {
            UpdateHorizontalAngle();
            UpdateHight();
            //UpdateFov();
        }
        UpdateAnim();
        UpdateCameraStatus();
        UpdateShake();
    }

    /// <summary>
    /// 更新动画
    /// </summary>
    protected void UpdateAnim()
    {
        if (!mIsChange)
        {
            CameraMgr.Refresh();
            return;
        }

        if (!mInfo.Change())
        {
            mIsChange = false;
            if(mAutoUnlock == true || mInResetCam == true)
            {
                mInResetCam = false;
                mLockAutoCam = false;
                mAutoUnlock = false;

                SetHrzAngle(mInfo.HA);
                SetHeight(mInfo.H);
                CalCurRadius();
                CalCurVtl();
                SetFov(mInfo.Fov);
                //Camera.fieldOfView = mInfo.Fov;

                CameraMgr.Refresh();
                return;
            }
        }

        ////mTarHeight = mInfo.H;
        //mCurHeight = mInfo.H;
        //mCurRadius = mInfo.R;
        ////mTarVtlAngle = mInfo.VA;
        //mCurVtlAngle = mInfo.VA;
        ////mTarHrzAngle = mInfo.HA;
        //mCurHrzAngle = mInfo.HA;

        SetHrzAngleImd(mInfo.HA);
        SetHeightImd(mInfo.H);
        SetRadiusImd(mInfo.R);
        SetVtlAngleImd(mInfo.VA);
        SetFovImd(mInfo.Fov);

        CameraMgr.Refresh();
    }

    protected void UpdateShake()
    {
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


    public CameraPlayerNewOperation(Camera camera) : base(camera)
    {
        Init();
    }

    /// <summary>
    /// 更新摄像机配置数据
    /// </summary>
    /// <param name="info"></param>
    public void UpdateCameraData(CameraInfo info)
    {
        mCameraInfo = info;

        if (!Check())
            return;

        /// 单人场景(取第一个) ///
        if ((CameraType)info.type == CameraType.Player)
        {
            mCamPosStruct = info.start.list[0];
            mCamEulerStruct = info.euler.list[0];
        }
        /// 阵型场景(根据阵型Id取相应的摄像机位置和欧拉角) ///
        else if ((CameraType)info.type == CameraType.Camp)
        {
            int camp = User.instance.MapData.Camp - 1;
            if (info.start.list.Count <= camp || info.euler.list.Count <= camp)
            {
                iTrace.eError("LY", "阵营摄像机缺少配置");
                return;
            }
            mCamPosStruct = info.start.list[camp];
            mCamEulerStruct = info.euler.list[camp];
        }

        mCamPos = new Vector3(mCamPosStruct.x, mCamPosStruct.y, mCamPosStruct.z) / 100f;
        mCamEuler = new Vector3(mCamEulerStruct.x, mCamEulerStruct.y, mCamEulerStruct.z) / 100f;
        /// 计算各种半径 ///
        mMaxRToTar = Vector3.Distance(Vector3.zero, new Vector3(mCamPos.x, 0, mCamPos.z));
        mMinRToTar = mMaxRToTar / 1.5f;
        mRLen = mMaxRToTar - mMinRToTar;
        /// 计算各种高度 ///
        mMaxHToTar = mCamPos.y;
        if (mUnitTrans == null)
        {
            mMinHToTar = 4f;
            mUnitHeight = 3;
        }
        mHLen = mMaxHToTar - mMinHToTar;
        mLockRotH = mMinHToTar + mHLen * mLockRotHW;
        
        /// 初始化各种角度 ///
        mDefHrzAngle = mCamEuler.y;
        mDefVtlAngle = mCamEuler.x;
        mDefFov = info.fov;

        mLookAtHeight = mMaxHToTar - Mathf.Tan(mDefVtlAngle * Mathf.Deg2Rad) * mMaxRToTar;

        if (mInfo == null) return;
        if (mInfo.Change()) return;

        ResetCameraState();
        //CalCurRadius();
        //CalCurVtl();
        mInfo.UpdateBase(mMaxHToTar, mMaxRToTar, mTarVtlAngle, mTarHrzAngle, info.fov);
    }

    public void SetMissionCameraInfo(CameraInfo info, float time)
    {
        mCameraInfo = info;

        if (!Check())
            return;
        

        mCamPosStruct = info.start.list[0];
        mCamEulerStruct = info.euler.list[0];
        mCamPos = new Vector3(mCamPosStruct.x, mCamPosStruct.y, mCamPosStruct.z) / 100f;
        mCamEuler = new Vector3(mCamEulerStruct.x, mCamEulerStruct.y, mCamEulerStruct.z) / 100f;
        /// 计算各种半径 ///
        mMaxRToTar = Vector3.Distance(Vector3.zero, new Vector3(mCamPos.x, 0, mCamPos.z));
        mMinRToTar = mMaxRToTar / 1.5f;
        mRLen = mMaxRToTar - mMinRToTar;
        /// 计算各种高度 ///
        mMaxHToTar = mCamPos.y;
        if (mUnitTrans == null)
        {
            mMinHToTar = 4f;
            mUnitHeight = 3;
        }
        mHLen = mMaxHToTar - mMinHToTar;
        mLockRotH = mMinHToTar + mHLen * mLockRotHW;

        /// 初始化各种角度 ///
        mDefHrzAngle = mCamEuler.y;
        mDefVtlAngle = mCamEuler.x;
        mDefFov = info.fov;

        mLookAtHeight = mMaxHToTar - Mathf.Tan(mDefVtlAngle * Mathf.Deg2Rad) * mMaxRToTar;

        //CalCurRadius();
        //CalCurVtl();
        //mInfo.UpdateTarget(mMaxHToTar, mMaxRToTar, mDefVtlAngle, mDefHrzAngle, mDefFov);
        //RestoreCamearInfo(time, time, time, time, time);

        //ResetCameraState();
        ResetCamToDefPos();
        //CalCurRadius();
        //CalCurVtl();
        mInfo.UpdateBase(mMaxHToTar, mMaxRToTar, mTarVtlAngle, mTarHrzAngle, info.fov);
    }


    /// <summary>
    /// 更新摄像机锁定对象
    /// </summary>
    public void UpdatePlayerObj(GameObject go, bool refresh = false)
    {
        if (go == null)
        {
#if UNITY_EDITOR
            iTrace.Log("LY", "传入角色摄像机控制的角色对象为null !!");
#endif
            return;
        }
        CameraMgr.ClearPullCam();
        mUnitTrans = go.transform;
        CapsuleCollider cc = go.GetComponent<CapsuleCollider>();
        //mMinHToTar = cc != null ? cc.center.y + cc.height / 2 : go.transform.position.y;
        //mMinHToTar = cc != null ? cc.center.y + cc.height * 2 : 4f;
        //mUnitHeight = cc.height;

        //float tH = CalHeight(go);
        mMinHToTar = CalHeight(go) * 0.7f;
        mUnitHeight = cc.height;
        mHLen = mMaxHToTar - mMinHToTar;
        mLockRotH = mMinHToTar + mHLen * mLockRotHW;
        if (TarHeight < mMinHToTar)
        {
            TarHeight = mMinHToTar;
        }
        CalCurVtl();

        if (refresh == true)
            return;

        MissionCameraInfo target = CameraMgr.ChangeMissCamera();
        if (target == null)
        {
            CameraInfo info = CameraInfoManager.instance.Find(GameSceneManager.instance.SceneInfo.camSet);
            UpdateCameraData(info);
        }
        else
        {
            CameraInfo info = CameraInfoManager.instance.Find((ushort)target.cameraId);
            if(info != null)
             UpdateCameraData(info);
        }
    }

    public void ChangeFollowObj(GameObject go)
    {
        if (go == null)
        {
#if UNITY_EDITOR
            iTrace.Log("LY", "传入跟随物体为空 !!");
#endif
            return;
        }
        CameraMgr.ClearPullCam();
        mUnitTrans = go.transform;

        CalCurVtl();
    }

    /// <summary>
    /// 重置摄像机到默认位置
    /// </summary>
    public void ResetCamToDefPos()
    {
        CameraMgr.ClearPullCam();

        mTarHrzAngle = mDefHrzAngle;
        TarHeight = mMaxHToTar;
        mTarVtlAngle = mDefVtlAngle;
        mTarFov = mDefFov;
    }

    public void ResetCamToDefPosImd()
    {
        CameraMgr.ClearPullCam();

        TarHeight = mMaxHToTar;
        mTarHrzAngle = mDefHrzAngle;
        mTarVtlAngle = mDefVtlAngle;
        mTarFov = mDefFov;

        mCurRadius = mMaxRToTar;
        mCurHeight = TarHeight;
        mCurHrzAngle = mTarHrzAngle;
        mCurVtlAngle = mTarVtlAngle;
        mCurFov = mTarFov;

        UpdateCameraStatus();
        CameraMgr.Refresh();
    }

    public override void Focus()
    {
        if (!Check())
            return;

        UpdateCustom();
    }

    public override void Focus(Vector3 position)
    {
        if (!Check())
            return;

        UpdateCustom();
    }

    public override void FocusSelf()
    {
        Focus();
    }

    /// <summary>
    /// 设置水平旋转角度
    /// </summary>
    /// <param name="hAngle"></param>
    public void SetHrzAngle(float hAngle)
    {
        mTarHrzAngle = hAngle;
    }

    /// <summary>
    /// 设置水平旋转角度(立即)
    /// </summary>
    /// <param name="hAngle"></param>
    public void SetHrzAngleImd(float hAngle)
    {
        SetHrzAngle(hAngle);
        mCurHrzAngle = hAngle;
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="fov"></param>
    public void SetFov(float fov)
    {
        mTarFov = fov;
    }

    public void SetFovImd(float fov)
    {
        SetFov(fov);
        mCurFov = fov;
    }

    /// <summary>
    /// 设置高度
    /// </summary>
    /// <param name="height"></param>
    public void SetHeight(float height)
    {
        mTarHeight = height;
    }

    /// <summary>
    /// 设置高度（立即）
    /// </summary>
    /// <param name="height"></param>
    public void SetHeightImd(float height)
    {
        SetHeight(height);
        mCurHeight = height;
    }

    /// <summary>
    /// 设置半径（立即）
    /// </summary>
    /// <param name="radius"></param>
    public void SetRadiusImd(float radius)
    {
        mCurRadius = radius;
    }

    /// <summary>
    /// 设置垂直角度
    /// </summary>
    /// <param name="vAngle"></param>
    public void SetVtlAngle(float vAngle)
    {
        mTarVtlAngle = vAngle;
    }

    /// <summary>
    /// 设置垂直角度（立即）
    /// </summary>
    /// <param name="vAngle"></param>
    public void SetVtlAngleImd(float vAngle)
    {
        SetVtlAngle(vAngle);
        mCurVtlAngle = vAngle;
    }

    public void ChangeCameraFOV(float target, float time, bool autoUnlock = false)
    {
        if (mInfo == null) return;
        mInfo.UpdateBase(mCurHeight, mCurRadius, mCurVtlAngle, mCurHrzAngle, mCurFov);
        //mInfo.UpdateBase(mMaxHToTar, mMaxRToTar, mDefVtlAngle, mDefHrzAngle, Camera.fieldOfView);
        mInfo.UpdateFOV(target, time);

        /// test begin ///
        if(mLockAutoCam == false)
        {
            mInfo.UpdateH(mMaxHToTar, time);
            mInfo.UpdateR(mMaxRToTar, time);
            mInfo.UpdateVA(mDefVtlAngle, time);
            mInfo.UpdateHA(mDefHrzAngle, time);
        }
        /// test end ///

        mIsChange = true;
        mLockAutoCam = true;
        mAutoUnlock = autoUnlock;
        mInResetCam = false;
    }

    public void ChangeCameraPos(Vector3 pos, float time, bool autoUnlock = false)
    {
        pos = pos / value;
        float tarR = Vector3.Distance(Vector3.zero, new Vector3(pos.x, 0, pos.z));
        float tarH = pos.y;

        //mInfo.UpdateBase(mTarHeight, mCurRadius, mTarVtlAngle, mTarHrzAngle);
        mInfo.UpdateBase(mCurHeight, mCurRadius, mCurVtlAngle, mCurHrzAngle, mCurFov);
        //mInfo.UpdateBase(mMaxHToTar, mMaxRToTar, mDefVtlAngle, mDefHrzAngle, Camera.fieldOfView);

        mInfo.UpdateH(tarH, time);
        mInfo.UpdateR(tarR, time);

        /// test begin ///
        if(mLockAutoCam == false)
        {
            mInfo.UpdateVA(mDefVtlAngle, time);
            mInfo.UpdateHA(mDefHrzAngle, time);
            mInfo.UpdateFOV(mDefFov, time);
        }
        /// test end ///

        mIsChange = true;
        mLockAutoCam = true;
        mAutoUnlock = autoUnlock;
        mInResetCam = false;
    }

    public void ChangeCameraEuler(Vector3 euler, float time, bool autoUnlock = false)
    {
        euler = euler / value;
        float tarVA = euler.x;
        float tarHA = euler.y;
        //mInfo.UpdateBase(mTarHeight, mCurRadius, mTarVtlAngle, mTarHrzAngle);
        mInfo.UpdateBase(mCurHeight, mCurRadius, mCurVtlAngle, mCurHrzAngle, mCurFov);
        //mInfo.UpdateBase(mMaxHToTar, mMaxRToTar, mDefVtlAngle, mDefHrzAngle, Camera.fieldOfView);

        mInfo.UpdateVA(tarVA, time);
        mInfo.UpdateHA(tarHA, time);

        /// test begin ///
        if (mLockAutoCam == false)
        {
            mInfo.UpdateH(mMaxHToTar, time);
            mInfo.UpdateR(mMaxRToTar, time);
            mInfo.UpdateFOV(mDefFov, time);
        }
        /// test end ///

        mIsChange = true;
        mLockAutoCam = true;
        mAutoUnlock = autoUnlock;
        mInResetCam = false;
    }

    public void ChangeCameraEulerY(float angle, float time, bool autoUnlock = false)
    {
        float tarHA = angle / value;
        //mInfo.UpdateBase(mTarHeight, mCurRadius, mTarVtlAngle, mTarHrzAngle);
        mInfo.UpdateBase(mCurHeight, mCurRadius, mCurVtlAngle, mCurHrzAngle, mCurFov);
        //mInfo.UpdateBase(mMaxHToTar, mMaxRToTar, mDefVtlAngle, mDefHrzAngle, Camera.fieldOfView);

        mInfo.UpdateHA(tarHA, time);

        /// test begin ///
        if (mLockAutoCam == false)
        {
            mInfo.UpdateH(mMaxHToTar, time);
            mInfo.UpdateR(mMaxRToTar, time);
            mInfo.UpdateVA(mDefVtlAngle, time);
            mInfo.UpdateFOV(mDefFov, time);
        }
        /// test end ///

        mIsChange = true;
        mLockAutoCam = true;
        mAutoUnlock = autoUnlock;
        mInResetCam = false;
    }

    public void RestoreCamearInfo(float rTime, float hTime, float vaTime, float haTime, float fovTime)
    {
        if (mInfo == null) return;
        mInfo.Restore(hTime, rTime, vaTime, haTime, fovTime);
        mIsChange = true;
        mInResetCam = true;
    }

    public void ResetLockCam()
    {
        mLockAutoCam = false;
    }
}
