/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2015.3.20 20:09:22
 ============================================================================*/

#if LOONG_AB_SYNC
using System.IO;
using UnityEngine;
using System.Collections;

namespace Loong.Game
{
    /// <summary>
    /// 同步加载资源管理类
    /// </summary>
    public class AssetLoadSync : AssetLoadBase
    {
        #region 字段

        /// <summary>
        /// 停顿计数
        /// </summary>
        private int pauceCnt = 0;

        /// <summary>
        /// 停顿的阈值
        /// </summary>
        private int threhold = int.MaxValue;
#if LOONG_AB_LOG
        private string logPath = "./ABLog.txt";
#endif
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        /// <summary>
        /// 加载资源清单文件
        /// </summary>
        /// <returns></returns>
        private void LoadManifest()
        {
            string manifestPath = prefix + AssetPath.Platform;
            AssetBundle ab = AssetBundle.LoadFromFile(manifestPath);
            if (ab == null)
            {
                iTrace.Error("Loong", "load :{0}, AB is null", manifestPath);
            }
            else
            {
                var name = typeof(AssetBundleManifest).Name;
                manifest = ab.LoadAsset<AssetBundleManifest>(name);
                ab.Unload(false);
                SetTotal();
            }
        }

        /// <summary>
        /// 同步 加载依赖的资源
        /// </summary>
        private void LoadDepend(string name)
        {
            string[] depends = GetDepends(name);
            if (depends == null || depends.Length == 0) return;
            int length = depends.Length;
            for (int i = 0; i < length; i++)
            {
                var depend = depends[i];
                if (string.IsNullOrEmpty(depend)) continue;
                if (dic.ContainsKey(depend))
                {
                    AssetInfo info = dic[depend];
                    ++info.Ref;
                    SetProgress();
                }
                else
                {
                    string path = prefix + depend;
                    LoadBundle(depend, path);
                }
            }
        }

        /// <summary>
        /// 同步步 加载实际资源包
        /// </summary>
        private void LoadBundle(string name, string path)
        {
            if (string.IsNullOrEmpty(name))
            {
                return;
            }
            if (dic.ContainsKey(name))
            {
                SetProgress();
                return;
            }
#if UNITY_EDITOR
#if LOONG_AB_LOG
            using (StreamWriter sw = new StreamWriter(logPath))
            {
                sw.Write(path);
            }
#endif
#endif
            AssetBundle ab = AssetBundle.LoadFromFile(path);
            if (ab == null && (App.IsDebug))
            {
                iTrace.Error("Loong", "load:{0}, AB is null", path);
            }
            else
            {
                Add(name, ab);
            }
            SetProgress();

#if UNITY_EDITOR
#if LOONG_AB_LSNR
            AddLsnr(name);
#endif
#endif
        }

        /// <summary>
        ///  同步 加载资源包
        /// </summary>
        private void LoadAssets()
        {
            int count = loadKeys.Count;
            if (count < 1)
            {
                Complete();
                pauceCnt = 0;
                threhold = int.MaxValue;
                return;
            }
            if (manifest == null) LoadManifest();
            var abName = loadKeys.Dequeue();
            var path = prefix + abName;
            if (!File.Exists(path))
            {
#if UNITY_EDITOR
                iTrace.Error("Loong", "加载ab:{0}不存在,请确定是否更新并打包AB;如果是,请检查对应文件的资源包名是否设置,如果没有设置包名,请查阅SVN日志,让上传人员处理或本地自行处理", abName);
#else
                if (App.IsDebug)
                {
                    iTrace.Error("Loong", "load AB:{0}, file not exist", path);
                }
#endif
                SetProgress();
            }
            else
            {
                LoadDepend(abName);
                LoadBundle(abName, path);
#if UNITY_EDITOR && LOONG_LOAD_LOG
                if (IPro != null && User.instance.MapData.Level > 0)
                {
                    AddLoadLsnr(abName);
                }
                iTrace.Error("Loong", "Load----------------------------:{0}", abName);
#endif
            }

            Handler(abName);
            if (IPro == null)
            {
                LoadAssets();
                return;
            }
            ++pauceCnt;
            if (pauceCnt > threhold)
            {
                pauceCnt = 0;
                mono.StartCoroutine(YieldLoad());
            }
            else
            {

                LoadAssets();
            }
        }

        private IEnumerator YieldLoad()
        {
            yield return new WaitForEndOfFrame();
            LoadAssets();
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override void Start()
        {
            if (Downing) return;
            if (IPro != null)
            {
                threhold = loadKeys.Count / 30;
                threhold = (threhold < 1 ? 1 : threhold);
            }
#if GAME_DEBUG
            BegTimer();
#endif
            base.Start();
            Downing = true;
            LoadAssets();
        }

        public override void Refresh()
        {
            prefix = AssetPath.AssetBundle;
        }
        #endregion
    }
}
#endif