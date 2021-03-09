/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2015.3.20 20:38:52
 ============================================================================*/
using UnityEngine;

namespace Loong.Game
{
    public enum OnOffState : byte
    {
        /// <summary>
        /// 无
        /// </summary>
        None,
        /// <summary>
        /// 打开
        /// </summary>
        Open,
        /// <summary>
        /// 关闭
        /// </summary>
        Close,
    }

    /// <summary>
    /// 需要在其它线程使用的UI代理基类
    /// </summary>
    public abstract class UIThreadProxy<T> where T : class, ISetActive, IInitByGo
    {
        #region 字段
        private T real = null;

        private OnOffState state = OnOffState.None;
        #endregion

        #region 属性


        public T Real
        {
            get { return real; }
            set { real = value; }
        }


        /// <summary>
        /// 开关状态
        /// </summary>
        public OnOffState State
        {
            get { return state; }
            set { state = value; }
        }
        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected void CheckSetActive()
        {
            switch (state)
            {
                case OnOffState.None:
                    break;
                case OnOffState.Open:
                    real.Open(); state = OnOffState.None; break;
                case OnOffState.Close:
                    real.Close(); state = OnOffState.None; break;
                default:
                    break;
            }
        }
        #endregion

        #region 公开方法
        public void Open()
        {
            State = OnOffState.Open;
        }

        public void Close()
        {
            State = OnOffState.Close;
        }


        public abstract void Update();

        public virtual void Dispose()
        {
            state = OnOffState.None;
            if (real != null)
            {
                real.Dispose();
            }
            real = null;
        }

        public virtual void Init(GameObject go)
        {

        }


        /// <summary>
        /// 通过查找到指定名称的游戏对象刷新代理
        /// </summary>
        /// <param name="name"></param>
        public virtual void Refresh<T1>(string name) where T1 : T, new()
        {
            var go = UITool.Find(name);
            if (go == null) go = GbjPool.Instance.Get(name);
            if (go == null) return;
            real = new T1();
            real.Init(go);
            go.SetActive(false);
            var root = UIMgr.HCam.transform;
            TransTool.AddChild(root, go.transform);
        }

        #endregion
    }
}