using System;
using UnityEngine;
using System.Collections.Generic;
using UnityEngine.SceneManagement;
using Object = UnityEngine.Object;

namespace Loong.Game
{

    /// <summary>
    /// AU:Loong
    /// TM:2014.6.3
    /// BG:委托加载场景
    /// </summary>
    public class DelLoadScene : DelObj<Object>
    {
        #region 字段
        private bool add = false;

        private string name = null;
        #endregion

        #region 属性

        /// <summary>
        /// true:叠加
        /// </summary>
        public bool Additive
        {
            get { return add; }
            set { add = value; }
        }

        /// <summary>
        /// 场景名称
        /// </summary>
        public string Name
        {
            get { return name; }
            set { name = value; }
        }
        #endregion

        #region 构造方法
        public DelLoadScene()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override Object Get(Object obj)
        {
            return null;
        }

        protected override void Execute(Object t)
        {
            if (string.IsNullOrEmpty(Name)) return;
            if (Additive)
            {
                SceneManager.LoadScene(Name, LoadSceneMode.Additive);
            }
            else
            {
                SceneManager.LoadScene(Name);
            }
#if UNITY_EDITOR
            iTrace.eLog("Loong", "load scene:{0},mode:{1}", Name, Additive ? "addtive" : "single");
#endif
        }
        #endregion

        #region 公开方法

        public override void Dispose()
        {
            Name = null;
            Additive = false;
        }

        public void OnComplete()
        {
            AssetMgr.Instance.complete -= OnComplete;
            Execute(null);
            Dispose();
        }
        #endregion
    }
}