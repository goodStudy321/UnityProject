using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.5.28
    /// BG:错误码信息基类
    /// </summary>
    public abstract class ErrorCodeBase
    {
        #region 字段
        private Dictionary<string, ErrorInfo> errorDic = new Dictionary<string, ErrorInfo>();

        #endregion

        #region 属性

        #endregion

        #region 构造方法
        protected ErrorCodeBase()
        {
            Initialize();
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected abstract void Initialize();

        protected string GetDefault(string errorCode)
        {
            return string.Format("[错误码:{0}]", errorCode);
        }

        protected void Add(string errorCode, ErrorInfo errorInfo)
        {
            if (errorDic.ContainsKey(errorCode))
            {
                iTrace.Error("Loong", string.Format("{0}中已经包含错误码:{1}", this.GetType().Name, errorCode));
            }
            else
            {
                errorDic.Add(errorCode, errorInfo);
            }
        }
        #endregion

        #region 公开方法
        /// <summary>
        /// 获取错误描述字符
        /// </summary>
        public string Get(string errorCode)
        {
            if (errorDic.ContainsKey(errorCode)) return errorDic[errorCode].ToString();
            return GetDefault(errorCode);
        }

        /// <summary>
        /// 获取错误信息
        /// </summary>
        public ErrorInfo GetErrorInfo(string errorCode)
        {
            if (errorDic.ContainsKey(errorCode)) return errorDic[errorCode];
            return null;
        }
        #endregion
    }
}