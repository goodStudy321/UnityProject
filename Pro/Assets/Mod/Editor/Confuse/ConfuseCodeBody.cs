//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/27 15:45:03
//=============================================================================

using System;
using System.Text;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit.Confuse
{
    using Random = UnityEngine.Random;
    /// <summary>
    /// ConfuseCodeBody
    /// </summary>
    public abstract class ConfuseCodeBody : ICodeBody
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public ConfuseCodeBody()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        /// <summary>
        /// 获取返回值名称
        /// </summary>
        /// <param name="func"></param>
        /// <returns></returns>
        protected virtual string GetReturnName(ICodeFunc func)
        {
            var name = func.Name;
            var idx = Random.Range(1, name.Length);
            name = name.Substring(0, idx);
            name = StrUtil.FirstLower(name);
            return name + "_res";
        }

        protected virtual CSTypeInfo GetMaxType(ICodeFunc func)
        {
            var args = func.Args;
            int length = args.Count;
            int max = (int)CSType.Double;
            int floatType = (int)CSType.Float;
            int min = (int)CSType.Bool;
            int cur = min;
            int type64 = (int)CSType.Int64;
            int type32 = (int)CSType.Int32;
            int type16 = (int)CSType.Int16;

            for (int i = 0; i < length; i++)
            {
                var arg = args[i];
                var argType = arg.Type;
                var typeInfo = CSTypeMgr.Get(argType);
                var csType = typeInfo.Type;
                var type = (int)csType;
                if (type == max)
                {
                    return typeInfo;
                }
                else if (type > max)
                {
                    if (csType != CSType.String)
                    {
                        cur = type = floatType;
                    }
                }
                else
                {
                    if (csType == CSType.UInt64)
                    {
                        type = type64;
                    }
                    else if (csType == CSType.UInt32)
                    {
                        type = type32;
                    }
                    else if (csType == CSType.UInt16 || csType == CSType.Char)
                    {
                        type = type16;
                    }
                    if (type > cur)
                    {
                        cur = type;
                    }
                }
            }
            var maxType = (CSType)cur;
            var typeKey = maxType.ToString();
            var info = CSTypeMgr.Get(typeKey);
            return info;
        }

        /// <summary>
        /// 获取返回值的初始化值
        /// </summary>
        /// <returns></returns>
        protected virtual string GetReturnInitVal(ICodeFunc func)
        {
            var returnType = func.ReturnType;
            return CodeUtil.GetRandomDefault(returnType);
        }
        public virtual void ApdBody(StringBuilder sb, int tap, ICodeFunc func)
        {

            var returnName = GetReturnName(func);
            var returnInit = GetReturnInitVal(func);
            var tap1 = tap + 1;
            CodeUtil.SetTap(sb, tap1);
            sb.Append(func.ReturnType).Append(" ").Append(returnName);
            sb.Append(" = ").Append(returnInit).Append(";\n");

            CodeUtil.SetTap(sb, tap1);
            var maxInfo = GetMaxType(func);
            var maxType = maxInfo.Name;
            var csMaxType = maxInfo.Type;
            var maxTypeName = "m_" + returnName;
            var maxTypeInit = CSTypeMgr.GetDefault(maxType);
            sb.Append(maxType).Append(" ").Append(maxTypeName);
            sb.Append(" = ").Append(maxTypeInit).Append(";\n");

            var args = func.Args;
            int length = args.Count;
            for (int i = 0; i < length; i++)
            {
                var arg = args[i];
                var argName = arg.Name;
                var argType = arg.Type;
                var typeInfo = CSTypeMgr.Get(argType);
                var csType = typeInfo.Type;
                CodeUtil.SetTap(sb, tap1);
                var opr = CodeUtil.GetRandomOpr();

                switch (csType)
                {
                    case CSType.Bool:
                        if (csMaxType != CSType.Bool)
                        {
                            sb.Append(maxTypeName).Append(" ").Append(opr).Append("= ");
                            sb.Append("(").Append(maxType).Append(")");
                            sb.Append("(").Append(argName).Append("?");
                            sb.Append(Random.Range(-1, -8)).Append(":");
                            sb.Append(Random.Range(1, 8)).Append(")");
                        }
                        break;
                    case CSType.Char:
                    case CSType.UInt16:
                    case CSType.UInt32:
                    case CSType.UInt64:
                        sb.Append(maxTypeName).Append(" ").Append(opr).Append("= ");
                        sb.Append("(").Append(maxType).Append(")").Append(argName);
                        break;
                    case CSType.String:
                        var c = CodeUtil.GetRandomSplit();
                        var arrName = argName + "_arr";
                        sb.Append("var ").Append(arrName).Append(" = ");
                        sb.Append(argName).Append(".Split('").Append(c).Append("');\n");
                        CodeUtil.SetTap(sb, tap1);
                        sb.Append("Array.Sort(").Append(arrName).Append(")");
                        break;
                    case CSType.Vector2:
                        sb.Append(maxTypeName).Append(" ").Append(opr).Append("= ");
                        sb.Append("(").Append(maxType).Append(")");
                        sb.Append("(").Append(argName).Append(".x");
                        opr = CodeUtil.GetRandomOpr();
                        sb.Append(opr).Append(argName).Append(".y)");
                        break;
                    case CSType.Vector3:
                        sb.Append(maxTypeName).Append(" ").Append(opr).Append("= ");
                        sb.Append("(").Append(maxType).Append(")");

                        sb.Append("(").Append(argName).Append(".x");
                        opr = CodeUtil.GetRandomOpr();
                        sb.Append(opr).Append(argName).Append(".y");
                        opr = CodeUtil.GetRandomOpr();
                        sb.Append(opr).Append(argName).Append(".z)");
                        break;
                    case CSType.Vector4:
                        sb.Append(maxTypeName).Append(" ").Append(opr).Append("= ");
                        sb.Append("(").Append(maxType).Append(")");

                        sb.Append("(").Append(argName).Append(".x");
                        opr = CodeUtil.GetRandomOpr();
                        sb.Append(opr).Append(argName).Append(".y");
                        opr = CodeUtil.GetRandomOpr();
                        sb.Append(opr).Append(argName).Append(".z");
                        opr = CodeUtil.GetRandomOpr();
                        sb.Append(opr).Append(argName).Append(".w)");
                        break;
                    case CSType.Color:
                        sb.Append(maxTypeName).Append(" ").Append(opr).Append("= ");
                        sb.Append("(").Append(maxType).Append(")");

                        sb.Append("(").Append(argName).Append(".r");
                        opr = CodeUtil.GetRandomOpr();
                        sb.Append(opr).Append(argName).Append(".g");
                        opr = CodeUtil.GetRandomOpr();
                        sb.Append(opr).Append(argName).Append(".b");
                        opr = CodeUtil.GetRandomOpr();
                        sb.Append(opr).Append(argName).Append(".a)");
                        break;
                    default:
                        sb.Append(maxTypeName).Append(" ").Append(opr).Append("= ");
                        sb.Append(CodeUtil.GetRandomDefault(csType));
                        break;
                }
                sb.Append(";\n");
            }
            CodeUtil.SetTap(sb, tap1);
            sb.Append("return ").Append(returnName).Append(";\n");
        }
        #endregion

        #region 公开方法
        #endregion
    }
}