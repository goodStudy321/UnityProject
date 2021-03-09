/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2015.3.20 20:09:22
 ============================================================================*/

using System;
using System.IO;
using System.Text;
using UnityEngine;
using System.Diagnostics;
using System.Collections.Generic;
using UnityEngine.SceneManagement;

namespace Loong.Game
{
    using AssetDic = Dictionary<string, AssetInfo>;
    using DependDic = Dictionary<string, string[]>;
    using HandlerDic = Dictionary<string, ObjHandler>;

    /// <summary>
    /// 加载资源管理基类
    /// </summary>
    public abstract class AssetLoadBase : IAssetLoad
    {
        #region 字段
#if GAME_DEBUG
        private int begCnt = 0;

        private float elapsed = 0f;

        private float begTimer = 0f;
#endif

        /// <summary>
        /// 正在加载的资源位置
        /// </summary>
        private int index = 0;
        /// <summary>
        /// 资源加载的总数量/包含依赖
        /// </summary>
        private float total = 0;

        private IProgress iPro = null;

        private byte sceneCount = 0;

        private bool downing = false;

        private bool autoCloseIPro = true;

        private Queue<string> unloads = new Queue<string>();

        /// <summary>
        /// 资源加载的前缀
        /// </summary>
        protected string prefix = null;

        /// <summary>
        /// 资源加载管理类
        /// </summary>
        protected EasyMono mono = null;

        /// <summary>
        /// 资源清单文件
        /// </summary>
        protected AssetBundleManifest manifest = null;

        /// <summary>
        /// 加载资源回调字典键值的集合
        /// </summary>
        protected Queue<string> loadKeys = new Queue<string>();

        /// <summary>
        /// 所有已加载资源字典
        /// </summary>
        protected AssetDic dic = new AssetDic();

        /// <summary>
        /// 加载资源回调字典
        /// </summary>
        protected HandlerDic cbDic = new HandlerDic();

        /// <summary>
        /// 依赖字典, k:ab完整名称, v:依赖数组
        /// </summary>
        protected DependDic dependDic = new DependDic();


#if UNITY_EDITOR
#if LOONG_AB_LSNR
        protected AssetLoadLsnr als = new AssetLoadLsnr();

        /// <summary>
        /// 详细加载资源,包含依赖
        /// </summary>
        public AssetLoadLsnr Als { get { return als; } }
#endif
#if LOONG_LOAD_LOG
        protected AssetLoadLsnr loadAls = new AssetLoadLsnr("../AssetLoadLsnr/AssetLoadSimple.xml");
        /// <summary>
        /// 直接加载资源
        /// </summary>
        public AssetLoadLsnr LoadAls { get { return loadAls; } }
#endif
#endif

        #endregion

        #region 属性

        public bool Downing
        {
            get { return downing; }
            set { downing = value; }
        }

        public IProgress IPro
        {
            get { return iPro; }
            set
            {
                iPro = value;
                if (iPro != null) IPro.Open();
            }
        }

        public bool AutoCloseIPro
        {
            get { return autoCloseIPro; }
            set { autoCloseIPro = value; }
        }


        public byte LoadSceneCount
        {
            get { return sceneCount; }
            set { SetSceneCount(value); }
        }

        public AssetBundleManifest Manifest
        {
            get { return manifest; }
            set
            {
                manifest = value;
                if (value == null) ClearDepends();
            }
        }
        #endregion

        #region 委托事件

        public event Action start = null;

        public event Action complete = null;

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        /// <summary>
        /// 解析资源回调
        /// </summary>
        /// <param name="abName">ab名称</param>
        /// <param name="cb">回调</param>
        protected virtual void Callback(string abName, ObjHandler cb)
        {
            if (!dic.ContainsKey(abName))
            {
                return;
            }
            if (cb == null)
            {
                return;
            }
            var ai = dic[abName];
            var ab = ai.Ab;
            if (ab == null)
            {
                return;
            }
            if (ab.isStreamedSceneAssetBundle)
            {
                cb(null); return;
            }
            var names = ab.GetAllAssetNames();
            if (names == null || names.Length == 0)
                return;

            var count = cb.GetInvocationList().Length;
            ai.URef += count;

            if (names.Length == 1)
            {
                string realName = names[0];
                cb(ab.LoadAsset(realName));
            }
            else
                cb(ab);
        }

        /// <summary>
        /// 设置加载场景数量
        /// </summary>
        /// <param name="value"></param>
        private void SetSceneCount(byte value)
        {
            if (value > 0)
            {
                if (sceneCount == 0)
                {
                    SceneTool.onloaded += OnSceneLoaded;
                }
            }
            else if (value == 0)
            {
                if (sceneCount > 0)
                {
                    SceneTool.onloaded -= OnSceneLoaded;
                }
            }
            sceneCount = value;
        }

