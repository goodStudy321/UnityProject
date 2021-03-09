/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/6/26 22:25:01
 ============================================================================*/

using System;
using Phantom;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// 模块管理
    /// </summary>
    public static class ModuleMgr
    {
        #region 字段
        private static List<IModule> modules = new List<IModule>();

        private static List<IUpdate> updates = new List<IUpdate>();
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
        /// 添加模块
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="t"></param>
        public static void Add<T>(T t) where T : IModule
        {
            if (t == null) return;
            modules.Add(t);
            t.Init();
            if (!(t is IUpdate)) return;
            IUpdate iu = t as IUpdate;
            updates.Add(iu);
        }

        /// <summary>
        /// 初始化
        /// </summary>
        public static void Init()
        {
            //Add<IModule>();
            Add<UnitModule>(new UnitModule());
            Add<QualityMgr>(QualityMgr.instance);
            Add<UICopyInfoMain>(UICopyInfoMain.Instance);
        }

        /// <summary>
        /// 清理:退出登出/重连时调用
        /// </summary>
        public static void Clear(bool reconnect = false)
        {
            int length = modules.Count;
            for (int i = 0; i < length; i++)
            {
                modules[i].Clear(reconnect);
            }
        }

        /// <summary>
        /// 更新
        /// </summary>
        public static void Update()
        {
            int length = updates.Count;
            for (int i = 0; i < length; i++)
            {
                updates[i].Update();
            }
        }

        /// <summary>
        /// 开始切换场景
        /// </summary>
        public static void BegChgScene()
        {
            int length = modules.Count;
            for (int i = 0; i < length; i++)
            {
                modules[i].BegChgScene();
            }
        }

        /// <summary>
        /// 结束切换场景
        /// </summary>
        public static void EndChgScene()
        {
            int length = modules.Count;
            for (int i = 0; i < length; i++)
            {
                modules[i].EndChgScene();
            }
        }

        public static void LocalChanged()
        {
            int length = modules.Count;
            for (int i = 0; i < length; i++)
            {
                modules[i].LocalChanged();
            }
        }
        #endregion
    }
}