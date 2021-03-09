using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.4.12
    /// BG:向量扩展
    /// </summary>
    public static class ExVector
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
        /// 将二维向量保留指定精度
        /// </summary>
        /// <param name="orig">初始值</param>
        /// <param name="format">精度字符</param>
        /// <returns></returns>
        public static Vector2 Pricision(this Vector2 orig, string format = "f3")
        {
            orig.x = orig.x.Precision(format);
            orig.y = orig.y.Precision(format);
            return orig;
        }

        /// <summary>
        /// 将三维向量保留指定精度
        /// </summary>
        /// <param name="orig">初始值</param>
        /// <param name="format">精度字符</param>
        /// <returns></returns>
        public static Vector3 Precision(this Vector3 orig, string format = "f3")
        {
            orig.x = orig.x.Precision(format);
            orig.y = orig.y.Precision(format);
            orig.z = orig.z.Precision(format);
            return orig;
        }

        /// <summary>
        /// 将四维向量保留指定精度
        /// </summary>
        /// <param name="orig">初始值</param>
        /// <param name="format">精度字符</param>
        /// <returns></returns>
        public static Vector4 Precision(this Vector4 orig, string format = "f3")
        {
            orig.w = orig.w.Precision(format);
            orig.x = orig.x.Precision(format);
            orig.y = orig.y.Precision(format);
            orig.z = orig.z.Precision(format);
            return orig;
        }
        #endregion
    }
}