        /// <summary>
        /// 场景加载完成后关闭进度接口
        /// </summary>
        /// <param name="scene"></param>
        /// <param name="mode"></param>
        private void OnSceneLoaded(Scene scene, LoadSceneMode mode)
        {
            if (LoadSceneCount > 0) --LoadSceneCount;
            if (LoadSceneCount != 0) return;
            //UnloadType(Suffix.Scene);
            CloseProgress();
        }


        #region GAME_DEBUG
        private int GetCount()
        {
            return dic.Count;
        }
        #endregion
        #endregion

        #region 保护方法

        /// <summary>
        /// 结束计时
        /// </summary>
        protected void BegTimer()
        {
#if GAME_DEBUG
            begCnt = GetCount();
            begTimer = Time.realtimeSinceStartup;
#endif
        }

        /// <summary>
        /// 结束计时
        /// </summary>
        protected void EndTimer()
        {
#if GAME_DEBUG
            int endCnt = GetCount();
            int realCnt = endCnt - begCnt;
            elapsed = Time.realtimeSinceStartup - begTimer;
            iTrace.Warning("Loong", string.Format("加载 {0}个资源结束,耗时:{1}/秒", realCnt, elapsed));
#endif
        }

#if UNITY_EDITOR
#if LOONG_AB_LSNR
        protected void AddLsnr(string name)
        {
            AddLsnr(als, name);
        }
#endif

#if LOONG_LOAD_LOG
        protected void AddLoadLsnr(string name)
        {
            AddLsnr(loadAls, name);
        }
#endif
        protected void AddLsnr(AssetLoadLsnr lsnr, string name)
        {
            if (lsnr.Contains(name)) return;
            if (!dic.ContainsKey(name)) return;
            var info = dic[name];
            var ab = info.Ab;
            string[] paths = null;
            if (ab.isStreamedSceneAssetBundle)
            {
                paths = ab.GetAllScenePaths();
            }
            else
            {
                paths = ab.GetAllAssetNames();
            }
            if (paths == null || paths.Length < 1) return;
            int length = paths.Length;
            for (int i = 0; i < length; i++)
            {
                var path = paths[i];
                lsnr.Add(name, path);
            }
        }
#endif

        #region 卸载
        protected void ReadyUnload(string name, bool force = false)
        {
            if (downing)
            {
                unloads.Enqueue(name);
            }
            else
            {
                Unloads(name, force);
            }
        }

        /// <summary>
        /// 卸载资源及其依赖
        /// </summary>
        /// <param name="name">名称</param>
        /// <param name="force">true:强制卸载</param>
        protected void Unloads(string name, bool force = false)
        {
            if (!dic.ContainsKey(name)) return;
            var info = dic[name];
            if (info.URef > 0)
            {
                --info.URef;
            }
            if (info.URef > 0) return;
            Remove(info, name, force);
            var depends = GetDepends(name);
            if (depends == null || depends.Length == 0) return;
            int length = depends.Length;
            for (int i = 0; i < length; i++)
            {
                var depend = depends[i];
                if (string.IsNullOrEmpty(depend)) continue;
                if (!dic.ContainsKey(depend)) continue;
                var di = dic[depend];
                if (di.URef > 0) continue;
                Remove(di, depend, force);
            }
        }

        /// <summary>
        /// 获取依赖资源数组
        /// </summary>
        /// <param name="abName"></param>
        /// <returns></returns>
        protected string[] GetDepends(string abName)
        {
            string[] depends = null;
            if (dependDic.ContainsKey(abName))
            {
                depends = dependDic[abName];
            }
            else
            {
                depends = Manifest.GetAllDependencies(abName);
                dependDic.Add(abName, depends);
            }
            return depends;
        }

        /// <summary>
        /// 设置资源为持久化的
        /// </summary>
        /// <param name="name"></param>
        protected virtual void SetPersistent(string name, bool val = true)
        {
            if (!dic.ContainsKey(name)) return;
            AssetInfo info = dic[name];
            if (info.Persist) return;
            info.Persist = true;
            var depends = GetDepends(name);
            int length = depends.Length;
            for (int i = 0; i < length; i++)
            {
                string depend = depends[i];
                if (string.IsNullOrEmpty(depend)) continue;
                if (dic.ContainsKey(depend))
                {
                    dic[depend].Persist = val;
                }
#if !LOONG_SUB_ASSET
                else
                {
                    iTrace.Error("Loong", "{0}:depend:{1} not exist,can't SetPersist", name, depend);
                }
#endif
            }
        }

        #endregion

        #region 加载

        #endregion

        #region 进度

