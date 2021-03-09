using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.5.28
    /// BG:WWW类型错误提示
    /// </summary>
    public class WWWError : ErrorCodeBase
    {
        #region 字段
        private static readonly WWWError instance = new WWWError();
        #endregion

        #region 属性
        public static WWWError Instance { get { return instance; } }
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        protected override void Initialize()
        {
            ErrorInfo info404 = new ErrorInfo("404", "未发现文件", "请确定路径是否存在");
            Add("404", info404);
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        #endregion
    }
}