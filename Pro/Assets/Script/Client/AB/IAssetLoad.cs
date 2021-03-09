/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2015.3.20 20:09:22
 ============================================================================*/
using System;
using UnityEngine;


using Object = UnityEngine.Object;

namespace Loong.Game
{
    /// <summary>
    /// 对象处理委托
    /// </summary>
    /// <param name="obj"></param>
    public delegate void ObjHandler(Object obj);

    /// <summary>
    /// 资源加载接口;加载回调(cb)尽量不要使用匿名委托和Lambda表达式
    /// </summary>
    public interface IAssetLoad
    {

        #region 属性
        /// <summary>
        /// 是否在加载
        /// </summary>
        bool Downing { get; }

        /// <summary>
        /// 进度属性
        /// </summary>
        IProgress IPro { get; set; }

        /// <summary>
        /// 默认为true:加载完结束时自动关闭进度接口
        /// </summary>
        bool AutoCloseIPro { get; set; }

        /// <summary>
        /// 加载场景计数器,通过预加载场景将计数器递增,场景加载完成后递减
        /// </summary>
        byte LoadSceneCount { get; set; }

        /// <summary>
        /// 清单文件
        /// </summary>
        AssetBundleManifest Manifest { get; set; }
        #endregion

        #region 方法
        /// <summary>
        /// 获取AB
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        AssetBundle Get(string name);

        /// <summary>
        /// 获取AB
        /// </summary>
        /// <param name="name"></param>
        /// <param name="sfx"></param>
        /// <returns></returns>
        AssetBundle Get(string name, string sfx);

        #region 添加资源到加载列表接口
        /// <summary>
        /// 向加载列表中添加项
        /// </summary>
        /// <param name="name">名称(包含后缀)</param>
        /// <param name="cb">加载完成回调</param>
        void Add(string name, ObjHandler cb);

        /// <summary>
        /// 向加载列表中添加项
        /// </summary>
        /// <param name="name">名称</param>
        /// <param name="sfx">后缀</param>
        /// <param name="cb">加载完成回调</param>
        void Add(string name, string sfx, ObjHandler cb);

        /// <summary>
        /// 开始加载
        /// </summary>
        void Start();
        #endregion

        #region 直接加载接口
        /// <summary>
        /// 加载资源
        /// </summary>
        /// <param name="name">名称(包含后缀)</param>
        /// <param name="cb">加载完成回调</param>
        void Load(string name, ObjHandler cb);

        /// <summary>
        /// 加载资源
        /// </summary>
        /// <param name="name">名称</param>
        /// <param name="sfx">后缀</param>
        /// <param name="cb">加载完成回调</param>
        void Load(string name, string sfx, ObjHandler cb);
        #endregion
        /// <summary>
        /// 释放指定名称资源(包含依赖)
        /// </summary>
        /// <param name="name">名称(包含后缀)</param>
        /// <param name="force">true:绕过引用计数释放;false:引用计数递减为0时释放,对持久化资源无效</param>
        void Unload(string name, bool force = false);

        /// <summary>
        /// 释放指定名称和后缀资源(包含依赖)
        /// </summary>
        /// <param name="name">名称</param>
        /// <param name="sfx">后缀</param>
        /// <param name="force">true:绕过引用计数释放;false:引用计数递减为0时释放,对持久化资源无效</param>
        void Unload(string name, string sfx, bool force = false);


        /// <summary>
        /// 设置持久化
        /// </summary>
        /// <param name="name">名称(包含后缀)</param>
        /// <param name="val">true:持久化</param>
        void SetPersist(string name, bool val = true);

        /// <summary>
        /// 设置资源为持久的
        /// </summary>
        /// <param name="name">名称</param>
        /// <param name="sfx">后缀</param>
        /// <param name="val">true:持久化</param>
        void SetPersist(string name, string sfx, bool val = true);

        /// <summary>
        /// 判断资源是否持久化
        /// </summary>
        /// <param name="name">资源完成名称</param>
        /// <returns></returns>
        bool IsPersist(string name);

        /// <summary>
        /// 释放资源
        /// </summary>
        /// <param name="unload"></param>
        void Dispose(bool unload = true);

        /// <summary>
        /// 刷新
        /// </summary>
        void Refresh();

        /// <summary>
        /// 判断资源是否存在
        /// </summary>
        /// <param name="name">完整资源名</param>
        /// <returns></returns>
        bool Exist(string name);
        #endregion

        #region 事件
        /// <summary>
        /// 开始加载资源
        /// </summary>
        event Action start;

        /// <summary>
        /// 所有资源加载结束回调事件
        /// 1,所有资源加载结束之后执行但不会自动清空,需要自己注销
        /// 2,在调用Load或者Start之前就设置,防止使用的是同步加载方式
        /// </summary>
        event Action complete;
        #endregion

        #region 索引器

        #endregion
    }
}