        /// <summary>
        /// 初始化下载的资源总数 包含依赖
        /// </summary>
        protected void SetTotal()
        {
            var em = loadKeys.GetEnumerator();
            while (em.MoveNext())
            {
                var name = em.Current;
                AddTotal(name);
            }
        }
        /// <summary>
        /// 更新正在下载的资源总数 包含依赖
        /// </summary>
        protected void AddTotal(string name)
        {
            if (manifest == null) return;
            int cnt = GetDepends(name).Length;
            cnt += 1;
            total += cnt;
        }

        /// <summary>
        /// 更新进度
        /// </summary>
        protected void SetProgress()
        {
            ++index;
            float value = index / total;
            if (iPro != null) iPro.SetProgress(value);
        }

        /// <summary>
        /// 关闭进度窗口
        /// </summary>
        protected void CloseProgress()
        {
            if (iPro == null) return;
            if (!AutoCloseIPro) return;
            iPro.SetProgress(1);
            iPro.Close();
            iPro.SetProgress(0);
            IPro = null;
        }


        #endregion

        #region 回调
        /// <summary>
        /// 解析资源回调
        /// </summary>
        protected void Handler(string name)
        {
            if (cbDic.ContainsKey(name))
            {
                Callback(name, cbDic[name]);
            }
        }

        protected void HandleUnloads()
        {
            while (unloads.Count > 0)
            {
                var name = unloads.Dequeue();
                Unloads(name);
            }
        }

        /// <summary>
        /// 结束加载
        /// </summary>
        protected void Complete()
        {
            Reset();
            EndTimer();
            HandleUnloads();
            if (complete != null) complete();
            if (LoadSceneCount == 0) CloseProgress();
        }

        /// <summary>
        /// 添加加载项
        /// </summary>
        /// <param name="name"></param>
        /// <param name="cb"></param>
        protected void AddLoad(string name, ObjHandler cb)
        {
            if (cbDic.ContainsKey(name))
            {
                if (cb != null) cbDic[name] += cb;
            }
            else
            {
                if (cb != null) cbDic.Add(name, cb);
                loadKeys.Enqueue(name);
                AddTotal(name);
            }
        }

        /// <summary>
        /// 重置正在下载的资源总数为0
        /// </summary>
        protected virtual void Reset()
        {
            total = 0;
            index = 0;
            downing = false;
            cbDic.Clear();
            loadKeys.Clear();
        }

        /// <summary>
        /// 添加已加载资源信息
        /// </summary>
        /// <param name="name"></param>
        /// <param name="ab"></param>
        protected void Add(string name, AssetBundle ab)
        {
            var info = ObjPool.Instance.Get<AssetInfo>();
            info.Ab = ab;
            dic.Add(name, info);
            ++info.Ref;
        }


        protected void Remove(AssetInfo info, string name, bool force = false, bool unload = true)
        {
            info.Unload(force, unload);
            if (info.Ref > 0) return;
            if (info.Persist) return;
            dic.Remove(name);
            ObjPool.Instance.Add(info);
        }

        /// <summary>
        /// 加载资源
        /// </summary>
        /// <param name="name">ab名</param>
        /// <param name="cb">回调</param>
        protected virtual void LoadAsset(string name, ObjHandler cb)
        {
            if (dic.ContainsKey(name))
            {
                Callback(name, cb);
            }
            else
            {
                AddLoad(name, cb);
                Start();
            }
        }
        #endregion

        #endregion

        #region 公开方法
        public virtual void Init()
        {
            mono = EasyMonoMgr.Create(this.GetType());
            Refresh();
#if UNITY_EDITOR
#if LOONG_AB_LSNR
            als.Init();
#endif

#if LOONG_LOAD_LOG
            loadAls.Init();
#endif
#endif
        }

        public void Unload(string name, bool force = false)
        {
            if (string.IsNullOrEmpty(name)) return;
            string abName = name.ToLower() + Suffix.AB;
            ReadyUnload(abName, force);
        }

        public void Unload(string name, string sfx, bool force = false)
        {
            if (string.IsNullOrEmpty(name)) return;
            if (string.IsNullOrEmpty(sfx)) return;
            string abName = name.ToLower() + sfx + Suffix.AB;
            ReadyUnload(abName, force);
        }

        public void SetPersist(string name, bool val = true)
        {
            if (string.IsNullOrEmpty(name)) return;
            string abName = name.ToLower() + Suffix.AB;
            SetPersistent(abName, val);
        }

        public void SetPersist(string name, string sfx, bool val = true)
        {
            if (string.IsNullOrEmpty(name)) return;
            if (string.IsNullOrEmpty(sfx)) return;
            string abName = name.ToLower() + sfx + Suffix.AB;
            SetPersistent(abName, val);
        }

