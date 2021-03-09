using System;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.9.2
    /// BG:对象回调委托处理
    /// </summary>
    public abstract class DelObj<T> : IDisposable where T : class
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        /// <summary>
        /// 获取指定类型对象
        /// </summary>
        /// <param name="obj"></param>
        /// <returns></returns>
        protected abstract T Get(Object obj);

        /// <summary>
        /// 解析指定类型对象处理
        /// </summary>
        /// <param name="t"></param>
        protected abstract void Execute(T t);

        #endregion

        #region 公开方法
        /// <summary>
        /// 对象回调
        /// </summary>
        /// <param name="obj"></param>
        public void Callback(Object obj)
        {
            T t = Get(obj);
            Execute(t);
            Dispose();
            ObjPool.Instance.Add(this);
        }

        public virtual void Dispose()
        {

        }


        #endregion
    }
}