//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/11/7 17:21:44
//=============================================================================

using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using System.Threading;
using UnityEngine.Networking;

namespace Phantom
{
    /// <summary>
    /// Localization
    /// </summary>
    public class Localization
    {
        #region 字段
        public static readonly Localization Instance = new Localization();
        #endregion

        #region 属性

        #endregion

        #region 委托事件
        /// <summary>
        /// 本地化发生改变事件
        /// </summary>
        public event Action changed = null;
        #endregion

        #region 构造方法
        private Localization()
        {

        }
        #endregion

        #region 私有方法
        private void Read()
        {
            var folder = FileLoader.Home;
            var name = folder + "/" + LocalCfgManager.instance.source;
            string path = AssetPath.WwwStreaming;
            var src = Path.Combine(path, name);
            using (var web = UnityWebRequest.Get(src))
            {
                web.SendWebRequest();
                while (!web.isDone) continue;
                var cache = GetPath(AssetPath.Cache, name);
                byte[] buf = web.downloadHandler.data;
                using (var fs = new FileStream(cache, FileMode.Create))
                {
                    fs.Write(buf, 0, buf.Length);
                }
                Thread.Sleep(1);

                var dest = GetPath(AssetPath.Persistent, name);
                var decomp = DecompFty.Create();
                decomp.Src = cache;
                decomp.Dest = dest;
                if (decomp.Execute())
                {
                    using (var fs = File.OpenRead(dest))
                    {
                        var data = new byte[fs.Length];
                        fs.Read(data, 0, (int)fs.Length);
                        LocalCfgManager.instance.Load(data);
                        if (App.IsReleaseDebug)
                        {
                            Debug.Log("Loong,读取本地化配置成功");
                        }
                    }
                }
                else
                {
                    throw new Exception("解压失败");
                }
            }
        }

        private void Register()
        {
            Table.NewHelper.Clear();
            Table.NewHelper.Register(typeof(LocalCfg), NewLocalCfg);
        }

        private object NewLocalCfg()
        {
            return new LocalCfg();
        }

        private void ReadFromTmp()
        {
            Register();
            var path = string.Format("Tmp/{0}/{1}", FileLoader.Home, LocalCfgManager.instance.source);
            var src = Path.Combine(AssetPath.WwwStreaming, path);
            using (var web = UnityWebRequest.Get(src))
            {
                web.SendWebRequest();
                while (!web.isDone) continue;
                if (web.isHttpError || web.isNetworkError)
                {
                    var err = web.error;
                    iTrace.Error("Loong", "加载本地化配置异常:{0}", err);
                }
                else
                {
                    var buf = web.downloadHandler.data;
                    LocalCfgManager.instance.Load(buf);
                }
            }
        }


        private string GetPath(string dir, string name)
        {
            var path = Path.Combine(dir, name);
            var fullDir = Path.GetDirectoryName(path);
            if (!Directory.Exists(fullDir)) Directory.CreateDirectory(fullDir);
            return path;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void Init()
        {
            var folder = FileLoader.Home;
            if (App.IsEditor)
            {
                LocalCfgManager.instance.Load(folder);
            }
            else if (AssetPath.ExistInPersistent)
            {
                LocalCfgManager.instance.Load(folder);
            }
            else
            {
                try
                {
                    ReadFromTmp();
                }
                catch (Exception e)
                {
                    Debug.LogErrorFormat("Loong,decom and read localCfg err:{0}", e.Message);
                    Thread.Sleep(20);
                    ReadFromTmp();
                }
            }
        }

        /// <summary>
        /// 获取描述
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        public string GetDes(int id)
        {
            var nid = (uint)id;
            return GetDes(nid);
        }

        /// <summary>
        /// 获取描述
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        public string GetDes(uint id)
        {
            var cfg = LocalCfgManager.instance.Find(id);
            if (cfg == null)
            {
                return string.Format("无本地化配置:{0}", id);
            }
            // cfg.lDes; //简体
            return cfg.des; //繁体

        }


        #endregion
    }
}