        public virtual bool IsPersist(string name)
        {
            if (string.IsNullOrEmpty(name)) return false;
            var abName = name.ToLower() + Suffix.AB;
            if (dic.ContainsKey(abName))
            {
                return dic[abName].Persist;
            }
            return false;
        }

        /// <summary>
        /// 释放所有资源
        /// </summary>
        public virtual void Dispose(bool unload = true)
        {
            if (Downing) return;
            if (dic.Count == 0) return;
            var keys = new List<string>(dic.Keys);
            int length = keys.Count;
            for (int i = 0; i < length; i++)
            {
                string key = keys[i];
                AssetInfo info = dic[key];
                if (info.Persist) continue;
                dic.Remove(key);
                info.Dispose(unload);
                ObjPool.Instance.Add(info);
            }
            keys.Clear();
            Reset();
            start = null;
            complete = null;
        }

        public virtual void Refresh()
        {

        }

        public AssetBundle Get(string name)
        {
            var abName = name.ToLower() + Suffix.AB;
            if (dic.ContainsKey(abName)) return dic[abName].Ab;
            return null;
        }

        public AssetBundle Get(string name, string sfx)
        {
            var abName = name.ToLower() + sfx + Suffix.AB;
            if (dic.ContainsKey(abName)) return dic[abName].Ab;
            return null;
        }

        /// <summary>
        ///  向加载列表中添加项
        /// </summary>
        /// <param name="name">名称/包含后缀</param>
        /// <param name="cb">回调</param>
        public void Add(string name, ObjHandler cb)
        {
            if (string.IsNullOrEmpty(name)) return;
            string abName = name.ToLower() + Suffix.AB;
            AddLoad(abName, cb);
        }

        /// <summary>
        ///  向加载列表中添加项
        /// </summary>
        /// <param name="name">名称</param>
        /// <param name="sfx">后缀</param>
        /// <param name="cb">回调</param>
        public void Add(string name, string sfx, ObjHandler cb)
        {
            if (string.IsNullOrEmpty(name)) return;
            if (string.IsNullOrEmpty(sfx)) return;
            string abName = name.ToLower() + sfx + Suffix.AB;
            AddLoad(abName, cb);
        }

        /// <summary>
        /// 开始加载/配合Add使用,可以提供进度
        /// </summary>
        public virtual void Start()
        {
            if (start != null) start();
        }

        /// <summary>
        /// 直接加载资源
        /// </summary>
        /// <param name="name">名称/包含后缀</param>
        /// <param name="cb">回调</param>
        public void Load(string name, ObjHandler cb)
        {
            if (string.IsNullOrEmpty(name)) return;
            string abName = name.ToLower() + Suffix.AB;
            LoadAsset(abName, cb);
        }
        /// <summary>
        /// 直接加载资源
        /// </summary>
        /// <param name="name">名称</param>
        /// <param name="sfx">后缀</param>
        /// <param name="cb">回调</param>
        public void Load(string name, string sfx, ObjHandler cb)
        {
            if (string.IsNullOrEmpty(name)) return;
            if (string.IsNullOrEmpty(sfx)) return;
            string abName = name.ToLower() + sfx + Suffix.AB;
            LoadAsset(abName, cb);
        }

        /// <summary>
        /// 判断文件是否存在
        /// </summary>
        /// <param name="name">完整资源名</param>
        /// <returns></returns>
        public virtual bool Exist(string name)
        {
#if LOONG_SUB_ASSET || (LOONG_SIMULATOR_SUB_ASSET && UNITY_EDITOR)
            if (PackDl.Instance.IsOver) return true;
            if (string.IsNullOrEmpty(name))
            {
                return true;
            }
            name = name.ToLower();
            var abName = name + Suffix.AB;
#if (LOONG_SIMULATOR_SUB_ASSET && UNITY_EDITOR)
            var path2 = Path.Combine(AssetPath.AssetBundle, abName);
            if (!File.Exists(path2)) return false;
#else
            if (!AssetMf.Exist(abName)) return false;
#endif
            var depends = GetDepends(abName);
            if (depends == null) return true;
            int length = depends.Length;
            for (int i = 0; i < length; i++)
            {
                var it = depends[i];
                if (string.IsNullOrEmpty(it)) continue;
#if (LOONG_SIMULATOR_SUB_ASSET && UNITY_EDITOR)
                var path = Path.Combine(AssetPath.AssetBundle, it);
                if (File.Exists(path)) continue;
#else
                if (AssetMf.Exist(it)) continue;
#endif
                return false;
            }
            return true;
#else
            return true;
#endif
        }



        protected void ClearDepends()
        {
            dependDic.Clear();
        }
        #endregion
    }
}