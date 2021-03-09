/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/2/5 10:05:42
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
    /// 变换组件属性视图
    /// </summary>
    public class TranPropView : EditViewBase
    {
        #region 字段

        [SerializeField]
        [HideInInspector]
        private string split = ",";

        [SerializeField]
        [HideInInspector]
        private string prec = "f0";

        [SerializeField]
        [HideInInspector]
        private string pos = "";

        [SerializeField]
        [HideInInspector]
        private string localPos = "";


        /// <summary>
        /// 使用Y轴
        /// </summary>
        public bool useY = true;
        /// <summary>
        /// 使用Z轴
        /// </summary>
        public bool useZ = true;


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
        /// 小数点后位数/精度
        /// </summary>
        public string Prec
        {
            get { return prec; }
            set { prec = value; }
        }


        /// <summary>
        /// 分隔符
        /// </summary>
        public string Split
        {
            get { return split; }
            set { split = value; }
        }
        /// <summary>
        /// 世界位置坐标
        /// </summary>
        public string Pos
        {
            get { return pos; }
            set { pos = value; }
        }

        /// <summary>
        /// 局部世界坐标
        /// </summary>
        public string LocalPos
        {
            get { return localPos; }
            set { localPos = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        /// <summary>
        /// 获取变换组件
        /// </summary>
        /// <returns></returns>
        private Transform GetTran()
        {
            var tran = Selection.activeTransform;
            if (tran == null)
            {
                var trans = Selection.transforms;
                if (trans == null || trans.Length < 1)
                {
                    UIEditTip.Error("没有选择变换组件");
                    return null;
                }
                tran = trans[0];
            }
            return tran;
        }


        private void SetProp()
        {
            var tran = GetTran();
            if (tran == null) return;
            char ch = ',';
            if (char.TryParse(split, out ch))
            {
                pos = EditVecUtil.Parse(tran.position, ch, prec, useY, useZ);
                localPos = EditVecUtil.Parse(tran.localPosition, ch, prec, useY, useZ);
            }
            else
            {
                UIEditTip.Error("非法分割字符");
            }
            tranPath = TransTool.GetPath(tran, tranPathOffset);
        }

        #endregion

        #region 保护方法
        protected override void OnGUICustom()
        {
            EditorGUILayout.Space();
            EditorGUILayout.BeginVertical(StyleTool.Group);


            UIEditLayout.TextField("精度:", ref prec, this);
            UIEditLayout.HelpInfo("f2:保留2位,f3:保留3位,以此类推");
            UIEditLayout.TextField("分隔符:", ref split, this);
            UIEditLayout.Toggle("包含Y轴坐标:", ref useY, this);
            UIEditLayout.Toggle("包含Z轴坐标:", ref useZ, this);
            EditorGUILayout.Space();
            UIEditLayout.IntField("路径起始偏移:", ref tranPathOffset, this);

            if (GUILayout.Button("转换"))
            {
                SetProp();
            }


            EditorGUILayout.EndVertical();
            EditorGUILayout.Space();

            EditorGUILayout.BeginVertical(StyleTool.Group);

            EditorGUILayout.TextField("世界位置坐标:", pos);
            EditorGUILayout.TextField("局部位置坐标:", localPos);
            EditorGUILayout.Space();
            EditorGUILayout.TextField("变换组件路径:", tranPath);
            EditorGUILayout.EndVertical();
        }
        #endregion

        #region 公开方法

        #endregion
    }
}