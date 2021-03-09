/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2015.3.20 20:09:22
 ============================================================================*/
#if !LOONG_AB_SYNC
using System.IO;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using ABM = UnityEngine.AssetBundleManifest;
using UnityEngine.Networking;


namespace Loong.Game
{
    /// <summary>
    /// 异步加载资源管理类
    /// </summary>
    public class AssetLoadAsync : AssetLoadBase
    {
#region 字段

        /// <summary>
        /// 正在下载的详细资源列表包含依赖
        /// </summary>
        private HashSet<string> detailSet = new HashSet<string>();

        /// <summary>
        /// 正在下载的目标资源列表
        /// </summary>
        private HashSet<string> targetSet = new HashSet<string>();
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
        private IEnumerator LoadManifest()
        {
#if LOONG_AB_ASYNC_FROMFILE
            string path = prefix + AssetPath.Platform;
            AssetBundleCreateRequest req = AssetBundle.LoadFromFileAsync(path);
            yield return req;
            string name = typeof(ABM).Name;
            if (req.assetBundle == null)
            {
                iTrace.Error("Loong", string.Format("加载清单:{0}, AssetBundle为空,可能未打包", path));
            }
            else
            {
                manifest = req.assetBundle.LoadAsset<ABM>(name);
                req.assetBundle.Unload(false);
            }
#else
            string path = prefix + AssetPath.Platform;
            using (UnityWebRequest request = UnityWebRequest.Get(path))
            {
                DownloadHandlerAssetBundle handler = new DownloadHandlerAssetBundle(request.url, uint.MaxValue);
                request.downloadHandler = handler;
                yield return request.SendWebRequest();
                var err = request.error;
                if (string.IsNullOrEmpty(err))
                {
                    string name = typeof(ABM).Name;
                    manifest = handler.assetBundle.LoadAsset<ABM>(name);
                    handler.assetBundle.Unload(false);
                }
                else
                {
                    iTrace.Error("Loong", string.Format("加载清单错误:{0},路径:{1}", err, path));
                }
            }
#endif
            if (manifest == null)
            {
                Downing = false;
            }
            else
            {
                SetTotal();
                ChkHuge();
                LoadAssets();
            }
        }

        /// <summary>
        /// 检查大资源
        /// </summary>
        private void ChkHuge()
        {
            if (loadKeys.Count == 0) return;
            int length = loadKeys.Count;
            for (int i = 0; i < length; i++)
            {
                string name = loadKeys[i];
                IsHuge(name);
            }
        }



        /// <summary>
        /// 异步 加载依赖的资源
        /// </summary>
        private IEnumerator LoadDepend(string name)
        {
            string[] depends = manifest.GetAllDependencies(name);
            if (depends == null || depends.Length == 0) yield break;
            int length = depends.Length;
            for (int i = 0; i < length; i++)
            {
                string dName = depends[i];
                if (string.IsNullOrEmpty(dName)) continue;
                if (dic.ContainsKey(dName))
                {
                    AssetInfo info = dic[dName];
                    ++info.Ref;
                    SetProgress();
                }
                else
                {
                    while (detailSet.Contains(dName)) yield return 0;
                    yield return LoadBundle(dName);
                }
            }
        }

        /// <summary>
        /// 异步 实际资源包的协同
        /// </summary>
        private IEnumerator LoadBundle(string name, bool unload = true)
        {
            if (string.IsNullOrEmpty(name))
            {
                yield break;
            }
            if (dic.ContainsKey(name))
            {
                AssetInfo info = dic[name];
                ++info.Ref;
                SetProgress();
                yield break;
            }
            if (detailSet.Contains(name))
            {
                yield break;
            }
            detailSet.Add(name);
#if LOONG_AB_ASYNC_FROMFILE
            string path = SbTool.Get(urlSb, prefix, name);
            var req = AssetBundle.LoadFromFileAsync(path);
            yield return req;
            if (req.assetBundle == null)
            {
                iTrace.Error("Loong", "load:{0}, AB is null", path);
            }
            else
            {
                Add(name, req.assetBundle, up);
            }
#else
            string path = prefix + name;
            using (UnityWebRequest request = UnityWebRequest.Get(path))
            {
                DownloadHandlerAssetBundle handler = new DownloadHandlerAssetBundle(request.url, uint.MaxValue);
                request.downloadHandler = handler;
                yield return request.SendWebRequest();
                var err = request.error;
                if (string.IsNullOrEmpty(err))
                {
                    Add(name, handler.assetBundle);
                }
                else
                {
#if UNITY_EDITOR
                    iTrace.Error("Loong", "加载资源包:{0},错误:{1},先确定资源是否打包?如果未打包使用快捷键Ctrl+Alt+K打包,反之请找相关程序", path, err);
#else
                    iTrace.Error("Loong", "load AB err:{0}", err);
#endif
                }
            }
#endif
            detailSet.Remove(name);
            SetProgress();
        }

        /// <summary>
        ///  异步 加载资源包
        /// </summary>
        private IEnumerator LoadAsset(string name)
        {
            yield return LoadDepend(name);
            yield return LoadBundle(name);
            Handler(name);
            if (targetSet.Contains(name))
            {
                targetSet.Remove(name);
            }
            LoadAssets();
        }

        /// <summary>
        /// 异步 加载资源包列表
        /// </summary>
        private void LoadAssets()
        {
            while (true)
            {
                int count = loadKeys.Count;
                if (count == 0)
                {
                    if (targetSet.Count == 0)
                    {
                        Complete();
                    }
                    break;
                }
                if (targetSet.Count > 30) break;
                int last = count - 1;
                string abName = loadKeys[last];
                loadKeys.RemoveAt(last);
                targetSet.Add(abName);
                mono.StartCoroutine(LoadAsset(abName));
            }
        }
#endregion

#region 保护方法

        protected override void Reset()
        {
            base.Reset();
            detailSet.Clear();
            targetSet.Clear();
        }

        private bool IsHuge(string name)
        {
            string nn = Path.GetFileNameWithoutExtension(name);
            string sfx = Path.GetExtension(nn);
            switch (sfx)
            {
                case Suffix.Prefab:
                //case Suffix.Fbx:
                case Suffix.Jpg:
                case Suffix.Png:
                case Suffix.Tga:
                case Suffix.Exr:
                    return true;
                default:
                    return false;
            }
        }

#endregion

#region 公开方法

        public override void Start()
        {
            if (Downing) return;
            BegTimer();
            base.Start();
            Downing = true;
            if (manifest != null) LoadAssets();
            else mono.StartCoroutine(LoadManifest());
        }

        public override void Refresh()
        {
#if LOONG_AB_ASYNC_FROMFILE
            prefix = AssetPath.AssetBundle;
#else
            prefix = AssetPath.WwwAssetBundle;
#endif
        }

#endregion
    }
}
#endif