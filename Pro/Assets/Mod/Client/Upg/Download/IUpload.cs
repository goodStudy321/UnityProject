/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.3 17:34:13
 ============================================================================*/

using System;


namespace Loong.Game
{
    /// <summary>
    /// 上传文件接口
    /// </summary>
    public interface IUpload
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 上传文件接口
        /// </summary>
        /// <param name="sourceURI"></param>
        /// <param name="targetURI"></param>
        /// <returns></returns>
        bool Upload(string sourceURI, string targetURI, Action<float> progress);
        #endregion
    }
}