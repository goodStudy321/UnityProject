#if UNITY_EDITOR
using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.8.2
    /// BG:功能工厂
    /// </summary>
    public static class ActionFty
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 获取功能
        /// </summary>
        /// <param name="type">类型</param>
        /// <returns></returns>
        public static ActionBase Get(ActionType type)
        {
            switch (type)
            {
                case ActionType.PlayParticle:
                    return ObjPool.Instance.Get<ActionPlayPaticle>();
                default:
                    return null;
            }
        }
        #endregion
    }
}
#endif