using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HgupPoint
{
    public static readonly HgupPoint instance = new HgupPoint();
    private HgupPoint() { }

    #region 字段
    /// <summary>
    /// 挂机点挂机时间
    /// </summary>
    private const float mHgTime = 600;
    private float mHgupTime = mHgTime;
    private bool isHgupPoint = false;
    #endregion

    #region 属性
    /// <summary>
    /// 是否正在挂机点挂机
    /// </summary>
    public bool IsHgupPoint
    {
        get { return isHgupPoint; }
        set
        {
            isHgupPoint = value;
            ResetTime();
        }
    }
    #endregion

    #region 私有方法
    
    #endregion

    #region 公有方法
    /// <summary>
    /// 更新挂机点挂机
    /// </summary>
    public void UpdateHgPoint()
    {
        mHgupTime -= Time.deltaTime;
        if (mHgupTime > 0)
            return;
        ResetTime();
        EventMgr.Trigger(EventKey.HgupPointHgup);
    }

    /// <summary>
    /// 重置时间
    /// </summary>
    public void ResetTime()
    {
        if (mHgupTime == mHgTime)
            return;
        mHgupTime = mHgTime;
    }

    /// <summary>
    /// 清除数据
    /// </summary>
    public void Clear()
    {
        IsHgupPoint = false;
    }
    #endregion
}
