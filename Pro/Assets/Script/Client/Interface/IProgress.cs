/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2015.3.20 20:09:23
 ============================================================================*/

namespace Hello.Game
{
    /// <summary>
    /// 进度接口
    /// </summary>
    public interface IProgress : ISetActive, IInitByGo
    {
        #region 属性

        #endregion

        #region 方法
        /// <summary>
        /// 设置进度
        /// </summary>
        void SetProgress(float val);
        /// <summary>
        /// 设置信息
        /// </summary>
        void SetMessage(string msg);
        /// <summary>
        /// 设置提示
        /// </summary>
        void SetTip(string tip);

        /// <summary>
        /// 设置总量
        /// </summary>
        /// <param name="size">大小:比如100M</param>
        /// <param name="total">总数量</param>
        void SetTotal(string size, int total);

        /// <summary>
        /// 设置总数量
        /// </summary>
        /// <param name="count"></param>
        void SetCount(int count);

        #endregion

        #region 枚举器

        #endregion

        #region 事件

        #endregion
    }
}