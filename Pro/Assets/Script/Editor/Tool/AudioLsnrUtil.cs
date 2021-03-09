/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2014/4/20 00:00:00
 ============================================================================*/

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UnityEditor.SceneManagement;
using UnityEngine.SceneManagement;

using Object = UnityEngine.Object;



namespace Loong.Edit
{
    /// <summary>
    /// 编辑器音效监听组件工具
    /// </summary>
    public static class AudioLnsrUtil
    {
        #region 字段
        /// <summary>
        /// 优先级
        /// </summary>
        public const int Pri = MenuTool.NormalPri + 35;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Loong + "音效监听组件工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "音效监听组件工具/";
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
        /// 显示游戏对象上的音效监听组件
        /// </summary>
        /// <param name="go"></param>
        public static bool ShowLsnrs(GameObject go)
        {
            if (go == null) return false;
            var arr = go.GetComponentsInChildren<AudioListener>(true);
            if (arr == null || arr.Length == 0) return false;
            float length = arr.Length;
            for (int i = 0; i < length; i++)
            {
                var it = arr[i];
                if (it == null) continue;
                var tran = it.transform;
                string path = TransTool.GetPath(tran);
                iTrace.Log("Loong", string.Format("[{0}] 上有音效监听组件", path));
            }
            return true;
        }

        /// <summary>
        /// 显示场景中的音效监听组件
        /// </summary>
        /// <param name="scene"></param>
        public static void ShowLsnrs(Scene scene)
        {
            var gos = scene.GetRootGameObjects();
            int length = gos.Length;
            for (int i = 0; i < length; i++)
            {
                var go = gos[i];
                ShowLsnrs(go);
            }
        }

        public static void ShowDontDestroyOnLoadLsnrs()
        {
            GameObject go = new GameObject();
            Object.DontDestroyOnLoad(go);
            ShowLsnrs(go.scene);
            Object.DestroyImmediate(go);
        }

        public static List<Object> GetLsnrs(Scene scene)
        {
            var gos = scene.GetRootGameObjects();
            List<Object> lst = null;
            int goLen = gos.Length;
            for (int i = 0; i < goLen; i++)
            {
                var go = gos[i];
                var lsnrs = go.GetComponentsInChildren<AudioListener>();
                if (lsnrs == null || lsnrs.Length == 0) continue;
                if (lst == null) lst = new List<Object>();
                int lsnrLen = lsnrs.Length;
                for (int j = 0; j < lsnrLen; j++)
                {
                    var it = lsnrs[j];
                    lst.Add(it);
                }
            }
            return lst;
        }

        public static List<Object> GetDontDestroyOnLoadLsnrs()
        {
            GameObject go = new GameObject();
            Object.DontDestroyOnLoad(go);
            var objs = GetLsnrs(go.scene);
            Object.DestroyImmediate(go);
            return objs;
        }


        [MenuItem(menu + "显示场景中音效监听组件路径", false, Pri + 1)]
        [MenuItem(AMenu + "显示场景中音效监听组件路径", false, Pri + 1)]
        public static void ShowLsnrsInScene()
        {
            if (EditorApplication.isPlaying)
            {
                ShowDontDestroyOnLoadLsnrs();
                int length = SceneManager.sceneCount;
                for (int i = 0; i < length; i++)
                {
                    Scene scene = SceneManager.GetSceneAt(i);
                    ShowLsnrs(scene);
                }
            }
            else
            {
                Scene scene = EditorSceneManager.GetActiveScene();
                ShowLsnrs(scene);
            }
        }


        [MenuItem(menu + "打开场景中的音效监听组件定位窗口", false, Pri + 2)]
        [MenuItem(AMenu + "打开场景中的音效监听组件定位窗口", false, Pri + 2)]
        public static void OpenLsnrsPingWin()
        {
            List<Object> objs = null;
            if (EditorApplication.isPlaying)
            {
                objs = GetDontDestroyOnLoadLsnrs();
                int length = SceneManager.sceneCount;
                for (int i = 0; i < length; i++)
                {
                    Scene scene = SceneManager.GetSceneAt(i);
                    var other = GetLsnrs(scene);
                    if (other == null) continue;
                    objs.AddRange(other);
                }
            }
            else
            {
                Scene scene = EditorSceneManager.GetActiveScene();
                objs = GetLsnrs(scene);
            }
            if (objs == null)
            {
                UIEditTip.Warning("没有发现音效监听组件");
            }
            else
            {
                ObjsWin.Open(objs);
            }
        }
        #endregion
    }
}