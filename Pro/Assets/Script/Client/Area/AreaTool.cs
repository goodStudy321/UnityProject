using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        d7f421b7-210b-484f-91e7-f4cc49b51c62
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/6 10:53:07
    /// BG:区域工具
    /// </summary>
    public static class AreaTool
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

        #endregion

        #region 公开方法

        /// <summary>
        /// 检查左下角点和右上角点之间有效性
        /// </summary>
        /// <param name="leftDownPoint">左下角点</param>
        /// <param name="rightUpPoint">右上角点</param>
        /// <returns></returns>
        public static bool Check(Vector3 leftDownPoint, Vector3 rightUpPoint)
        {
            if (leftDownPoint.x >= rightUpPoint.x) return false;
            if (leftDownPoint.z >= rightUpPoint.z) return false;
            return true;
        }

        /// <summary>
        /// 判断点是否处在左下角点和右上角点构成的矩形区域中
        /// </summary>
        /// <param name="leftDownPoint">左下角点</param>
        /// <param name="rightUpPoint">右上角点</param>
        /// <param name="position">位置</param>
        /// <returns></returns>
        public static bool Contains(Vector3 leftDownPoint, Vector3 rightUpPoint, Vector3 position)
        {
            if (leftDownPoint.x >= rightUpPoint.x) return false;
            if (leftDownPoint.z >= rightUpPoint.z) return false;
            if (position.x < leftDownPoint.x) return false;
            if (position.z < leftDownPoint.z) return false;
            if (position.x > rightUpPoint.x) return false;
            if (position.z > rightUpPoint.z) return false;
            return true;
        }

        /// <summary>
        /// 判断点所在半径是否处在左下角点和右上角点构成的矩形区域中
        /// </summary>
        /// <param name="leftDownPoint"></param>
        /// <param name="rightUpPoint"></param>
        /// <param name="position"></param>
        /// <param name="radius"></param>
        /// <returns></returns>
        public static bool Contains(Vector3 leftDownPoint, Vector3 rightUpPoint, Vector3 position, float radius)
        {
            if (leftDownPoint.x >= rightUpPoint.x) return false;
            if (leftDownPoint.z >= rightUpPoint.z) return false;
            if (position.x - radius < leftDownPoint.x) return false;
            if (position.z - radius < leftDownPoint.z) return false;
            if (position.x + radius > rightUpPoint.x) return false;
            if (position.z + radius > rightUpPoint.z) return false;
            return true;
        }
        #endregion
    }
}