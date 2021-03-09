/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2016/8/10 19:49:39
 ============================================================================*/

using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// 版本号数据
    /// </summary>
    public class VerData : EditViewBase
    {
        #region 字段

        [HideInInspector]
        [SerializeField]
        private int major = 1;

        [HideInInspector]
        [SerializeField]
        private int minor = -1;

        [HideInInspector]
        [SerializeField]
        private int verCode = -1;
        #endregion

        #region 属性

        /// <summary>
        /// 主版本号
        /// </summary>
        public int Major
        {
            get { return major; }
            set
            {
                major = value;
                EditUtil.SetDirty(this);
            }
        }

        /// <summary>
        /// 次版本号
        /// </summary>
        public int Minor
        {
            get { return minor; }
            set
            {
                minor = value;
                EditUtil.SetDirty(this);
            }
        }

        /// <summary>
        /// 内部版本号
        /// </summary>
        public int VerCode
        {
            get { return verCode; }
            set
            {
                verCode = value;
                EditUtil.SetDirty(this);
            }
        }


        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void OnGUICustom()
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.UIntField("主版本号:", ref major, this);
            UIEditLayout.IntField("次版本号:", ref minor, this);
            UIEditLayout.UIntField("内部版本号:", ref verCode, this);
            EditorGUILayout.EndVertical();
        }
        #endregion

        #region 公开方法

        #endregion
    }
}