/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2018/2/5 10:55:25
 ============================================================================*/

using UnityEngine;
using System.Text;

namespace Loong.Edit
{

    /// <summary>
    /// 编辑器向量工具
    /// </summary>
    public static class EditVecUtil
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
        /// 将三维向量根据分隔符转换成字符串
        /// 比如val:Vector3.zero ch=',' 将转换成:0,0,0
        /// </summary>
        /// <param name="val">值</param>
        /// <param name="ch">分隔符</param>
        /// <param name="fmt">精度</param>
        /// <param name="useY">使用Y轴</param>
        /// <param name="useZ">使用Z轴</param>
        /// <returns></returns>
        public static string Parse(Vector3 val, char ch, string fmt = "f2", bool useY = true, bool useZ = true)
        {
            StringBuilder sb = new StringBuilder();
            string xstr = val.x.ToString(fmt);
            sb.Append(xstr);
            if (useY)
            {
                sb.Append(ch);
                string ystr = val.y.ToString(fmt);
                sb.Append(ystr);
            }
            if (useZ)
            {
                sb.Append(ch);
                string zstr = val.z.ToString(fmt);
                sb.Append(zstr);
            }
            string res = sb.ToString();
            return res;
        }
        #endregion
    }
}