using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.4.12
    /// BG:浮点型扩展
    /// </summary>
    public static class ExFloat
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
        /// 将浮点型数字保留小数点后几位
        /// </summary>
        /// <param name="orig">初始值</param>
        /// <param name="deci">精度∈[0,1]</param>
        /// <returns></returns>
        public static float Precision(this float orig, float deci = 0.001f)
        {
            if (deci <= 0) return orig;
            float multi = orig / deci;
            int temp = (int)multi;
            orig = temp * deci;
            return orig;

        }

        /// <summary>
        /// 通过字符格式化将小鼠保留到小数点后几位
        /// </summary>
        /// <param name="orig">初始值</param>
        /// <param name="format">格式化字符</param>
        /// <returns></returns>
        public static float Precision(this float orig, string format = "f3")
        {
            string temp = orig.ToString(format);
            orig = float.Parse(temp);
            return orig;
        }
        #endregion
    }
}