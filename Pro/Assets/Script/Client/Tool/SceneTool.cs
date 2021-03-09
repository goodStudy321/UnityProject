using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.SceneManagement;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.3.20
    /// BG:场景工具
    /// </summary>
    public static class SceneTool
    {
        #region 字段
        /// <summary>
        /// 清理场景的名称
        /// </summary>
        public static string ClearScene = "Clear";

        public static Action<Scene, LoadSceneMode> onloaded = null;
        #endregion

        #region 属性

        #endregion

        #region 构造方法
        static SceneTool()
        {
            SceneManager.sceneLoaded += OnLoaded;
        }
        #endregion

        #region 私有方法
        /// <summary>
        /// 场景加载回调
        /// </summary>
        /// <param name="scene"></param>
        /// <param name="mode"></param>
        private static void OnLoaded(Scene scene, LoadSceneMode mode)
        {
            if (scene.name == "Clear") return;
            MonoEvent.Start(YieldOnLoaded(scene, mode));
        }

        /// <summary>
        /// 场景加载完成判断
        /// </summary>
        /// <param name="scene"></param>
        /// <param name="mode"></param>
        /// <returns></returns>
        private static IEnumerator YieldOnLoaded(Scene scene, LoadSceneMode mode)
        {
            while (!scene.isLoaded) yield return 0;
            if (onloaded != null) onloaded(scene, mode);
            EventMgr.Trigger("OnSceneLoaded", scene.name);
            Refresh(scene, mode);
            /*Resources.UnloadUnusedAssets();
            GC.Collect();*/

        }

        private static IEnumerator YieldUnload(AsyncOperation op)
        {
            yield return op;
            Resources.UnloadUnusedAssets();
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法


        /// <summary>
        /// 加载完成场景后的设置
        /// </summary>
        /// <param name="scene">场景结构</param>
        /// <param name="mode">加载模式</param>
        public static void Refresh(Scene scene, LoadSceneMode mode)
        {
            AudioTool.CheckUniqueListener();
#if UNITY_EDITOR
            ShaderTool.eResetScene(scene);
#endif
        }

        /// <summary>
        /// 多个场景间激活某场景,并隐藏其它场景
        /// </summary>
        /// <param name="name"></param>
        public static void Switch(string name)
        {
            int length = SceneManager.sceneCount;
            for (int i = 0; i < length; i++)
            {
                var scene = SceneManager.GetSceneAt(i);
                if (scene.name == name)
                {
                    SceneManager.SetActiveScene(scene);
                    SetActive(scene, true);
                }
                else
                {
                    SetActive(scene, false);
                }
            }
        }

        /// <summary>
        /// 设置场景根游戏对象的激活状态
        /// </summary>
        /// <param name="name"></param>
        /// <param name="active"></param>
        public static void SetActive(string name, bool active)
        {
            var scene = SceneManager.GetSceneByName(name);
            SetActive(scene, active);
        }

        /// <summary>
        /// 设置场景根游戏对象的激活状态
        /// </summary>
        /// <param name="scene">场景</param>
        /// <param name="active">激活状态</param>
        public static void SetActive(Scene scene, bool active)
        {
            if (!scene.IsValid()) return;
            var gos = scene.GetRootGameObjects();
            int length = gos.Length;
            for (int i = 0; i < length; i++)
            {
                gos[i].SetActive(active);
            }
        }

        public static IEnumerator Unload(string name)
        {
            var scene = SceneManager.GetSceneByName(name);
            if (!scene.IsValid()) yield break;
            var active = SceneManager.GetActiveScene();
            if (active.path.Equals(scene.path))
            {
                var clear = SceneManager.GetSceneByName(ClearScene);
                if (!clear.IsValid())
                {
                    SceneManager.LoadScene(ClearScene, LoadSceneMode.Additive);
                    for (int i = 0; i < 2; i++)
                    {
                        yield return null;
                    }
                    clear = SceneManager.GetSceneByName(ClearScene);
                }
                SceneManager.SetActiveScene(clear);
            }
            AsyncOperation async = null;
            try
            {
                 async = SceneManager.UnloadSceneAsync(scene);

            }
            catch (Exception e)
            {
                iTrace.Error("Loong", "Unload:{0},IsValid():{1}, loaded:{2}, err:{3}", scene.name, scene.IsValid(), scene.isLoaded, e.Message);
            }
            yield return async;
            yield return null;
            Resources.UnloadUnusedAssets();
            yield return null;
        }


        public static bool Exist(string name)
        {
            var scene = SceneManager.GetSceneByName(name);
            return scene.IsValid();
        }

        public static Scene Get(string name)
        {
            var scene = SceneManager.GetSceneByName(name);
            return scene;
        }

        public static IEnumerator SwitchClear(string filter)
        {
            var lst = new List<Scene>();
            int length = SceneManager.sceneCount;
            for (int i = 0; i < length; i++)
            {
                var scene = SceneManager.GetSceneAt(i);
                if (scene.IsValid()) lst.Add(scene);
            }
            length = lst.Count;
            for (int i = 0; i < length; i++)
            {
                var scene = lst[i];
                var sceneName = scene.name;
                var fullSceneName = sceneName + Suffix.Scene;
                if (AssetMgr.Instance.IsPersist(fullSceneName))
                {
                    continue;
                }
                if (filter == sceneName)
                {
                    continue;
                }
                if (sceneName == ClearScene)
                {
                    continue;
                }

                yield return Unload(sceneName);
            }
        }
        #endregion
    }
}