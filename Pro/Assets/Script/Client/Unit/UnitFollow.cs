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
    /// �������
    /// </summary>
    public float mFollowDistance = 3f;
    /// <summary>
    /// �������ƽ��
    /// </summary>
    public float mFollowDistanceSqr = 9f;
    /// <summary>
    /// �ƶ�����ɫ�ľ���
    /// </summary>
    public float mMoveToDistanceSqr = 3f;
    /// <summary>
    /// �Ƿ��ڸ�����
    /// </summary>
    private bool bFollowing = false;
    /// <summary>
    /// �Ƿ��ƶ�״��
    /// </summary>
   // private bool bMoving = false;
    /// �Ƿ������ƶ���
    /// </summary>
    //private bool bFreedomMoving = false;
    /// <summary>
    /// �������߼�ʱ��
    /// </summary>
    private Timer mFreedomWalkTimers;
    /// <summary>
    /// ��ʱ����
    /// </summary>
    private bool mTimeOut = false;
    /// <summary>
    /// ��ǰ�����ƶ���
    /// </summary>
   // private Vector3 mCurFreedomPoint = Vector3.zero;
    /// <summary>
    /// ֡��
    /// </summary>
    //private int mFrame = 8;
    /// <summary>
    /// �ƶ�λ���б�
    /// </summary>
    protected List<Vector3> mMovePosList = new List<Vector3>();

    private CommenNameBar bar;

    /// <summary>
    /// �������λ��
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
    /// ���ﱳ��λ��
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
    /// ��ʼ����������
    /// </summary>
    private void InitPetData()
    {
        SetFreedomWalkTime();
        SetFreedomMovePoints();
    }

    /// <summary>
    /// ���������ƶ�ʱ��
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
    /// ���������ƶ���
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
    /// �����ƶ���ʱ����
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
    /// ����
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
    /// ��ȡ����
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
    /// ִ����ת
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
    /// ִ���ƶ�
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
    /// ���������ƶ�
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
    /// ���¸߶�
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
    /// �Ƿ��ڸ��������
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
    /// ����ģ��λ��
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
