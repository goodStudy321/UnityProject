using UnityEngine;

public class JoyStickCtrl 
{
    public static readonly JoyStickCtrl instance = new JoyStickCtrl();

    private JoyStickCtrl()
    {

    }
    #region ˽�б���
    /// <summary>
    /// ��ǰ����ID
    /// </summary>
    private int mCurrentTouchID = -1;
    /// <summary>
    /// ��ʼλ��
    /// </summary>
    private Vector2 mStartPosition = Vector2.zero;
    /// <summary>
    /// ��ǰλ��
    /// </summary>
    private Vector2 mCurrentPosition = Vector2.zero;
    /// <summary>
    /// ��갴��
    /// </summary>
    private bool MouseButtonDown = false;
    /// <summary>
    /// �Ƿ��м��̿����ƶ�����
    /// </summary>
    private bool mIsKeyBoardKeydown = false;
    /// <summary>
    /// ҡ�˿�ȿ�ʼռ������
    /// </summary>
    private const float mWBegRatio = 0;
    /// <summary>
    /// ҡ�˿�Ƚ���ռ������
    /// </summary>
    private const float mWEndRatio = 280f / 1334f;
    /// <summary>
    /// ҡ�˸߶ȿ�ʼռ������
    /// </summary>
    private const float mHBegRatio = 70 / 750f;
    /// <summary>
    /// ҡ�˸߶Ƚ���ռ������
    /// </summary>
    private const float mHEndRatio = 252f / 750f;
    /// <summary>
    /// ҡ��ռ�ÿ�ʼ�߶�
    /// </summary>
    private float mStickWBeg = 0f;//mWBegRatio * Screen.width;
    /// <summary>
    /// ҡ��ռ�ÿ��
    /// </summary>
    private float mStickWEnd = 0f;//mWEndRatio * Screen.width;
    /// <summary>
    /// ҡ��ռ�ÿ�ʼ�߶�
    /// </summary>
    private float mStickHBeg = 0f;//mHBegRatio * Screen.height;
    /// <summary>
    /// ҡ��ռ�ø߶�
    /// </summary>
    private float mStickHEnd = 0f;//mHEndRatio * Screen.height;
    #endregion

    #region ���б���
    /// <summary>
    /// ����ƫ��ֵ
    /// </summary>
    public Vector2 mInputVector = Vector2.zero;
    #endregion

    #region ����
    /// <summary>
    /// �Ƿ��д���
    /// </summary>
    public bool IsTouch
    {
        get
        {
            return (mCurrentTouchID != -1);
        }
    }
    #endregion

    #region ���з���
    public void Init()
    {
        SetStartPos();
    }

    public void SetRange()
    {

        mStickWBeg = mWBegRatio * Screen.width;

        mStickWEnd = mWEndRatio * Screen.width;

        mStickHBeg = mHBegRatio * Screen.height;

        mStickHEnd = mHEndRatio * Screen.height;
        if (Loong.Game.App.IsDebug)
        {
            Debug.LogWarningFormat("XBL", "mStickWBeg:{0}, mStickWEnd:{1}, mStickHBeg:{2}, mStickHEnd:{3}", mStickWBeg, mStickWEnd, mStickHBeg, mStickHEnd);
        }
}
    /// <summary>
    /// ��ȡ��ʼ����λ��
    /// </summary>
    /// <returns></returns>
    public Vector2 GetStartTouchPosition()
    {
        return mStartPosition;
    }

    /// <summary>
    /// ��ȡ��ǰ����λ��
    /// </summary>
    /// <returns></returns>
    public Vector2 GetMoveTouchPosition()
    {
        return mCurrentPosition;
    }

    /// <summary>
    /// ����ҡ�˿���
    /// </summary>
    /// <param name="canCtrl"></param>
    public void SetJsCtrl(bool canCtrl)
    {
        ResetMoveState(canCtrl);
        InputMgr.instance.JoyStickControlMdl = canCtrl;
    }

    /// <summary>
    /// ����
    /// </summary>
    public void Reset()
    {
        mCurrentTouchID = -1;
        SetStartPos();
        //mStartPosition = Vector2.zero;
        mCurrentPosition = Vector2.zero;
        MouseButtonDown = false;
        mIsKeyBoardKeydown = false;
        mInputVector = Vector2.zero;
    }

