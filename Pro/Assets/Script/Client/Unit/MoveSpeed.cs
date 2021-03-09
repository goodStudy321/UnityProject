using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MoveSpeed 
{
    public static readonly MoveSpeed instance = new MoveSpeed();

    private MoveSpeed()
    {

    }
    #region 私有变量
    private Dictionary<MoveType, int> mMoveDic;
    #endregion

    #region 属性

    public Dictionary<MoveType,int> MoveDic
    {
        get
        {
            if (mMoveDic == null)
            {
                mMoveDic = new Dictionary<MoveType, int>();
                Init();
            }
            return mMoveDic;
        }
    }
    #endregion

    #region 私有方法
    /// <summary>
    /// 初始化
    /// </summary>
    private void Init()
    {
        mMoveDic.Add(MoveType.Rush, 20);
        mMoveDic.Add(MoveType.BePull, 15);
    }
    #endregion
}
