using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;


/// <summary>
/// ������Ч
/// </summary>
public class PlayEffectEvent : GameEvent
{
    #region ˽�б���
    int mBindMode;
    int mStopMode;
    string mResName = string.Empty;
    Transform mBindBone = null;
    Unit mParentUnit = null;
    Unit mBehitUnit = null;
    Vector3 mPos = Vector3.zero;
    Vector3 mOffset = Vector3.zero;
    Vector3 mForward = Vector3.zero;
    Vector3 mScale = Vector3.zero;

    GameObject mLoadEffectObject = null;
    bool mIsLoadEffect = false;
    bool mLoadObject = true;
    ParticleSystem[] ps;
    #endregion

    #region ����
    /// <summary>
    /// ֹͣ��ʽ
    /// </summary>
    public int StopMode
    {
        get { return mStopMode; }
    }

    /// <summary>
    /// ��Ч��
    /// </summary>
    public string Resname
    {
        get { return mResName; }
    }

    /// <summary>
    /// ��Ч
    /// </summary>
    public GameObject EffectObject
    {
        get { return mLoadEffectObject; }
        set { mLoadEffectObject = value; }
    }
    #endregion

    #region ���з���
    public PlayEffectEvent(string resName, Unit parent,
        Vector3 offset, Vector3 scale, Vector3 forward, int bindMode, int stopMode)
    {
        mParentUnit = parent;
        mStopMode = stopMode;
        mBindMode = bindMode;
        string[] strs = resName.Split(',');
        if (strs.Length > 0)
            mResName = QualityMgr.instance.GetQuaEffName(strs[0]);
        if (mBindMode != 0)
        {
            if (strs.Length == 2)
                mBindBone = GetParentBone(strs[1]);
            else
                mBindBone = GetParentBone();
        }
        if (parent != null)
            mPos = parent.Position;
        mOffset = offset;
        mForward = forward;
        mScale = scale;
        mScale.y = 1;

        //0��1��ʾֹͣ��ʽ���붯���޹أ�2��ʾ�涯��������4��ʾ���˽�����8��ʾ�����жϽ�����16��ʾ��ʱ��󶨣�����HidedEffect����
        //�����༭����Ӧ��ֵ��
        //0---------------------------, 1--------------, 2------------, 3----------------, 4------------------------------------
        if(mStopMode == 0)
        {
            mPos = offset;
            if (mParentUnit == null)
                return;
            mParentUnit.mUnitEffects.AddPlayBehitEffectEvent(this);
            mBehitUnit = mParentUnit;
            mParentUnit = null;
        }
        else
            mLoadObject = mParentUnit.mUnitEffects.AddPlayerEffectEvent(this);
    }
    
    /// <summary>
    /// ��Ч�Ƿ�ֹͣ����
    /// </summary>
    /// <returns></returns>
    public bool isEffectStop()
    {
        bool isStop = true;
        if (mLoadEffectObject == null && mIsLoadEffect)
            return true;
        else if (mLoadEffectObject == null && !mIsLoadEffect)
            return false;
        for (int i = 0; i < ps.Length; i++)
        {
            if (ps[i] == null)
                continue;
            if (ps[i].isPlaying)
            {
                isStop = false;
                break;
            }
        }
        return isStop;
    }

    /// <summary>
    /// ֹͣ��Ч
    /// </summary>
    public void StopEffect()
    {
        if (mLoadEffectObject == null)
        {
            mParentUnit = null;
            mBehitUnit = null;
            return;
        }
        GameEventManager.instance.DestroyEffect(mLoadEffectObject);
        mLoadEffectObject = null;
    }

    /// <summary>
    /// �����Ч��Ч��
    /// </summary>
    /// <returns></returns>
    public bool ChkEffective()
    {
        if (Global.Mode == PlayMode.Local)
            return true;
        if (GameSceneManager.instance.SceneLoadState == SceneLoadStateEnum.SceneDone)
            return true;
        GameObject go = mLoadEffectObject;
        if (go == null)
            return false;
        ShowEffectMgr.instance.RemoveShowEffect(go);
        StopEffect();
        return false;
    }

    /// <summary>
    /// ���ز�����Ч
    /// </summary>
    public override void Execute()
    {
        if (!mLoadObject)
            return;
        if (string.IsNullOrEmpty(mResName))
            return;
        AssetMgr.LoadPrefab(mResName, (effect) =>
        {
            if (effect == null)
                return;
            effect.transform.parent = null;
            effect.SetActive(true);
            mLoadEffectObject = effect;
            mIsLoadEffect = true;
            if (!ChkEffective())
                return;
            ps = mLoadEffectObject.GetComponentsInChildren<ParticleSystem>();

            DelayDestroy delay = effect.GetComponent<DelayDestroy>();
            if (delay != null)
            {
                if (mStopMode == 0x10)
                {
                    delay.enabled = false;
                }
                else
                {
                    if (mBehitUnit != null)
                        delay.unitUID = mBehitUnit.UnitUID;
                    else
                    {
                        if(mParentUnit != null)
                            delay.unitUID = mParentUnit.UnitUID;
                    }
                    delay.onDestroy = GameEventManager.instance.DelayDestroyCallback;
                }
            }

            if (mBindMode != 0)
            {
                effect.transform.parent = mBindBone;

                if (effect.transform.parent == null)
                {
                    effect.transform.position = mPos;
                    effect.transform.position = effect.transform.TransformPoint(mOffset);
                }
                else
                    effect.transform.localPosition = mOffset;

                if (mForward != Vector3.zero)
                    effect.transform.rotation = Quaternion.LookRotation(mForward);
                else
                    effect.transform.localEulerAngles = mForward;
            }
            else
            {
                Vector3 position = Vector3.zero;
                //�������任��Ϊ��ʱ�������ø���任�ķ���׼ȷ�����Чƫ��λ�ã����������Ч����任�ķ�����Ϊƫ�ƻ�׼
                if (mParentUnit != null && mParentUnit.UnitTrans != null) 
                {
                    Matrix4x4 mtr = new Matrix4x4();
                    mtr = Matrix4x4.TRS(mParentUnit.Position, Quaternion.LookRotation(mParentUnit.UnitTrans.forward), Vector3.one);
                    position = mtr.MultiplyPoint(mOffset);
                }
                else if (mParentUnit != null)
                {
                    Matrix4x4 mtr = new Matrix4x4();
                    mtr = Matrix4x4.TRS(mParentUnit.Position, Quaternion.LookRotation(effect.transform.forward), Vector3.one);
                    position = mtr.MultiplyPoint(mOffset);
                }
                else//������������ܻ���Чֹͣ��ʽ
                    position = mPos;
                effect.transform.position = position;
                if (mForward != Vector3.zero)
                {
                    effect.transform.rotation = Quaternion.LookRotation(mForward);
                }
                else
                {
                    effect.transform.localEulerAngles = mForward;
                }
            }
            Utility.ScaleGameOject(effect, mScale);
        });
    }
    #endregion

    #region ˽�з���
    /// <summary>
    /// ��ȡ���ظ��ڵ�
    /// </summary>
    private Transform GetParentBone(string boneName = null)
    {
        if (mParentUnit == null)
            return null;
        return mParentUnit.mUnitBoneInfo.GetBoneByName(boneName);
    }
    #endregion
}