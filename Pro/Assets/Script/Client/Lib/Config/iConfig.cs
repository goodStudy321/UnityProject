using UnityEngine;
using System.Collections;
using System.Collections.Generic;

/*
 * 如有改动需求,请联系Loong
 * 如果必须改动,请知会Loong
*/

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.6.6
    /// BG:配置
    /// </summary>
    public static class iConfig
    {
        #region 字段
        private static string productName = null;
        private static Transform monoRoot = null;

        #endregion

        #region 属性
        /// <summary>
        /// Mono脚本根节点
        /// </summary>
        public static Transform MonoRoot
        {
            get
            {
                SetMonoRoot();
                return monoRoot;
            }
        }

        /// <summary>
        /// 产品名称
        /// </summary>
        public static string ProductName
        {
            get { return productName; }
        }
        #endregion

        #region 构造方法
        static iConfig()
        {
            SetProperty();
        }
        #endregion

        #region 私有方法
        private static void SetProperty()
        {
            productName = Application.productName;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 设置mono脚本根节点
        /// </summary>
        public static void SetMonoRoot()
        {
            if (monoRoot != null) return;
            monoRoot = TransTool.CreateRoot("MonoStatic");
        }

        /// <summary>
        /// 刷新
        /// </summary>
        public static void Refresh()
        {
            SetMonoRoot();
        }
        #endregion
    }
}