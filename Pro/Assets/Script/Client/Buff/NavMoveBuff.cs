using Loong.Game;

public class NavMoveBuff
{
    public static readonly NavMoveBuff instance = new NavMoveBuff();

    private NavMoveBuff()
    {
        mTimer = ObjPool.Instance.Get<Timer>();
    }

    #region 私有字段
    /// <summary>
    /// 计时器
    /// </summary>
    private Timer mTimer;
    /// <summary>
    /// 是否移动buff中
    /// </summary>
    private bool isMovBuff = false;
    #endregion

    #region 私有方法
    /// <summary>
    /// 时间结束
    /// </summary>
    private void TimeOut()
    {
        Unit unit = InputMgr.instance.mOwner;
        if (unit == null)
            return;
        StopTimer(unit);
        if (isMovBuff)
            return;
        NetBuff.ReqMoveBuff(1);
        isMovBuff = true;
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 设置时间
    /// </summary>
    public void StartTimer(Unit unit)
    {
        if (unit == null)
            return;
        if (unit != InputMgr.instance.mOwner)
            return;
        int systemId = (int)PendantSystemEnum.Mount;
        if (User.instance.SystemOpenList.Contains(systemId))
            return;
        if (mTimer == null)
            return;
        if (mTimer.Running)
            return;
        mTimer.Seconds = 50f;
        mTimer.complete += TimeOut;
        mTimer.Start();
    }

    /// <summary>
    /// 停止时间
    /// </summary>
    public void StopTimer(Unit unit)
    {
        if (unit == null)
            return;
        UnitType unitType = unit.mUnitAttInfo.UnitType;
        if (unit.mPendant != null && unitType == UnitType.Mount)
            unit = unit.ParentUnit;
        if (unit != InputMgr.instance.mOwner)
            return;
        if (mTimer == null)
            return;
        if (!mTimer.Running)
            return;
        mTimer.complete -= TimeOut;
        mTimer.Stop();
    }

    /// <summary>
    /// 停止移动buff
    /// </summary>
    public void StopMoveBuff(Unit unit)
    {
        UnitType unitType = unit.mUnitAttInfo.UnitType;
        if (unit.mPendant != null && unitType == UnitType.Mount)
            unit = unit.ParentUnit;
        if (unit != InputMgr.instance.mOwner)
            return;
        StopTimer(unit);
        if (!isMovBuff)
            return;
        NetBuff.ReqMoveBuff(0);
        isMovBuff = false;
    }
    #endregion
}
