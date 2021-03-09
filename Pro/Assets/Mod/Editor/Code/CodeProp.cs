//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/25 20:44:08
//=============================================================================

using System;
using System.Text;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// CodeProp
    /// </summary>
    public class CodeProp : ICodeProp
    {
        #region 字段
        private string name;

        private string type;

        private string field;

        private bool isList = false;

        private CSPropType propType = CSPropType.All;

        private CSAccessType accessType = CSAccessType.Public;
        #endregion

        #region 属性

        public string Name
        {
            get { return name; }
            set
            {
                name = StrUtil.FirstUpper(value);
                field = StrUtil.FirstLower(value);
            }
        }

        public string Type
        {
            get { return type; }
            set { type = value; }
        }

        public bool IsList
        {
            get { return isList; }
            set { isList = value; }
        }

        public CSPropType PropType
        {
            get { return propType; }
            set { propType = value; }
        }

        public CSAccessType AccessType
        {
            get { return accessType; }
            set { accessType = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public CodeProp()
        {

        }

        public CodeProp(string name, string type, bool isList, CSPropType propType, CSAccessType accessType)
        {
            Name = name;
            this.type = type;
            this.isList = isList;
            this.propType = propType;
            this.accessType = accessType;
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void ApdField(StringBuilder sb, int tap)
        {
            CodeUtil.SetTap(sb, tap);
            if (isList)
            {
                sb.Append("private List<").Append(type).Append("> ");
            }
            else
            {
                sb.Append("private ").Append(type).Append(" ");
            }
            sb.Append(field).Append(";");
        }

        public void ApdProp(StringBuilder sb, int tap)
        {
            CodeUtil.SetTap(sb, tap);
            CodeUtil.SetAccessType(sb, accessType);
            sb.Append(" ");
            if (isList)
            {
                sb.Append("List<").Append(type).Append("> ");
            }
            else
            {
                sb.Append(type).Append(" ");
            }
            sb.Append(name).Append("\n");
            CodeUtil.SetTap(sb, tap);
            sb.Append("{\n");
            if (propType == CSPropType.All || propType == CSPropType.Get)
            {
                CodeUtil.SetTap(sb, tap + 1);
                sb.Append("get { return ").Append(field).Append("; }\n");
            }
            if (propType == CSPropType.All || propType == CSPropType.Set)
            {
                CodeUtil.SetTap(sb, tap + 1);
                sb.Append("set { ").Append(field).Append(" = value; }\n");
            }
            CodeUtil.SetTap(sb, tap);
            sb.Append("}");
        }

        public void Dispose()
        {
            name = null;
            type = null;
            isList = false;
            propType = CSPropType.All;
            accessType = CSAccessType.Public;
        }
        #endregion
    }
}