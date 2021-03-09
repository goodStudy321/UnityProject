//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/27 15:04:59
//=============================================================================

using System;
using Loong.Game;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit.Confuse
{
    /// <summary>
    /// ConfuseCodeBodyFty
    /// </summary>
    public static class ConfuseCodeBodyFty
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
        public static ICodeBody Create(ICodeFunc func)
        {
            if (func == null) return null;
            var returnType = func.ReturnType;
            var typeInfo = CSTypeMgr.Get(returnType);
            if (typeInfo == null)
            {
                iTrace.Error("Loong", "无类型:{0}", returnType);
                return null;

            }
            var type = typeInfo.Type;
            switch (type)
            {
                case CSType.Bool:
                    return new ConfuseCodeBodyBool();

                case CSType.String:
                    return new ConfuseCodeBodyStr();
                case CSType.Vector2:
                    return new ConfuseCodeBodyVector2();
                case CSType.Vector3:
                    return new ConfuseCodeBodyVector3();
                case CSType.Vector4:
                    return new ConfuseCodeBodyVector4();
                case CSType.Color:
                    return new ConfuseCodeBodyColor();
                default:
                    return new ConfuseCodeBodyNumber();
            }
        }
        #endregion
    }
}