    /// <summary>
    /// ҡ�˼�����
    /// </summary>
    public void Update()
    {
        if (!InputMgr.instance.JoyStickControlMdl)
            return;
        if (Application.platform == RuntimePlatform.WindowsEditor || Application.platform == RuntimePlatform.WindowsPlayer
            || Application.platform == RuntimePlatform.OSXEditor || Application.platform == RuntimePlatform.OSXPlayer)
        {
            mInputVector = Vector2.zero;
            float horizontal = Input.GetAxis("Horizontal");
            float vertical = Input.GetAxis("Vertical");
            if (horizontal != 0 ||  vertical!= 0)
            {
                mIsKeyBoardKeydown = true;
                MouseButtonDown = true;
                Vector2 delta = new Vector2(horizontal, vertical);
                mInputVector = delta.normalized;
            }
            else
            {
                if (mIsKeyBoardKeydown)
                {
                    mIsKeyBoardKeydown = false;
                    MouseButtonDown = false;
                }
            }
            SetPCJoystick();
            //UpdatePCSkillKey();
        }
        else
        {
            SetMobileJoystick();
        }
    }
    #endregion

    #region ˽�з���
    /// <summary>
    /// �����ƶ�״̬
    /// </summary>
    /// <param name="canCtrl"></param>
    private void ResetMoveState(bool canCtrl)
    {
        if (canCtrl == true)
            return;
        Vector3 inputVector = mInputVector;
        if (inputVector == Vector3.zero)
            return;
        InputVectorMove Ivm = InputVectorMove.instance;
        if (Ivm.MoveUnit == null)
            return;
        if (Ivm.MoveUnit.ActionStatus == null)
            return;
        Ivm.MoveUnit.ActionStatus.ChangeIdleAction();
    }
    /// <summary>
    /// ����PC��ҡ�˴���
    /// </summary>
    private void SetPCJoystick()
    {
        if (Input.GetMouseButtonDown(0))
            MouseButtonDown = true;
        else if (Input.GetMouseButtonUp(0))
            MouseButtonDown = false;

        if (MouseButtonDown)
        {
            Vector2 vDownPos = new Vector2(Input.mousePosition.x, Input.mousePosition.y);

            if (StfStickCon(vDownPos.x, vDownPos.y) && mCurrentTouchID == -1 && !mIsKeyBoardKeydown)
            {
                mCurrentTouchID = 1;
                //mStartPosition = vDownPos;
                mCurrentPosition = vDownPos;
            }

            if (mCurrentTouchID == 1 && !mIsKeyBoardKeydown)
            {
                mCurrentPosition = vDownPos;//Vector2.Lerp(mCurrentPosition, vDownPos, Time.fixedDeltaTime * mOwner.ActionStatus.LJoyStickRotateSpeed);
                mInputVector = (mCurrentPosition - mStartPosition).normalized;
            }
        }
        else
        {
            //mStartPosition = Vector2.zero;
            mInputVector = Vector2.zero;
            mCurrentPosition = Vector2.zero;
            mCurrentTouchID = -1;
        }
    }

    /// <summary>
    /// �����ƶ���ҡ�����ݴ���
    /// </summary>
    private void SetMobileJoystick()
    {
        bool bJoyStickDown = false;
        for (int i = 0; i < Input.touchCount; i++)
        {
            Touch toc = Input.GetTouch(i);
            Vector2 touchPos = toc.position;

            if (StfStickCon(touchPos.x, touchPos.y) && mCurrentTouchID == -1)
            {
                //mStartPosition = touchPos;
                mCurrentPosition = touchPos;
                mCurrentTouchID = toc.fingerId;
            }

            if ((touchPos.x <= 0 && touchPos.x >= Screen.width / 3 ||
                touchPos.y <= 0 && touchPos.y >= Screen.height / 2))
            {
                //mStartPosition = Vector2.zero;
                mInputVector = Vector2.zero;
                mCurrentPosition = Vector2.zero;
                mCurrentTouchID = -1;
            }

            if (toc.fingerId == mCurrentTouchID)
            {
                mCurrentPosition = touchPos;//Vector2.Lerp(mCurrentPosition, touchPos, Time.fixedDeltaTime * mOwner.ActionStatus.LJoyStickRotateSpeed);
                mInputVector = (mCurrentPosition - mStartPosition).normalized;
                bJoyStickDown = true;
            }
        }

        if (!bJoyStickDown)
        {
            //mStartPosition = Vector2.zero;
            mInputVector = Vector2.zero;
            mCurrentPosition = Vector2.zero;
            mCurrentTouchID = -1;
        }
    }

    /// <summary>
    /// ����ҡ�������Ƿ�����
    /// </summary>
    /// <param name="x"></param>
    /// <param name="y"></param>
    /// <returns></returns>
    private bool StfStickCon(float x, float y)
    {
        if ((x > mStickWBeg && x < mStickWEnd) && (y > mStickHBeg && y < mStickHEnd))
            return true;
        return false;
    }

    /// <summary>
    /// ����ҡ�˿�ʼλ��
    /// </summary>
    private void SetStartPos()
    {
        float startX = mStickWBeg + (mStickWEnd - mStickWBeg)/2;
        float startY = mStickHBeg + (mStickHEnd - mStickHBeg) / 2;
        mStartPosition = new Vector2(startX,startY);
    }
    #endregion
}
