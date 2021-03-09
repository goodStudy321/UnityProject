using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class ActivBatMgr
{
    public static readonly ActivBatMgr instance = new ActivBatMgr();
    private ActivBatMgr() { }
    #region ˽���ֶ�
    //�Լ�
    private Unit mOwner = null;
    //�Ƿ��ǻ��ͼ
    private bool isActivMap = false;
    //�淨��Ϣ
    private MapPlayInfo mPlayInfo = null;
    //�Զ��һ�ʱ��
    private Timer mHgupTimer = null;
    //·��ͣ����ʱ��
    private Timer mStayTimer = null;
    //ͣ��ʱ��
    private float mStayTime = 0;
    //Ѳ�߷�ʽ
    private PatrolType mPatrolType = PatrolType.Linear;
    //Ѳ������
    private int mPatrolIndex = -1;
    //����Ѳ��
    private bool mPatroling = false;
    //Ѳ��λ���ֵ�
    private Dictionary<int, Vector3> mPatrolPosDic = new Dictionary<int, Vector3>();
    #endregion

    #region ����
    /// <summary>
    /// �Ƿ��ڻ��ͼ
    /// </summary>
    public bool IsActivMap { get { return isActivMap; } }
    #endregion

    #region ˽�з���
    //����Ѳ��λ���ֵ�
    private void SetPatrolPosDic()
    {
        if (mPlayInfo == null)
            return;
        mPatrolPosDic.Clear();
        List<MapPlayInfo.vector2> posList = mPlayInfo.loopPosLst.list;
        if (posList.Count == 0)
        {
            posList = mPlayInfo.linearPosLst.list;
            if (posList.Count == 0)
                return;
            mPatrolType = PatrolType.Linear;
        }
        else
        {
            mPatrolType = PatrolType.Loop;
        }
        for(int i = 0; i < posList.Count; i++)
        {
            float x = posList[i].x;
            float z = posList[i].z;
            Vector3 pos = new Vector3(x, 0, z);
            pos.y = UnitHelper.instance.GetTerrainHeight(pos);
            mPatrolPosDic[i] = pos;
        }
        mPatrolIndex = 0;
        StartHgupTimer(mPlayInfo.hangupTime * 0.001f);
    }

    /// <summary>
    /// ��鶯��״̬
    /// </summary>
    /// <returns></returns>
    private bool CanChangeActionState()
    {
        if (mOwner == null)
            return false;
        ActionStatus.EActionStatus actionState = mOwner.ActionStatus.ActionState;
        if (actionState == ActionStatus.EActionStatus.EAS_Dead)
            return false;
        if (actionState == ActionStatus.EActionStatus.EAS_Attack)
            return false;
        else if (actionState == ActionStatus.EActionStatus.EAS_Skill)
            return false;
        return true;
    }

    /// <summary>
    /// ��������Id��ȡĿ��
    /// </summary>
    /// <param name="typeId"></param>
    /// <returns></returns>
    private Unit GetTarByTypeId(Unit finder)
    {
        if (mPlayInfo == null)
            return null;
        int count = mPlayInfo.attTypeIdLst.list.Count;
        if (count == 0)
            return null;
        Unit target = null;
        for (int i = 0; i < count; i++)
        {
            target = SkillHelper.instance.GetNTarByTypeId(finder, mPlayInfo.attTypeIdLst.list[i]);
            if (target == null)
                continue;
            UnitType unitType = target.mUnitAttInfo.UnitType;
            if (!SkillHelper.instance.CannotHitUnitType(unitType))
                continue;
            if (!SkillHelper.instance.InViewDis(finder, target))
                continue;
            if (!SkillHelper.instance.CanHit(target))
                continue;
            if (SkillHelper.instance.CompaireCamp(finder, target, UnitCamp.Enemy))
                continue;
            return target;
        }
        return null;
    }

    /// <summary>
    /// �������ͻ�ȡĿ��
    /// </summary>
    /// <param name="type"></param>
    /// <returns></returns>
    private Unit GetTarByType(Unit finder)
    {
        if (mPlayInfo == null)
            return null;
        int count = mPlayInfo.attTypeList.list.Count;
        if (count == 0)
            return null;
        Unit target = null;
        for (int i = 0; i < count; i++)
        {
            UnitType unitType = (UnitType)mPlayInfo.attTypeList.list[i];
            target = SkillHelper.instance.GetNTarByType(finder, unitType);
            if (target == null)
                continue;
            if (!SkillHelper.instance.CannotHitUnitType(unitType))
                continue;
            if (!SkillHelper.instance.InViewDis(finder, target))
                continue;
            if (!SkillHelper.instance.CanHit(target))
                continue;
            if (!SkillHelper.instance.CompaireCamp(finder, target, UnitCamp.Enemy))
                continue;
            return target;
        }
        return null;
    }

    private void PathfindingCB(Unit unit,AsPathfinding.PathResultType PRType)
    {
        NavMoveBuff.instance.StopMoveBuff(unit);
        mPatroling = false;
        if (PRType != AsPathfinding.PathResultType.PRT_PATH_SUC)
            StopStayTimer();
        else
        {
            StartStayTimer();
            ChangePatrolIndex();
        }
    }

    /// <summary>
    /// �ı�Ѳ��·������
    /// </summary>
    private void ChangePatrolIndex()
    {
        int count = mPatrolPosDic.Count;
        if(mPatrolType == PatrolType.Linear)
        {
            if (mPatrolIndex + 1 >= count)
                mPatrolIndex = -1;
            else
                mPatrolIndex++;
        }
        else if(mPatrolType == PatrolType.Loop)
        {
            if (mPatrolIndex + 1 >= count)
                mPatrolIndex = 0;
            else
                mPatrolIndex++;
        }
        else if(mPatrolType == PatrolType.radom)
        {
            mPatrolIndex = Random.Range(0, count);
        }
    }

    /// <summary>
    /// ����·��ͣ����ʱ��
    /// </summary>
    private void StartStayTimer()
    {
        if (mStayTimer == null)
            mStayTimer = ObjPool.Instance.Get<Timer>();
        else
            mStayTimer.Stop();
        mStayTimer.Seconds = mStayTime;
        mStayTimer.Start();
    }

    /// <summary>
    /// ֹͣ½·��ͣ����ʱ��
    /// </summary>
    private void StopStayTimer()
    {
        if (mStayTimer == null)
            return;
        if (!mStayTimer.Running)
            return;
        mStayTimer.Stop();
    }
    #endregion

    #region ���з���

    /// <summary>
    /// ��ʼ�һ���ʱ��
    /// </summary>
    public void StartHgupTimer(float seconds)
    {
        if (mHgupTimer == null)
            mHgupTimer = ObjPool.Instance.Get<Timer>();
        else
            mHgupTimer.Stop();
        mHgupTimer.Seconds = seconds;
        mHgupTimer.complete += HgupCmp;
        mHgupTimer.Start();
    }

    /// <summary>
    /// ֹͣ�һ���ʱ��
    /// </summary>
    public void StopHgupTimer()
    {
        if (mHgupTimer == null)
            return;
        if (!mHgupTimer.Running)
            return;
        mHgupTimer.Stop();
    }

    /// <summary>
    /// �Զ��һ���ʱ���
    /// </summary>
    public void HgupCmp()
    {
        HangupMgr.instance.IsSituFight = true;
    }
    /// <summary>
    /// ���û��ͼ����
    /// </summary>
    /// <param name="sceneId"></param>
    public void SetActivMapData(int sceneId)
    {
        SceneInfo sceneInfo = SceneInfoManager.instance.Find((uint)sceneId);
        if(sceneInfo == null)
        {
            ClearData();
            return;
        }
        MapPlayInfo playInfo = MapPlayInfoManager.instance.Find(sceneInfo.playId);
        if(playInfo == null)
        {
            ClearData();
            return;
        }
        mOwner = InputMgr.instance.mOwner;
        isActivMap = sceneInfo.playId != 0;
        mPlayInfo = playInfo;
        mPatroling = false;
        mStayTime = playInfo.stayTime * 0.001f;
        SetPatrolPosDic();
    }

    /// <summary>
    /// ��ȡ���ͼĿ��
    /// </summary>
    /// <returns></returns>
    public Unit GetActivTarget(Unit owner)
    {
        Unit target = GetTarByTypeId(owner) == null ? GetTarByType(owner):null;
        if (target != null)
            return target;
        return null;
    }

    /// <summary>
    /// �������
    /// </summary>
    public void ClearData()
    {
        isActivMap = false;
        mPlayInfo = null;
    }

    public void MoveToPos()
    {
        if (!isActivMap)
            return;
        if (mPatrolIndex == -1)
            return;
        if (mPatroling)
            return;
        if (mHgupTimer == null)
            return;
        if (mHgupTimer.Running)
            return;
        if (!CanChangeActionState())
            return;
        if (mStayTimer != null && mStayTimer.Running)
            return;
        Vector3 targetPos = mPatrolPosDic[mPatrolIndex];
        if (!mOwner.mUnitMove.StartNav(targetPos, -1, 0, PathfindingCB, true))
            return;
        mPatroling = true;
    }
    #endregion
}
