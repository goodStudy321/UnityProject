using System.IO;
using Hello.Game;
using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using UnityEngine.SceneManagement;
using UnityEditor.SceneManagement;

namespace Hello.Edit
{
    /// <summary>
    /// 编辑器场景管理
    /// </summary>
    public static class SceneMgr
    {
        #region 字段
        private static EditSceneView data = null;

        /// <summary>
        /// 菜单优先级
        /// </summary>
        public const int Pri = MenuTool.ScenePri + 10;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Hello + "场景工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.AHello + "场景工具/";
        #endregion

        #region 属性
        /// <summary>
        /// 设置数据
        /// </summary>
        public static EditSceneView Data
        {
            get
            {
                if (data == null)
                {
                    data = AssetDataUtil.Get<EditSceneView>();
                }
                return data;
            }
        }
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 获取指定资源场景目录
        /// </summary>
        /// <param name="assetPath"></param>
        /// <returns></returns>
        public static string GetDir(string assetPath)
        {
            if (!assetPath.StartsWith(EditSceneView.prefix))
                return EditSceneView.sharePrefix;
            int startIndex = EditSceneView.prefix.Length;
            int index = assetPath.IndexOf('/', startIndex);
            if (index == -1) return EditSceneView.sharePrefix;
            string sceneDir = assetPath.Substring(0, index);
            return sceneDir;
        }

        /// <summary>
        /// 通过场景名称获取场景资源路径
        /// </summary>
        /// <param name="sceneName"></param>
        /// <returns></returns>
        public static string GetAssetPath(string sceneName)
        {
            if (string.IsNullOrEmpty(sceneName)) return null;
            string assetPath = string.Format("{0}{1}/Unity/{2}.unity", EditSceneView.prefix, sceneName, sceneName);
            return assetPath;
        }

        /// <summary>
        /// 通过场景名称获取场景文件完整路径
        /// </summary>
        /// <param name="sceneName"></param>
        /// <returns></returns>
        public static string GetFullPath(string sceneName)
        {
            string assetPath = GetAssetPath(sceneName);
            if (string.IsNullOrEmpty(assetPath)) return null;
            var cur = Directory.GetCurrentDirectory();
            string fullPath = string.Format("{0}/{1}", cur, assetPath);
            return fullPath;
        }

        /// <summary>
        /// 通过场景名称打开场景
        /// </summary>
        /// <param name="sceneName">场景名称</param>
        /// <param name="showDialog">true:显示对话框</param>
        public static void OpenByName(string sceneName, bool showDialog = true)
        {
            string scenePath = GetAssetPath(sceneName);
            Open(scenePath, showDialog);
        }


        /// <summary>
        /// 打开场景
        /// </summary>
        /// <param name="scenePath">场景路径</param>
        /// <param name="showDialog">true:显示对话框</param>
        public static void Open(string scenePath, bool showDialog = true)
        {
            if (string.IsNullOrEmpty(scenePath))
            {
                UIEditTip.Error("场景路径为空"); return;
            }
            var cur = Directory.GetCurrentDirectory();
            string fullPath = string.Format("{0}/{1}", cur, scenePath);
            if (!File.Exists(fullPath))
            {
                UIEditTip.Error("场景路径:{0},不存在", fullPath); return;
            }
            if (showDialog)
            {
                EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo();
            }
            if (EditorApplication.isPlaying)
            {
                SceneManager.LoadScene(scenePath);
            }
            else
            {
                EditorSceneManager.OpenScene(scenePath);
            }
            UIEditTip.Log("打开场景:{0},成功", scenePath);
        }

        /// <summary>
        /// 创建场景
        /// </summary>
        /// <param name="name">场景名</param>
        /// <param name="focus">true:创建完后定位</param>
        public static void Create(string name, bool focus = true)
        {
            if (string.IsNullOrEmpty(name)) return;
            string sceneAssetPath = GetAssetPath(name);
            string sceneFullPath = GetFullPath(name);
            if (File.Exists(sceneFullPath)) return;
            FileTool.CheckDir(sceneFullPath);
            if (!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo()) return;
            Scene scene = EditorSceneManager.NewScene(NewSceneSetup.DefaultGameObjects);
            EditorSceneManager.SaveScene(scene, sceneAssetPath);
            if (focus) EditUtil.Ping(sceneAssetPath);
            AssetDatabase.Refresh();
        }

        /// <summary>
        /// 定位场景
        /// </summary>
        /// <param name="sceneName"></param>
        public static void Ping(string sceneName)
        {
            if (string.IsNullOrEmpty(sceneName)) return;
            string sceneAssetPath = GetAssetPath(sceneName);
            string sceneFullPath = GetFullPath(sceneName);
            if (File.Exists(sceneFullPath))
            {
                EditUtil.Ping(sceneAssetPath);
            }
            else
            {
                UIEditTip.Error("场景不存在:{0}", sceneAssetPath);
            }
        }



        /// <summary>
        /// 保存当前场景并打开入口
        /// </summary>
        [MenuItem(menu + "保存当前场景并进入游戏 %&#s", false, Pri + 1)]
        [MenuItem(AMenu + "保存当前场景并进入游戏", false, Pri + 1)]
        public static void SaveCurAndOpenMain()
        {
            if (EditorApplication.isPlaying)
            {
                EditorApplication.isPlaying = false;
                UIEditTip.Warning("重新使用快捷键"); return;
            }
            string mainScenePath = Data.MainScenePath;
            if (string.IsNullOrEmpty(mainScenePath))
            {
                UIEditTip.Error("没有设置主场景路径"); SceneWin.Open();
            }
            else
            {
                EditorSceneManager.SaveOpenScenes();
                Open(mainScenePath, false);
                EditorApplication.isPlaying = true;
            }
        }

        /// <summary>
        /// 不保存当前场景并打开入口
        /// </summary>
        [MenuItem(menu + "不保存当前场景并进入游戏 %&#d", false, Pri + 2)]
        [MenuItem(AMenu + "不保存当前场景并进入游戏", false, Pri + 2)]
        public static void NotSaveCurAndOpenMain()
        {
            if (EditorApplication.isPlaying)
            {
                EditorApplication.isPlaying = false;
                UIEditTip.Warning("重新使用快捷键"); return;
            }
            string mainScenePath = Data.MainScenePath;
            if (string.IsNullOrEmpty(mainScenePath)) { SceneWin.Open(); return; }
            Open(mainScenePath, false);
            EditorApplication.isPlaying = true;
        }


        [MenuItem(menu + "创建默认场景 %&#c", false, Pri + 3)]
        [MenuItem(AMenu + "创建默认场景", false, Pri + 3)]
        public static void CreateDefault()
        {
            if (!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo()) return;
            EditorSceneManager.NewScene(NewSceneSetup.DefaultGameObjects, NewSceneMode.Single);
            var cam = Camera.main;
            if (cam == null) return;
            cam.allowHDR = false;
            cam.allowMSAA = false;
            cam.useOcclusionCulling = false;
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = Color.gray;
        }

        #endregion
    }
}