/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2015/7/15 22:20:31
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// NGUI工具
    /// </summary>
    public static class NGUIUtil
    {
        #region 字段
        public const string RootName = "UI Root";

        public const string UIDir = "Assets/Pkg/ui/UI";

        /// <summary>
        /// 优先级
        /// </summary>
        public const int Pri = MenuTool.NormalPri + 70;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Loong + "NGUI工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "NGUI工具/";
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private static Transform SetRoot()
        {
            return UITool.CreateRoot(1334, 750, 0);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        [MenuItem(menu + "创建根结点", false, Pri)]
        [MenuItem(AMenu + "创建根结点", false, Pri)]
        public static void CreateRoot()
        {
            SetRoot();
        }

        [MenuItem(menu + "创建根结点在新场景 %&r", false, Pri + 1)]
        [MenuItem(AMenu + "创建根结点在新场景", false, Pri + 1)]
        public static void CreateRootInNewDialog()
        {
            DialogUtil.Show("", "创建根结点在新场景?", CreateRootInNew);
        }


        public static void CreateRootInNew()
        {
            SceneMgr.CreateDefault();
            SetRoot();
        }


        /// <summary>
        /// 设置锚点为Start
        /// </summary>
        [MenuItem(menu + "设置锚点为Start", false, Pri + 3)]
        [MenuItem(AMenu + "设置锚点为Start", false, Pri + 3)]
        public static void SetAnchorStart()
        {
            SetAnchor(UIRect.AnchorUpdate.OnStart);
        }

        /// <summary>
        /// 删除无用组件/UIPlaySound
        /// </summary>
        [MenuItem(menu + "删除无用组件/UIPlaySound", false, Pri + 4)]
        [MenuItem(AMenu + "删除无用组件/UIPlaySound", false, Pri + 4)]
        public static void DeleteUnusedComponent()
        {
            EditComUtil.Delete<UIPlaySound>();
        }

        /// <summary>
        /// 删除无用组件/UIButton
        /// </summary>
        [MenuItem(menu + "删除无用组件/UIButton", false, Pri + 5)]
        [MenuItem(AMenu + "删除无用组件/UIButton", false, Pri + 5)]
        public static void DeleteUIButton()
        {
            EditComUtil.Delete<UIButton>();
        }

        /// <summary>
        /// 删除无用组件/UIEventListener
        /// </summary>
        [MenuItem(menu + "删除无用组件/UIEventListener", false, Pri + 6)]
        [MenuItem(AMenu + "删除无用组件/UIEventListener", false, Pri + 6)]
        public static void DeleteUIEventListener()
        {
            EditComUtil.Delete<UIEventListener>();
        }


        /// <summary>
        /// 设置选择的游戏对象的锚点
        /// </summary>
        /// <param name="anchor"></param>
        public static void SetAnchor(UIRect.AnchorUpdate anchor)
        {
            if (!SelectUtil.CheckGos()) return;
            var gos = Selection.gameObjects;
            int length = gos.Length;
            for (int i = 0; i < length; i++)
            {
                var go = gos[i];
                SetAnchor(go, anchor);
                EditorUtility.SetDirty(go);
            }

            ProgressBarUtil.Clear();
        }

        /// <summary>
        /// 设置游戏对象的锚点
        /// </summary>
        /// <param name="go"></param>
        /// <param name="anchor"></param>
        public static void SetAnchor(GameObject go, UIRect.AnchorUpdate anchor)
        {
            if (go == null) return;
            var widgets = go.GetComponentsInChildren<UIWidget>(true);
            if (widgets == null || widgets.Length < 1) return; ;
            float length = widgets.Length;
            var title = "设置锚点";
            for (int i = 0; i < length; i++)
            {
                var widget = widgets[i];
                widget.updateAnchors = anchor;
                ProgressBarUtil.Show(title, widget.name, i / length);
            }
        }

        [MenuItem(menu + "创建所有UI", false, Pri + 5)]
        [MenuItem(AMenu + "创建所有UI", false, Pri + 5)]
        public static void LoadAllUI()
        {
            var go = GameObject.Find(RootName);
            if (go != null)
            {
                var msg = string.Format("已经存在:{0} 若继续将删除此节点重新创建(建议在新场景或测试场景中进行此操作)", RootName);
                if (!EditorUtility.DisplayDialog("", msg, "继续", "取消")) return;
                GameObject.DestroyImmediate(go);
            }
            var tran = SetRoot();
            go = tran.gameObject;
            var curDir = Directory.GetCurrentDirectory();
            var fullDir = Path.Combine(curDir, UIDir);
            var curDirLen = curDir.Length + 1;
            if (Directory.Exists(fullDir))
            {
                var title = "创建UI中";
                var uis = Directory.GetFiles(fullDir, "*.prefab", SearchOption.AllDirectories);
                if (uis == null) return;
                float len = uis.Length;
                for (int i = 0; i < len; i++)
                {
                    var ui = uis[i];
                    var rPath = ui.Substring(curDirLen);
                    rPath = rPath.Replace("\\", "/");
                    ProgressBarUtil.Show(title, rPath, i / len);
                    var obj = AssetDatabase.LoadAssetAtPath<GameObject>(rPath);
                    var com = obj.GetComponent<UIPanel>();
                    if (com == null) continue;
                    var newui = PrefabUtility.InstantiatePrefab(obj) as GameObject;
                    TransTool.AddChild(tran, newui.transform);
                }
                ProgressBarUtil.Clear();
            }
            else
            {
                UIEditTip.Error("{0} 不存在,请检查UI是否在此目录", fullDir);
            }
        }

        [MenuItem(menu + "检查所有UI相机是否开启MSAA", false, Pri + 7)]
        [MenuItem(AMenu + "检查所有UI相机是否开启MSAA", false, Pri + 7)]
        public static void CheckMSAA()
        {
            var go = GameObject.Find(RootName);
            if (go == null) return;
            var cams = go.GetComponentsInChildren<Camera>(true);
            var list = new List<Object>();
            int length = cams.Length;
            for (int i = 0; i < length; i++)
            {
                var cam = cams[i];
                if (cam.allowMSAA)
                {
                    list.Add(cam.gameObject);
                }
            }
            PingObjWin.Open(list);
        }

        public static List<UILabelInfo> CheckTextLbl()
        {
            var go = GameObject.Find(RootName);
            if (go == null) return null;
            var lbls = go.GetComponentsInChildren<UILabel>(true);
            var list = new List<UILabelInfo>();
            int length = lbls.Length;
            for (int i = 0; i < length; i++)
            {
                var it = lbls[i];
                var text = it.text;
                if (!text.IsNum())
                {
                    var info = new UILabelInfo(it);
                    info.path = TransTool.GetPath(it.transform, 1);
                    list.Add(info);
                }
            }
            return list;
        }
        #endregion
    }
}