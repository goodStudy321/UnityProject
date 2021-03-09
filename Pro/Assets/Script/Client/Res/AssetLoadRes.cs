//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/8/9 14:25:31
//=============================================================================

using System;
using System.IO;
using UnityEngine;

using System.Collections;
using System.Collections.Generic;
using UnityEngine.SceneManagement;

#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.SceneManagement;
#endif

using Object = UnityEngine.Object;

namespace Loong.Game
{
    using ResDic = Dictionary<string, ResInfo>;
    using PathDic = Dictionary<string, string>;

    public class AssetLoadRes : AssetLoadBase
    {
        #region 字段
        private int pauceCnt = 0;

        private int threhold = int.MaxValue;

        private LoadResCfg cfg = null;


        /// <summary>
        /// k:资源名称,无AB后缀
        /// v:资源
        /// </summary>
        private ResDic resDic = new ResDic();

        /// <summary>
        /// k:资源名称,有AB名称
        /// v:资源路径
        /// </summary>
        private PathDic pathDic = new PathDic();

        public const string path = "./Assets/Script/Client/Res/ResSetting.xml";
        #endregion

        #region 属性


        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法



        private string GetPath(string name)
        {
            if (string.IsNullOrEmpty(name)) return null;
            string path = null;

#if UNITY_EDITOR
            if (pathDic.ContainsKey(name))
            {
                path = pathDic[name];
            }
            if (path == null)
            {
                var arr = AssetDatabase.GetAssetPathsFromAssetBundle(name);
                var len = arr.Length;
                if (len < 1)
                {

                }
                else if (len == 1)
                {
                    path = arr[0];
                }
                else
                {
                    var nn = Path.GetFileNameWithoutExtension(name);
                    if (nn.LastIndexOf("_mat") < 0)
                    {
                        iTrace.Error("Loong", "本地加载资源包:{0},有多个路径,已取第一个!", name);
                    }
                    path = arr[0];
                }
                pathDic[name] = path;
            }
#endif
            return path;
        }

        private void SetPathDic()
        {
#if UNITY_EDITOR

            pathDic.Clear();
            var allNames = AssetDatabase.GetAllAssetBundleNames();
            int length = allNames.Length;
            for (int i = 0; i < length; i++)
            {
                var name = allNames[i];
                pathDic.Add(name, null);
            }
#endif
        }

        private void Error(string name)
        {
            iTrace.Error("Loong", "未加载到:{0}, 请确认资源是否设置包名", name);
        }

        private void Add(string name, string path, Object obj)
        {
            if (resDic.ContainsKey(name))
            {

            }
            else
            {
                var info = new ResInfo(obj, path);
                resDic.Add(name, info);
            }
        }

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
            var abName = loadKeys.Dequeue();
            var name = Path.GetFileNameWithoutExtension(abName);
            var sfx = Path.GetExtension(name);
            var path = GetPath(abName);
            if (sfx == Suffix.Scene)
            {
                Add(abName, null, null);
            }
            else if (string.IsNullOrEmpty(path))
            {
                SetProgress();
            }
            else
            {
#if UNITY_EDITOR

                var obj = AssetDatabase.LoadAssetAtPath<Object>(path);
                if (obj == null)
                {
                    iTrace.Error("Loong", "加载失败:{0}", path);
                }
                else
                {
                    Add(abName, path, obj);
                }
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
            yield return null;
            LoadAssets();
        }

#if UNITY_EDITOR


        [InitializeOnLoadMethod]
        private static void SetScene()
        {
            var set = new HashSet<string>();
            var scenes = EditorBuildSettings.scenes;
            int length = scenes.Length;
            for (int i = 0; i < length; i++)
            {
                var path = scenes[i].path;
                if (set.Contains(path)) continue;
                set.Add(path);
            }

            var curDir = Directory.GetCurrentDirectory();
            var sceneDir = Path.Combine(curDir, "Assets/Scene");
            var scenePaths = Directory.GetFiles(sceneDir, "*.Unity", SearchOption.AllDirectories);
            var curDirLen = curDir.Length + 1;
            length = scenePaths.Length;
            var newScenes = new List<EditorBuildSettingsScene>();
            for (int i = 0; i < length; i++)
            {
                var scenePath = scenePaths[i];
                scenePath = scenePath.Substring(curDirLen);
                scenePath.Replace('\\', '/');
                var scene = new EditorBuildSettingsScene(scenePath, true);
                newScenes.Add(scene);
            }

            var clearScene = new EditorBuildSettingsScene("Assets/Clear.Unity", true);
            newScenes.Add(clearScene);
            EditorBuildSettings.scenes = newScenes.ToArray();
        }


        [InitializeOnLoadMethod]
        private static void SceneSaved()
        {
            EditorSceneManager.sceneSaved += SceneSaved;
        }

        private static void SceneSaved(Scene scene)
        {
            SetScene();
        }
#endif

        #endregion

        #region 保护方法
        protected override void LoadAsset(string name, ObjHandler cb)
        {
            if (resDic.ContainsKey(name))
            {
                Callback(name, cb);
            }
            else
            {
                AddLoad(name, cb);
                Start();
            }
        }

        protected override void Callback(string abName, ObjHandler cb)
        {
            if (!resDic.ContainsKey(abName))
            {
                return;
            }
            if (cb == null)
            {
                return;
            }
            var info = resDic[abName];
            cb(info.Obj);
        }

        protected override void SetPersistent(string name, bool val = true)
        {
            if (!resDic.ContainsKey(name)) return;
            resDic[name].Persist = true;
        }
        #endregion

        #region 公开方法
        public override void Init()
        {
            base.Init();
            SetPathDic();
        }

        public override void Start()
        {
            if (Downing) return;
            if (IPro != null)
            {
                threhold = loadKeys.Count / 30;
                threhold = (threhold < 1 ? 1 : threhold);
            }
            base.Start();
            Downing = true;
            LoadAssets();
        }


        public override void Refresh()
        {
            prefix = Directory.GetCurrentDirectory() + "/";
        }


        public override bool IsPersist(string name)
        {
            if (string.IsNullOrEmpty(name)) return false;
            var abName = name.ToLower() + Suffix.AB;
            if (resDic.ContainsKey(abName))
            {
                return resDic[abName].Persist;
            }
            return false;
        }

        public override bool Exist(string name)
        {
            return true;
        }
        #endregion
    }
}
