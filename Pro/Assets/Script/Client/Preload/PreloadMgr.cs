using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.6.3
    /// BG:预加载管理类
    /// </summary>
    public static class PreloadMgr
    {
        #region 字段
        /// <summary>
        /// 预加载音效
        /// </summary>
        public static readonly PreloadAudio audio = new PreloadAudio();

        /// <summary>
        /// 预加载预制件
        /// </summary>
        public static readonly PreloadPrefab prefab = new PreloadPrefab();

        /// <summary>
        /// 预加载图片
        /// </summary>
        public static readonly PreloadBase texture = new PreloadBase();

        /// <summary>
        /// 通用预加载
        /// </summary>
        public static readonly PreloadBase normal = new PreloadBase();

        /// <summary>
        /// 预加载场景
        /// </summary>
        public static readonly PreloadScene scene = new PreloadScene();

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
        /// 将预加载列表添加到资源加载列表
        /// </summary>
        public static void Execute()
        {
            audio.Execute();
            prefab.Execute();
            texture.Execute();
            normal.Execute();
            scene.Execute();
            EventMgr.Trigger("ExePreload");
        }

        /// <summary>
        /// 预加载UI
        /// </summary>
        /// <param name="id"></param>
        public static void UI(ushort id)
        {
            UIConfig conf = UIConfigManager.instance.Find(id);
            UI(conf);
        }

        /// <summary>
        /// 预加载UI资源
        /// </summary>
        /// <param name="conf"></param>
        public static void UI(UIConfig conf)
        {
            if (conf == null) return;
            prefab.Add(conf.typeName);
            audio.Add(conf.openAudio);
            audio.Add(conf.closeAudio);
        }
        #endregion
    }
}