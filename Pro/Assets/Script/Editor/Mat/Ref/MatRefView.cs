/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/12/11 11:42:18
 ============================================================================*/

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// MatRefView
    /// </summary>
    public class MatRefView : AssetRefViewBase<Material>
    {
        #region 字段
        private HashSet<string> nameSet = new HashSet<string>();

        public List<string> matNames = new List<string>();
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
        protected override void SetObjs()
        {
            nameSet.Clear();
            int length = matNames.Count;
            for (int i = 0; i < length; i++)
            {
                nameSet.Add(matNames[i].ToLower());
            }
            objs = MatUtil.SearchSelect(nameSet);
        }
        #endregion

        protected override void DrawObj(Object obj)
        {
            UIDrawTool.StringLst(obj, matNames, "matRefNames", "搜索名称列表");
        }

        #region 公开方法

        #endregion
    }
}