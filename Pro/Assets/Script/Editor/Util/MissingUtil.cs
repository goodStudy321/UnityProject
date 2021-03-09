/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2015/7/2 20:25:33
 ============================================================================*/

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Reflection;
using System.Collections;
using System.Collections.Generic;
using UnityEditor.SceneManagement;
using UnityEngine.SceneManagement;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// 丢失脚本工具
    /// </summary>
    public static class MissingUtil
    {
        #region 字段
        /// <summary>
        /// 优先级
        /// </summary>
        public const int Pri = ScriptUtil.Pri + 20;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = ScriptUtil.Menu + "丢失工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = ScriptUtil.AMenu + "丢失工具/";
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private static bool ShowTip()
        {
            string tip = "因为一些不可描述的原因,删除Missing脚本后,需要重新打开工程";
            return EditorUtility.DisplayDialog("", tip, "继续", "否");
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 获取丢失组件
        /// </summary>
        /// <param name="target"></param>
        public static List<Object> Get(GameObject target)
        {
            if (target == null) return null;
            var trans = target.GetComponentsInChildren<Transform>(true);
            float tranLen = trans.Length;
            List<Object> objs = null;
            for (int i = 0; i < tranLen; i++)
            {
                var go = trans[i].gameObject;
                var coms = go.GetComponents<Component>();
                int comLen = coms.Length;
                for (int j = 0; j < comLen; j++)
                {
                    var com = coms[j];
                    if (com != null) continue;
                    if (objs == null) objs = new List<Object>();
                    if (objs.Contains(go)) continue;
                    objs.Add(go);
                }
            }
            return objs;
        }

        /// <summary>
        /// 获取丢失组件
        /// </summary>
        /// <param name="gos"></param>
        /// <returns></returns>
        public static void Open(GameObject[] gos)
        {
            if (gos == null) return;
            int length = gos.Length;
            List<Object> objs = null;
            for (int i = 0; i < length; i++)
            {
                var go = gos[i];
                var subs = Get(go);
                if (subs == null) continue;
                if (objs == null) objs = new List<Object>();
                objs.AddRange(subs);
            }
            if (objs == null)
            {

                UIEditTip.Log("无丢失组件");
            }
            else
            {
                ObjsWin.Open(objs);
                UIEditTip.Log("已打开丢失对象定位窗口");
            }
        }


        /// <summary>
        /// 显示丢失组件
        /// </summary>
        /// <param name="target"></param>
        public static bool Show(GameObject target)
        {
            if (target == null) return false;
            var trans = target.GetComponentsInChildren<Transform>(true);
            float tranLen = trans.Length;
            bool hasMiss = false;
            for (int i = 0; i < tranLen; i++)
            {
                var go = trans[i].gameObject;
                var coms = go.GetComponents<Component>();
                int comLen = coms.Length;
                for (int j = 0; j < comLen; j++)
                {
                    var com = coms[j];
                    if (com != null) continue;
                    hasMiss = true;
                    string path = TransTool.GetPath(go.transform);
                    iTrace.Log("Loong", string.Format("{0} 的丢失组件已移除", path));
                }
            }
            return hasMiss;
        }

        public static void Show(GameObject[] gos)
        {
            if (gos == null) return;
            float length = gos.Length;
            bool hasMiss = false;
            var title = "查找Missing组件";
            for (int i = 0; i < length; i++)
            {
                var go = gos[i];
                ProgressBarUtil.Show(title, go.name, i / length);
                if (Show(go))
                {
                    hasMiss = true;
                }
            }
            ProgressBarUtil.Clear();
            if (hasMiss)
            {
                UIEditTip.Log("已显示在控制台");
            }
            else
            {
                UIEditTip.Log("没有丢失组件");
            }
        }

        /// <summary>
        /// 移除游戏对象丢失的组件
        /// </summary>
        /// <param name="target"></param>
        public static bool Remove(GameObject target)
        {
            if (target == null) return false;
            bool hasMiss = false;
            bool rHasMiss = false;
            var trans = target.GetComponentsInChildren<Transform>(true);
            float tranLen = trans.Length;
            for (int i = 0; i < tranLen; i++)
            {
                var go = trans[i].gameObject;
                var coms = go.GetComponents<Component>();
                int comLen = coms.Length;
                for (int j = 0; j < comLen; j++)
                {
                    var com = coms[j];
                    if (com != null) continue;
                    hasMiss = true;
                    rHasMiss = true;
                    break;
                }
                if (!hasMiss) continue;
                var so = new SerializedObject(go);
                so.Update();
                var prop = so.FindProperty("m_Component");
                int pIdx = 0;
                for (int j = 0; j < coms.Length; j++)
                {
                    var com = coms[j];
                    if (com != null) continue;
                    prop.DeleteArrayElementAtIndex(j - pIdx);
                    ++pIdx;
                }
                string path = TransTool.GetPath(go.transform);
                iTrace.Log("Loong", string.Format("{0} 的丢失组件已移除", path));
                EditorUtility.SetDirty(go);
                so.ApplyModifiedProperties();
                so.Dispose();
                hasMiss = false;
            }
            if (rHasMiss)
            {
                string path = AssetDatabase.GetAssetPath(target);
                if (string.IsNullOrEmpty(path))
                {
                    EditorSceneManager.MarkSceneDirty(EditorSceneManager.GetActiveScene());
                }
                EditorUtility.SetDirty(target);
                AssetDatabase.SaveAssets();
            }

            return rHasMiss;
        }

        public static void Remove(GameObject[] gos)
        {
            if (gos == null) return;
            int length = gos.Length;
            bool hasMiss = false;
            var title = "查找Missing组件";
            for (int i = 0; i < length; i++)
            {
                var go = gos[i];
                ProgressBarUtil.Show(title, go.name, i / length);

                if (Remove(go))
                {
                    hasMiss = true;
                }
            }
            ProgressBarUtil.Clear();
            if (hasMiss)
            {
                UIEditTip.Log("移除完毕");
            }
            else
            {
                UIEditTip.Warning("不存在丢失脚本");
            }
        }

        /// <summary>
        /// 移除选择游戏对象上的丢失组件
        /// </summary>
        [MenuItem(menu + "移除选择对象的丢失脚本", false, Pri + 2)]
        [MenuItem(AMenu + "移除选择对象的丢失脚本", false, Pri + 2)]
        public static void RemoveBySelect()
        {
            if (!ShowTip()) return;
            if (!SelectUtil.CheckGos()) return;
            var gos = Selection.gameObjects;
            Remove(gos);
        }

        /// <summary>
        /// 删除选择对象
        /// </summary>
        [MenuItem(menu + "移除当前场景中的丢失脚本", false, Pri + 3)]
        [MenuItem(AMenu + "移除当前场景中的丢失脚本", false, Pri + 3)]
        public static void RemoveInScene()
        {
            if (!ShowTip()) return;
            Scene scene = EditorSceneManager.GetActiveScene();
            var gos = scene.GetRootGameObjects();
            Remove(gos);
        }

        /// <summary>
        /// 移除选择游戏对象上的丢失组件
        /// </summary>
        [MenuItem(menu + "显示选择对象的丢失脚本", false, Pri + 4)]
        [MenuItem(AMenu + "显示选择对象的丢失脚本", false, Pri + 4)]
        public static void ShowBySelect()
        {
            if (!SelectUtil.CheckGos()) return;
            var gos = Selection.gameObjects;
            Show(gos);
        }

        /// <summary>
        /// 删除选择对象
        /// </summary>
        [MenuItem(menu + "显示当前场景中的丢失脚本", false, Pri + 5)]
        [MenuItem(AMenu + "显示当前场景中的丢失脚本", false, Pri + 5)]
        public static void ShowInScene()
        {
            Scene scene = EditorSceneManager.GetActiveScene();
            var gos = scene.GetRootGameObjects();
            Show(gos);
        }

        /// <summary>
        /// 移除选择游戏对象上的丢失组件
        /// </summary>
        [MenuItem(menu + "打开选择对象的丢失脚本定位窗口", false, Pri + 6)]
        [MenuItem(AMenu + "打开选择对象的丢失脚本定位窗口", false, Pri + 6)]
        public static void OpenBySelect()
        {
            if (!SelectUtil.CheckGos()) return;
            var gos = Selection.gameObjects;
            Open(gos);
        }

        /// <summary>
        /// 删除选择对象
        /// </summary>
        [MenuItem(menu + "打开当前场景中的丢失脚本定位窗口", false, Pri + 7)]
        [MenuItem(AMenu + "打开当前场景中的丢失脚本定位窗口", false, Pri + 7)]
        public static void OpenInScene()
        {
            Scene scene = EditorSceneManager.GetActiveScene();
            var gos = scene.GetRootGameObjects();
            Open(gos);
        }
        #endregion
    }
}