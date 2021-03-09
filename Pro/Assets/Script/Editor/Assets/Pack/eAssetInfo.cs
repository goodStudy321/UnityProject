/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/7/30 15:15:33
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
    /// <summary>
    /// 编辑器资源信息
    /// </summary>
    [Serializable]
    public class eAssetInfo : IDraw, IComparable<eAssetInfo>, IComparer<eAssetInfo>
    {
        #region 字段
        [SerializeField]
        [HideInInspector]
        private int lv = 0;

        [SerializeField]
        [HideInInspector]
        private int sort = 0;

        [SerializeField]
        [HideInInspector]
        private string _path = "";

        #endregion

        #region 属性
        /// <summary>
        /// 资源相对路径
        /// </summary>
        [XmlAttribute]
        public string path
        {
            get { return _path; }
            set { _path = value; }
        }

        /// <summary>
        /// 等级
        /// </summary>
        [XmlAttribute]
        public int Lv
        {
            get { return lv; }
            set { lv = value; }
        }

        /// <summary>
        /// 排序
        /// </summary>
        [XmlAttribute]
        public int Sort
        {
            get { return sort; }
            set { sort = value; }
        }


        /// <summary>
        /// 校验结果
        /// </summary>
        [XmlIgnore]
        public bool valid = true;

        /// <summary>
        /// 校验信息
        /// </summary>
        [XmlIgnore]
        public string validMsg = "";

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private bool CheckSfx(string sfx)
        {
            if (sfx == Suffix.Js) return false;
            if (sfx == Suffix.CS) return false;
            if (sfx == Suffix.Lua) return false;
            if (sfx == Suffix.Meta) return false;
            return true;
        }

        private void SetPathDialog(Object obj)
        {
            var cur = Directory.GetCurrentDirectory();
            cur += "/Assets";
            string temp = EditorUtility.OpenFilePanel("设置资源路径", cur, "*.*");
            if (string.IsNullOrEmpty(temp)) return;

            var rDir = FileUtil.GetProjectRelativePath(temp);
            if (string.IsNullOrEmpty(rDir))
            {
                valid = false;
            }
            if (!rDir.StartsWith("Assets"))
            {
                valid = false;
            }
            if (valid)
            {
                UIEditTip.Log("成功设置:{1}", temp);
                EditUtil.RegisterUndo("SetFilePath", obj);
                _path = temp;
            }
            else
            {
                UIEditTip.Error("非法路径:{0}", temp);
            }
        }
        #endregion

        #region 保护方法
        public void SetPath()
        {
            var sfx = Path.GetExtension(_path);
            if (CheckSfx(sfx))
            {
                _path = FileUtil.GetProjectRelativePath(_path);
            }
            else
            {
                UIEditTip.Error("无效资源:{0}", _path);
                _path = "";
            }
        }
        #endregion

        #region 公开方法
        public void Draw(Object obj, IList lst, int idx)
        {
            EditorGUILayout.BeginHorizontal();
            UIEditLayout.TextField("", ref _path, obj, SetPath);
            UIEditLayout.UIntField("", ref lv, obj, null, UIOptUtil.btn);
            UIEditLayout.IntField("", ref sort, obj, null, UIOptUtil.btn);
            if (sort < 0)
            {
                GUILayout.Box("", StyleTool.Label6, UIOptUtil.plus);
            }
            else
            {
                GUILayout.Box("", StyleTool.Label3, UIOptUtil.plus);
            }
            if (GUILayout.Button("设置", UIOptUtil.btn)) SetPathDialog(obj);
            if (GUILayout.Button("定位", UIOptUtil.btn)) EditUtil.Ping(path);
            EditorGUILayout.EndHorizontal();
            //UIEditLayout.TextArea("描述:", ref des, obj);
            if (valid) return;
            if (string.IsNullOrEmpty(validMsg))
            {
                UIEditLayout.HelpError("请确定路径是否存在并设置包名");
            }
            else
            {
                UIEditLayout.HelpError(validMsg);
            }
        }

        public int CompareTo(eAssetInfo rhs)
        {
            if (lv < rhs.lv) return -1;
            if (lv > rhs.lv) return 1;
            if (sort < rhs.sort) return -1;
            if (sort > rhs.sort) return 1;
            if (string.IsNullOrEmpty(_path)) return -1;
            if (string.IsNullOrEmpty(rhs._path)) return -1;
            return _path.CompareTo(rhs._path);
        }

        public int Compare(eAssetInfo lhs, eAssetInfo rhs)
        {
            return lhs.CompareTo(rhs);
        }

        public void CopyFrom(eAssetInfo other)
        {
            if (other == null) return;
            lv = other.lv;
            sort = other.sort;
        }

        /// <summary>
        /// 校验
        /// </summary>
        /// <returns></returns>
        public AssetValidResult Valid()
        {
            AssetValidResult res = AssetValidResult.Suc;
            validMsg = "";
            var cur = Directory.GetCurrentDirectory();
            var fullPath = Path.Combine(cur, _path);
            if (File.Exists(fullPath))
            {
                var ai = AssetImporter.GetAtPath(_path);
                if (string.IsNullOrEmpty(ai.assetBundleName))
                {
                    validMsg = string.Format("路径:{0} 未设置包名", _path);
                    res = AssetValidResult.NoAB;
                }
            }
            else
            {
                validMsg = string.Format("路径:{0}不存在", _path);
                res = AssetValidResult.NotExist;
            }
            if (res != AssetValidResult.Suc)
            {
                //iTrace.LogError("Loong", validMsg);
                iTrace.Error("Loong", validMsg);
            }
            return res;
        }
        #endregion
    }
}