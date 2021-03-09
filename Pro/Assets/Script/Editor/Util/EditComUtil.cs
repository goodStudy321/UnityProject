/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/10/9 11:51:30
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
    /// 编辑器组件工具
    /// </summary>
    public static class EditComUtil
    {
        #region 字段

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
        /// 删除组件
        /// </summary>
        /// <typeparam name="T"></typeparam>
        public static void Delete<T>() where T : Component
        {
            if (!SelectUtil.CheckGos()) return;
            var gos = Selection.gameObjects;
            int length = gos.Length;
            for (int i = 0; i < length; i++)
            {
                var go = gos[i];
                Delete<T>(go);
                EditorUtility.SetDirty(go);
            }

            ProgressBarUtil.Clear();
            UIEditTip.Log("删除{0}完成", typeof(T).Name);
        }

        /// <summary>
        /// 删除组件
        /// </summary>
        /// <param name="go"></param>
        public static void Delete<T>(GameObject go) where T : Component
        {
            if (go == null) return;
            var coms = go.GetComponentsInChildren<T>(true);
            if (coms == null || coms.Length < 1) return; ;
            float length = coms.Length;
            var title = "删除组件";
            for (int i = 0; i < length; i++)
            {
                var com = coms[i];
                ProgressBarUtil.Show(title, com.name, i / length);
                GameObject.DestroyImmediate(com, true);
            }
        }

        #endregion
    }
}