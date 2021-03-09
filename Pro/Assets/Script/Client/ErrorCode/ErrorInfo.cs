using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Text;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.5.28
    /// BG:错误信息
    /// </summary>
    public class ErrorInfo
    {
        #region 字段
        private string code = "未添加";

        private string error = "未添加";

        private string solution = "未添加";
        #endregion

        #region 属性
        /// <summary>
        /// 错误码
        /// </summary>
        public string Code { get { return code; } }

        /// <summary>
        /// 错误信息
        /// </summary>
        public string Error { get { return error; } }

        /// <summary>
        /// 结局方案
        /// </summary>
        public string Solution { get { return solution; } }
        #endregion

        #region 构造方法
        /// <summary>
        /// 构造函数
        /// </summary>
        /// <param name="code">错误码</param>
        /// <param name="error">错误信息</param>
        /// <param name="solution">解决方案</param>
        public ErrorInfo(string code, string error, string solution)
        {
            this.code = code;
            this.error = error;
            this.solution = solution;
        }

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override string ToString()
        {
            StringBuilder sb = new StringBuilder();
            sb.Append("[");
            sb.Append("错误码:").Append(code).Append(",");
            sb.Append("错误信息:").Append(error).Append(",");
            sb.Append("解决方案:").Append(solution).Append("]");
            return sb.ToString();
        }
        #endregion
    }
}