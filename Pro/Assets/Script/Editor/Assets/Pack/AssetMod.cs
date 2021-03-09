/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/7/30 16:24:05
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Xml.Serialization;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    using AVR = AssetValidResult;
    /// <summary>
    /// 资源模块
    /// </summary>
    [Serializable]
    public class AssetMod : IDraw
    {
        #region 字段
        private AssetSet sets = null;

        /// <summary>
        /// 等级
        /// </summary>
        public int lv = 0;

        public eAssetPage page = new eAssetPage();

        /// <summary>
        /// 模块名
        /// </summary>
        public string name = "unknown";

        /// <summary>
        /// true:折叠
        /// </summary>
        [XmlIgnore]
        public bool foldout = false;


        /// <summary>
        /// 监听最小等级
        /// </summary>
        public int lsnrMinLv = 0;

        /// <summary>
        /// 监听最大等级
        /// </summary>
        public int lsnrMaxLv = 0;

        /// <summary>
        /// 批量加载文件
        /// </summary>
        public string cfgPath = "";

        /// <summary>
        /// 批量搜索目录
        /// </summary>
        public string searchDir = "./Assets/Pkg";


        public static IList moveSrc = null;

        public static int moveSrcIdx = -1;

        public static IList moveTo = null;

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private bool AddSets(string path)
        {
            if (sets == null) return false;
            return sets.Add(path);
        }

        private void Add(List<string> paths)
        {
            //EditTool.RegisterUndo("AssetModAdd", obj);
            if (paths == null) return;
            var infos = page.lst;
            int length = paths.Count;
            var last = ((infos.Count > 0) ? infos[infos.Count - 1] : null);
            for (int i = 0; i < length; i++)
            {
                var path = paths[i];
                var sfx = Path.GetExtension(path);
                if (!AssetPackUtil.IsValidSfx(sfx)) continue;
                if (!AddSets(path)) continue;
                var info = new eAssetInfo();
                info.path = path;
                info.Lv = lv;
                info.CopyFrom(last);
                infos.Add(info);
            }
        }

        private bool CheckPath(string path)
        {
            if (string.IsNullOrEmpty(path)) return false;
            string name = Path.GetFileName(path);
            var infos = page.lst;
            int length = infos.Count;
            for (int i = 0; i < length; i++)
            {
                var info = infos[i];
                var iName = Path.GetFileName(info.path);
                if (iName.Equals(name))
                {
                    var err = string.Format("{0} {1} 相同", path, info.path);
                    iTrace.Log("Loong", err);
                    return false;
                }
            }
            return true;
        }

        private void AddByFile()
        {
            if (!Directory.Exists(searchDir))
            {
                UIEditTip.Error("{0} 不存在", searchDir);
            }
            else if (!File.Exists(cfgPath))
            {
                UIEditTip.Error("{0} 不存在", cfgPath);
            }
            else
            {
                var lst = AssetUtil.Search(searchDir, cfgPath);
                if (lst == null || lst.Count < 1)
                {
                    UIEditTip.Log("无任何文件需要添加");
                }
                else
                {
                    Add(lst);
                }
            }
        }

        /// <summary>
        /// 通过监听等级添加
        /// </summary>
        private void AddByLsnrFile()
        {
            if ((lsnrMaxLv < 0) || (lsnrMinLv >= lsnrMaxLv))
            {
                UIEditTip.Error("未正确设置等级范围");
            }
            else if (!File.Exists(AssetLoadLsnr.path))
            {
                UIEditTip.Error("无资源加载监听信息");
            }
            else
            {
                var als = Loong.Game.XmlTool.Deserializer<List<AssetLoadInfo>>(AssetLoadLsnr.path);
                if (als.Count < 1)
                {
                    UIEditTip.Error("无资源加载监听信息");
                }
                else
                {
                    int length = als.Count;
                    var infos = page.lst;
                    for (int i = 0; i < length; i++)
                    {
                        var ali = als[i];
                        var allv = ali.Lv;
                        if (allv < lsnrMinLv) continue;
                        if (allv > lsnrMaxLv) continue;
                        var path = ali.path;
                        if (!AddSets(path)) continue;

                        var info = new eAssetInfo();
                        info.path = path;
                        info.Lv = allv;
                        infos.Add(info);
                    }
                    EventTool.Use();
                    UIEditTip.Warning("添加完成,{0},{1}", page.lst.Count, infos.Count);
                }
            }
        }

        private void SetLv(Object obj)
        {
            EditUtil.RegisterUndo("AssetModSetLv", obj);
            int length = page.lst.Count;
            for (int i = 0; i < length; i++)
            {
                var info = page.lst[i];
                info.Lv = lv;
            }
            UIEditTip.Log("设置完成");
        }


        private object GetMoveMod(Object obj)
        {
            if (moveSrc == null) return null;
            var idx = moveSrcIdx;
            if (idx < 0 || idx >= moveSrc.Count) return null;
            var mod = moveSrc[idx];
            EditUtil.RegisterUndo("Move", obj);
            moveSrc.RemoveAt(idx);
            return mod;
        }

        private void ReadyMove(IList lst, int idx)
        {
            if (!EditorUtility.DisplayDialog("", "移动此模块?", "确定", "取消")) return;
            moveSrc = lst;
            moveSrcIdx = idx;
        }

        private void MoveDown(Object obj, IList lst, int idx)
        {
            if (!EditorUtility.DisplayDialog("", "移动到此模块以下?", "确定", "取消")) return;
            Move(obj, lst, idx + 1);

        }

        private void MoveUp(Object obj, IList lst, int idx)
        {
            if (!EditorUtility.DisplayDialog("", "移动到此模块之前?", "确定", "取消")) return;
            Move(obj, lst, idx - 1);
        }

        private void Move(Object obj, IList lst, int idx)
        {
            var mod = GetMoveMod(obj);
            if (mod == null) return;
            if (idx < 0)
            {
                lst.Insert(0, mod);
            }
            else
            {
                var last = lst.Count - 1;
                if (idx < last)
                {
                    lst.Insert(idx, mod);
                }
                else
                {
                    lst.Add(mod);
                }
            }
            MoveClear();
        }

        private void MoveClear()
        {
            moveSrc = null;
            moveTo = null;
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void Draw(Object obj, IList lst, int idx)
        {
            foldout = EditorGUILayout.Foldout(foldout, name);
            if (!foldout) return;
            EditorGUILayout.BeginHorizontal(StyleTool.Group);
            UIEditLayout.TextField("模块名:", ref name, obj);
            UIEditLayout.IntField("等级:", ref lv, obj);
            if (GUILayout.Button("一键设置")) SetLv(obj);
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal(StyleTool.Group);
            UIEditLayout.SetFolder("搜索目录:", ref searchDir, obj, true);
            UIEditLayout.SetPath("配置文件:", ref cfgPath, obj, "*.*");
            if (GUILayout.Button("添加", UIOptUtil.btn))
            {
                DialogUtil.Show("", "通过配置文件添加", AddByFile);
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal(EditorStyles.toolbar);
            EditorGUILayout.LabelField("通过等级监听文件添加");
            UIEditLayout.IntField("最小监听等级:", ref lsnrMinLv, obj);
            UIEditLayout.IntField("最大监听等级:", ref lsnrMaxLv, obj);
            if (GUILayout.Button("添加", EditorStyles.toolbarButton, UIOptUtil.btn))
            {
                DialogUtil.Show("", "确定添加", AddByLsnrFile);
            }

            EditorGUILayout.Space();
            if (moveSrc == null)
            {
                if (GUILayout.Button("", StyleTool.MultiTog, UIOptUtil.plus))
                {
                    ReadyMove(lst, idx);
                }
            }
            else
            {
                if (GUILayout.Button("", StyleTool.Cancel, UIOptUtil.plus))
                {
                    DialogUtil.Show("", "取消移动?", MoveClear);
                }
                else if (GUILayout.Button("", StyleTool.GradDown, UIOptUtil.plus))
                {
                    MoveDown(obj, lst, idx);
                }
                else if (GUILayout.Button("", StyleTool.GradUp, UIOptUtil.plus))
                {
                    MoveUp(obj, lst, idx);
                }
            }

            EditorGUILayout.EndHorizontal();

            page.OnGUI(obj);
            DragDropUtil.Files(Add);
        }

        public void Sort()
        {
            page.lst.Sort();
        }

        /// <summary>
        /// 校验
        /// </summary>
        /// <returns></returns>
        public bool Valid()
        {
            var infos = page.lst;
            int length = infos.Count;
            float len = length;
            int idx = 0;
            for (int i = length - 1; i > -1; --i)
            {
                ++idx;
                var info = infos[i];
                ProgressBarUtil.Show("校验中···", info.path, idx / len);
                var res = info.Valid();
                if (res == AVR.Suc) continue;
                if (res == AVR.NotExist)
                {
                    ListTool.Remove<eAssetInfo>(infos, i);
                    var err = string.Format("{0} 不存在,已从列移除", info.path);
                    iTrace.Error("Loong", err);
                }
            }
            ProgressBarUtil.Clear();
            return true;
        }


        public void Set(AssetSet set)
        {
            sets = set;
            if (set == null) return;
            var lst = page.lst;
            int length = lst.Count;
            for (int i = length - 1; i > -1; i--)
            {
                var info = lst[i];
                if (!set.Add(info.path))
                {
                    ListTool.Remove<eAssetInfo>(lst, i);
                    iTrace.Error("Loong", "重复添加:" + info.path);
                }
            }
        }
    }
    #endregion
}