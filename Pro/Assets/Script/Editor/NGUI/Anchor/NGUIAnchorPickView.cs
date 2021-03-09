/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/6/20 1:43:18
 ============================================================================*/

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// NGUIAnchorPickView
    /// </summary>
    public class NGUIAnchorPickView : EditViewBase
    {
        #region 字段
        [SerializeField]
        [HideInInspector]
        private string split = ",";

        private string absoluteStr = "";

        private string relativeStr = "";


        /// <summary>
        /// 变换组件路径
        /// </summary>
        public string tranPath = "";

        /// <summary>
        /// 变换组件路径起始偏移
        /// </summary>
        public int tranPathOffset = 2;

        #endregion

        #region 属性
        /// <summary>
        /// 分隔符
        /// </summary>
        public string Split
        {
            get { return split; }
            set { split = value; }
        }
        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public NGUIAnchorPickView()
        {

        }
        #endregion

        #region 私有方法

        /// <summary>
        /// 获取坐标位置
        /// </summary>
        /// <returns></returns>
        private UIRect GetRect()
        {
            var tran = Selection.activeTransform;
            if (tran == null)
            {
                var trans = Selection.transforms;
                if (trans == null || trans.Length < 1)
                {
                    UIEditTip.Error("未选择变换组件");
                    return null;
                }
                tran = trans[0];
            }

            UIRect rect = tran.GetComponent<UIRect>();
            if (rect == null)
            {
                UIEditTip.Error("无 UIRect组件");
            }

            return rect;
        }

        /// <summary>
        /// 转换坐标
        /// </summary>
        private void SetRect()
        {
            var rect = GetRect();
            if (rect == null) return;
            float leftO = rect.leftAnchor.absolute;
            float rightO = rect.rightAnchor.absolute;
            float bottomO = rect.bottomAnchor.absolute;
            float topO = rect.topAnchor.absolute;
            absoluteStr = string.Format("{0},{1},{2},{3}", leftO, rightO, bottomO, topO);

            float leftR = rect.leftAnchor.relative;
            float rightR = rect.rightAnchor.relative;
            float bottomR = rect.bottomAnchor.relative;
            float topR = rect.topAnchor.relative;
            relativeStr = string.Format("{0},{1},{2},{3}", leftR, rightR, bottomR, topR);
            tranPath = TransTool.GetPath(rect.transform, tranPathOffset);
        }

        private int ParseAnchorAbsolute(string str)
        {
            int val = 0;
            if (!int.TryParse(str, out val))
            {
                UIEditTip.Error("无法将:{0}转换为数字", str);
            }
            return val;
        }

        private float ParseAnchorRelative(string str)
        {
            float val = 0;
            if (!float.TryParse(str, out val))
            {
                UIEditTip.Error("无法将:{0}转换为浮点数", str);
            }
            return val;
        }

        private string[] GetAnchorArr(string str, char c)
        {
            string[] arr = absoluteStr.Split(c);
            if (arr.Length != 4)
            {
                UIEditTip.Error("锚点值数量必须为4", absoluteStr);
                return null;
            }
            return arr;
        }

        /// <summary>
        /// 逆转坐标
        /// </summary>
        private void ResetRect()
        {
            var rect = GetRect();
            if (rect == null) return;
            char c = ',';
            if (!char.TryParse(split, out c))
            {
                UIEditTip.Error("无法将:{0}转换为字符", absoluteStr);
                return;
            }
            string[] arrA = GetAnchorArr(absoluteStr, c);
            if (arrA != null)
            {
                int la = ParseAnchorAbsolute(arrA[0]);
                int ra = ParseAnchorAbsolute(arrA[1]);
                int ba = ParseAnchorAbsolute(arrA[2]);
                int ta = ParseAnchorAbsolute(arrA[3]);

                rect.leftAnchor.absolute = la;
                rect.rightAnchor.absolute = ra;
                rect.bottomAnchor.absolute = ba;
                rect.topAnchor.absolute = ta;
            }

            /*string[] arrR = GetAnchorArr(relativeStr, c);
            if (arrR != null)
            {
                float lr = ParseAnchorRelative(arrR[0]);
                float rr = ParseAnchorRelative(arrR[1]);
                float br = ParseAnchorRelative(arrR[2]);
                float tr = ParseAnchorRelative(arrR[3]);

                rect.leftAnchor.relative = lr;
                rect.rightAnchor.relative = rr;
                rect.bottomAnchor.relative = br;
                rect.topAnchor.relative = tr;
            }*/
        }
        #endregion

        #region 保护方法
        protected override void OnGUICustom()
        {
            EditorGUILayout.BeginVertical(StyleTool.Box);
            UIEditLayout.IntField("路径起始偏移:", ref tranPathOffset, this);
            if (GUILayout.Button("转换"))
            {
                SetRect();
            }
            EditorGUILayout.Space();
            relativeStr = EditorGUILayout.TextField("锚点相对值:", relativeStr);
            absoluteStr = EditorGUILayout.TextField("锚点绝对值:", absoluteStr);
            EditorGUILayout.Space();
            EditorGUILayout.TextField("变换组件路径:", tranPath);
            if (GUILayout.Button("逆转"))
            {
                ResetRect();
            }
            EditorGUILayout.EndVertical();
        }
        #endregion

        #region 公开方法

        #endregion
    }
}