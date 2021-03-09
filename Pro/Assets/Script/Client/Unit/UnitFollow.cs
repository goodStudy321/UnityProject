using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class UnitFollow : MonoBehaviour
{
    float offsetH = 0;

    private Unit owner
    {
        get
        {
            return InputVectorMove.instance.MoveUnit;
        }
    }
    private Transform oTrans
    {
        get
        {
            if (owner == null) return null;
            return owner.UnitTrans;
        }
    }
    public float DeltaY
    {
        get
        {
            if (owner == null)
                return 0;
            return owner.Position.y+ mDeltaY;
        }
    }

    public  float mDeltaY = 0;
    /// <summary>
    /// 跟随距离
    /// </summary>
    public float mFollowDistance = 3f;
    /// <summary>
    /// 跟随距离平方
    /// </summary>
    public float mFollowDistanceSqr = 9f;
    /// <summary>
    /// 移动到角色的距离
    /// </summary>
    public float mMoveToDistanceSqr = 3f;
    /// <summary>
    /// 是否在跟随中
    /// </summary>
    private bool bFollowing = false;
    /// <summary>
    /// 是否移动状中
    /// </summary>
   // private bool bMoving = false;
    /// 是否自由移动中
    /// </summary>
    //private bool bFreedomMoving = false;
    /// <summary>
    /// 自由行走计时器
    /// </summary>
    private Timer mFreedomWalkTimers;
    /// <summary>
    /// 计时结束
    /// </summary>
    private bool mTimeOut = false;
    /// <summary>
    /// 当前自由移动点
    /// </summary>
   // private Vector3 mCurFreedomPoint = Vector3.zero;
    /// <summary>
    /// 帧率
    /// </summary>
    //private int mFrame = 8;
    /// <summary>
    /// 移动位置列表
    /// </summary>
    protected List<Vector3> mMovePosList = new List<Vector3>();

    private CommenNameBar bar;

    /// <summary>
    /// 出生相对位置
    /// </summary>
    public Vector3 PetBornPos
    {
        get
        {
            Vector3 bornPos = transform.position;
            if (bornPos == Vector3.zero)
                return BackPos;
            bornPos.y += 1;
            return GetRayHitPosition(bornPos);
        }
    }

    /// <summary>
    /// 人物背后位置
    /// </summary>
    public Vector3 BackPos
    {
        get
        {
            if (oTrans != null)
            {
                Vector3 pos = oTrans.position + oTrans.forward * (-1f);
                pos.y += 1;
                return GetRayHitPosition(pos);
            }
            return Vector3.zero;
        }
    }

    void Awake()
    {
        //DontDestroyOnLoad(this);
       // AssetMgr.Instance.SetPrstnt(this.name);
        EventMgr.Add(EventKey.UnitRevive, UpdateBirthPos);
    }

    // Use this for initialization
    void Start ()
    {
        
        offsetH = 2;
        CapsuleCollider cc = this.gameObject.GetComponent<CapsuleCollider>();
        if (cc != null)
        {
            offsetH = cc.height;
        }

        UpdateBirthPos();
        InitPetData();
    }

    private void UpdateBirthPos(params object[] objs)
    {
        transform.position = PetBornPos;
    }

    public void UpdateTitle(string name)
    {
        bar = CommenNameBar.Create(transform, string.Empty, name, TopBarFty.LocalPlayerBarStr, 1);
    }

    public void UpdateFalmily(string text)
    {
        if(bar != null)
        {
            bar.Server = text;
        }
    }

    /// <summary>
    /// 初始化宠物数据
    /// </summary>
    private void InitPetData()
    {
        SetFreedomWalkTime();
        SetFreedomMovePoints();
    }

    /// <summary>
    /// 设置自由移动时间
    /// </summary>
    private void SetFreedomWalkTime()
    {
        if (mFreedomWalkTimers == null)
            mFreedomWalkTimers = ObjPool.Instance.Get<Timer>();
        if (mFreedomWalkTimers.Running)
            return;
        mTimeOut = false;
        mFreedomWalkTimers.Seconds = 10f;
        mFreedomWalkTimers.complete += FreedomWalkTimeOut;
        mFreedomWalkTimers.Start();
    }

    /// <summary>
    /// 设置自由移动点
    /// </summary>
    private void SetFreedomMovePoints()
    {
        float moveDis = mFollowDistance - 1;
        mMovePosList.Add(new Vector3(0, 0, moveDis));
        mMovePosList.Add(new Vector3(0, 0, -moveDis));
        mMovePosList.Add(new Vector3(moveDis, 0, 0));
        mMovePosList.Add(new Vector3(-moveDis, 0, 0));
    }

    /// <summary>
    /// 自由移动计时结束
    /// </summary>
    private void FreedomWalkTimeOut()
    {
        mTimeOut = true;
    }

    // Update is called once per frame
    void Update ()
    {
        if (transform == null || transform.name == "null")
            return;
        if (oTrans == null || oTrans.name == "null")
            return;
        Follow();
        Bar();
    }

    private Vector3 GetRayHitPosition(Vector3 pos)
    {
        Ray ray = new Ray(pos, Vector3.down);
        int layer = 2 ^ LayerMask.NameToLayer("Ground");
        RaycastHit hit;
        bool flag = Physics.Raycast(ray, out hit, 10, layer);
        if (!flag)
        {
            layer = 2 ^ LayerMask.NameToLayer("ShadowCaster");
        }
        flag = UnityEngine.Physics.Raycast(ray, out hit, 10, layer);
        if (flag)
        {
            return hit.point;
        }
        return pos;
    }

    private void Bar()
    {
        if(bar != null)
        {
            if (CameraMgr.Main)
                bar.transform.rotation = CameraMgr.Main.transform.rotation;

            bar.transform.position = transform.position + Vector3.up * offsetH;
        }
    }

    /// <summary>
    /// 跟随
    /// </summary>
    private void Follow()
    {
        Vector3 followPos = owner.Position;
        if (bFollowing)
        {
            if (!mTimeOut)
            {
                if (mFreedomWalkTimers.Running)
                    ResetFreedomMove(false);
            }
            Vector3 moveForward = GetForward(transform.position, followPos);
            ExecuteRotation(moveForward);
            ExecuteMove(moveForward);
            UpdateHeight();
            if (!InFollowDistance(followPos, mMoveToDistanceSqr))
                return;
            bFollowing = false;
          //  bMoving = false;
            ResetFreedomMove();
        }
        else
        {
            if (!InFollowDistance(followPos, mFollowDistanceSqr))
                bFollowing = true;
        }
    }
    /// <summary>
    /// 获取方向
    /// </summary>
    /// <param name="srcPos"></param>
    /// <param name="desPos"></param>
    /// <returns></returns>
    protected Vector3 GetForward(Vector3 srcPos, Vector3 desPos)
    {
        //srcPos.y = desPos.y = 0;
        Vector3 forward = desPos - srcPos;
        return forward.normalized;
    }

    /// <summary>
    /// 执行旋转
    /// </summary>
    /// <param name="forward"></param>
    private void ExecuteRotation(Vector3 forward)
    {
        float fowardSqr = Vector3.SqrMagnitude(oTrans.forward - forward);
        if (fowardSqr < 0.01f)
            return;
        float rotateSpeed = owner.ActionStatus.ActiveAction.RotateSpeed;
        transform.rotation = Quaternion.Lerp(transform.rotation, Quaternion.Euler(0, Mathf.Atan2(forward.x, forward.z) * Mathf.Rad2Deg, 0), Time.deltaTime * rotateSpeed);
    }

    /// <summary>
    /// 执行移动
    /// </summary>
    /// <param name="forward"></param>
    private void ExecuteMove(Vector3 forward, bool bFreeMove = false)
    {
        if (owner.ActionStatus.ActionState != ActionStatus.EActionStatus.EAS_Move)
            if (!owner.ActionStatus.CheckInterrupt("N0020"))
                return;
    //    bMoving = true;
        float moveSpeed = InputMgr.instance.mOwner.MoveSpeed;
        Vector3 delPos = forward * moveSpeed * Time.deltaTime;
        if (bFreeMove)
        {
            RaycastHit hit;
            Vector3 orgin = transform.position + new Vector3(0, 0.5f, 0);
            Ray rayObsta = new Ray(orgin, forward);
            float lengths = delPos.magnitude;
            lengths += owner.ActionStatus.Bounding.z;
            if (Physics.Raycast(rayObsta, out hit, delPos.magnitude, 1 << LayerTool.Wall))
            {
           //     bMoving = false;
                ResetFreedomMove();
                return;
            }
        }
        transform.position += delPos;
    }

    /// <summary>
    /// 重置自由移动
    /// </summary>
    private void ResetFreedomMove(bool bRestart = true)
    {
        mFreedomWalkTimers.Reset();
        if (bRestart)
            mFreedomWalkTimers.Start();
        else
            mFreedomWalkTimers.Pause();
       // mCurFreedomPoint = Vector3.zero;
        mTimeOut = false;
        //bFreedomMoving = false;
    }

    /// <summary>
    /// 更新高度
    /// </summary>
    private void UpdateHeight()
    {
        if (transform == null || transform.name == "null") return;
        Vector3 pos = this.transform.position;
        pos = GetRayHitPosition(pos);
        pos.y = DeltaY;
        Vector3 desPos = Vector3.Slerp(this.transform.position, pos, Time.deltaTime * 5);
        SetModelPosition(desPos);
    }

    /// <summary>
    /// 是否在跟随距离内
    /// </summary>
    /// <param name="followPos"></param>
    /// <param name="followDisSqr"></param>
    /// <returns></returns>
    protected bool InFollowDistance(Vector3 followPos, float followDisSqr)
    {
        //followPos.y = owner.Position.y;
        float dis = Vector3.SqrMagnitude(followPos - transform.position);
        if (dis > followDisSqr)
            return false;
        return true;
    }

    /// <summary>
    /// 设置模型位置
    /// </summary>
    public void SetModelPosition(Vector3 pos)
    {
        this.transform.position = pos;
    }

    void OnDestroy()
    {
        EventMgr.Remove(EventKey.UnitRevive, UpdateBirthPos);
        if (bar != null)
        {
            bar.Dispose();
            bar = null;
        }
    }

}
