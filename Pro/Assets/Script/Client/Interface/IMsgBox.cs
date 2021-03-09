/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2015.3.20 20:38:52
 ============================================================================*/

using System;

namespace Loong.Game
{

    /// <summary>
    /// AU:Loong
    /// TM:2015.3.20
    /// BG:消息框接口
    /// </summary>
    public interface IMsgBox : ISetActive, IInitByGo
    {
        #region 属性

        #endregion

        #region 方法
        /// <summary>
        /// 显示是
        /// </summary>
        /// <param name="msg">信息</param>
        /// <param name="yes">是按钮内容</param>
        /// <param name="cb">是按钮点击回调</param>
        void Show(string msg, string yes = "是", Action cb = null);

        /// <summary>
        /// 显示是/否
        /// </summary>
        /// <param name="msg">信息</param>
        /// <param name="yes">是按钮内容</param>
        /// <param name="yesCb">是按钮点击回调</param>
        /// <param name="no">否按钮内容</param>
        /// <param name="noCb">否按钮点击回调</param>
        void Show(string msg, string yes = "是", Action yesCb = null, string no = "否", Action noCb = null);
        #endregion

        #region 事件

        #endregion

        #region 索引器

        #endregion

    }
}