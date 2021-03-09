/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/7/30 15:13:15
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// AssetPackView
    /// </summary>
    public class AssetPackView : EditViewBase
    {
        #region 字段
        /// <summary>
        /// 配置保存目录
        /// </summary>
        public string dir = "../AssetPack";

        /// <summary>
        /// 资源过滤集合
        /// </summary>
        public AssetSet set = new AssetSet();

        /// <summary>
        /// 分包资源
        /// </summary>
        public List<AssetPack> packs = new List<AssetPack>();
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private void Load()
        {
            var path = GetPath();
            if (File.Exists(path))
            {
                var msg = string.Format("加载之后,视图内编辑的信息将丢失,并使用配置:{0}的信息", path);
                if (!EditorUtility.DisplayDialog("", msg, "确定", "取消")) return;
                var pm = AssetPackUtil.Read(dir);
                if (pm.packs.Count < 1)
                {
                    UIEditTip.Error("配置中无任何内容");
                }
                else
                {
                    packs.Clear();
                    packs.AddRange(pm.packs);
                    EditorUtility.SetDirty(this);
                    UIEditTip.Log("读取成功");
                    Refresh();
                }

            }
            else
            {
                UIEditTip.Error("配置:{0} 不存在", path);
            }
        }

        private void Save()
        {
            var msg = "确定保存?";
            if (!EditorUtility.DisplayDialog("", msg, "是", "否")) return;
            if (string.IsNullOrEmpty(dir))
            {
                UIEditTip.Error("未设置保存目录");
            }
            else if (packs.Count < 1)
            {
                UIEditTip.Warning("无分包");
            }
            else if (!Valid())
            {
                UIEditTip.Error("校验失败");
            }
            else
            {
                var suc = AssetPackUtil.SaveAll(dir, packs);
                var tip = (suc ? "成功" : "失败");
                UIEditTip.Warning("保存{0}", tip);
                Refresh();
            }
        }


        private bool Valid()
        {
            bool valid = PackManifest.IsValid(packs);
            EditorUtility.SetDirty(this);
            UIEditTip.Mutex(valid, "校验");
            return valid;
        }

        private void ChkValid()
        {
            Valid();
        }

        override protected void Help()
        {
            var msg = "1,若视图上数据丢失,可通过加载保存的数据还原\n2,每一次编辑后需要导出并提交\n3,保存之前需进行校验\n4,校验将删除列表中路径不存在的并提示未设置包名的";
            EditorUtility.DisplayDialog("帮助", msg, "确定");
        }

        private bool Add()
        {
            if (EditorUtility.DisplayDialog("", "添加?", "确定", "取消"))
            {
                EditUtil.RegisterUndo("AddPack", this);
                var pack = new AssetPack();
                pack.idx = packs.Count;
                pack.Init();
                pack.Set(set);
                packs.Add(pack);
                return true;
            }
            return false;
        }

        private bool Remove(int idx)
        {
            if (EditorUtility.DisplayDialog("", "移除?", "确定", "取消"))
            {
                EditUtil.RegisterUndo("RmvPack", this);
                packs.RemoveAt(idx);
                return true;
            }
            return false;
        }

        private void DrawPacks()
        {
            EditorGUILayout.BeginHorizontal();
            GUILayout.FlexibleSpace();
            if (GUILayout.Button("", StyleTool.Plus, UIOptUtil.plusWd))
            {
                if (Add()) Event.current.Use();
            }
            EditorGUILayout.EndHorizontal();
            int length = packs.Count;
            for (int i = 0; i < length; i++)
            {
                if (GUILayout.Button("", StyleTool.Minus, UIOptUtil.plusWd))
                {
                    if (Remove(i))
                    {
                        Event.current.Use();
                        break;
                    }
                }
                packs[i].Draw(this, packs, i);
            }
        }


        #endregion

        #region 保护方法
        protected override void Title()
        {
            BegTitle();
            if (TitleBtn("加载")) Load();
            else if (TitleBtn("保存")) Save();
            else if (TitleBtn("校验")) Valid();
            else if (TitleBtn("刷新")) Refresh();
            else if (TitleBtn("帮助")) Help();
            EndTitle();
        }

        protected override void OnGUICustom()
        {
            UIEditLayout.SetFolder("配置保存目录:", ref dir, this);
            DrawPacks();
        }

        protected override void ContextClick()
        {
            GenericMenu menu = new GenericMenu();
            menu.AddItem("加载", false, Load);
            menu.AddSeparator("");
            menu.AddItem("保存", false, Save);
            menu.AddSeparator("");
            menu.AddItem("校验", false, ChkValid);
            menu.AddSeparator("");
            menu.AddItem("帮助", false, Help);
        }
        #endregion

        #region 公开方法
        public string GetPath()
        {
            string path = Path.Combine(dir, AssetPackUtil.packName);
            return path;
        }

        public override void Initialize()
        {
            base.Initialize();
            set.Clear();
            int length = packs.Count;
            for (int i = 0; i < length; i++)
            {
                var pack = packs[i];
                pack.idx = i;
                pack.Init();
                pack.Set(set);
            }
            EditorUtility.SetDirty(this);
        }

        public override void OnCompiled()
        {
            Refresh();
        }

        public override void Refresh()
        {
            set.Clear();
            int length = packs.Count;
            for (int i = 0; i < length; i++)
            {
                var pack = packs[i];
                pack.idx = i;
                pack.Set(set);
                pack.SetIdx();
            }
            Win.Repaint();
        }
        #endregion
    }
}