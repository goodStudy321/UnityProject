//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/4/7 21:40:01
//=============================================================================

using System;

namespace Loong.Game
{
    /// <summary>
    /// 通知接口
    /// </summary>
    public interface IPush
    {
        #region 属性

        #endregion

        #region 方法
        void Init();

        /// <summary>
        /// 添加通知
        /// </summary>
        /// <param name="id">标识符</param>
        /// <param name="name">名称</param>
        /// <param name="title">标题</param>
        /// <param name="content">内容</param>
        /// <param name="mills">从格林尼治时间(1970.1.1,0.0.0)算起的目标刻度</param>
        /// <param name="repeat">重复间隔/毫秒</param>
        void Add(int id, string name, string title, string content, long mills, long repeat);

        /// <summary>
        /// 添加通知
        /// </summary>
        /// <param name="id">标识符</param>
        /// <param name="name">名称</param>
        /// <param name="title">标题</param>
        /// <param name="content">内容</param>
        /// <param name="mills">目标时间和当前时间的刻度差值</param>
        /// <param name="repeat"></param>
        void AddFromNow(int id, string name, string title, string content, long mills, long repeat);

        /// <summary>
        /// 移除通知
        /// </summary>
        /// <param name="id"></param>
        void Remove(int id);

        /// <summary>
        /// 保存
        /// </summary>
        void Save();

        /// <summary>
        /// 清理
        /// </summary>
        void Clear();
        #endregion

        #region 索引器

        #endregion

        #region 事件

        #endregion
    }
}