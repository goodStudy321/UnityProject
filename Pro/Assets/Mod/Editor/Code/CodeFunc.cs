//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/24 17:49:06
//=============================================================================

using System;
using System.Text;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit.Confuse
{
    /// <summary>
    /// CodeFunc
    /// </summary>
    public class CodeFunc : ICodeFunc
    {
        #region 字段
        private string name;

        private string returnType;

        private List<CSArgInfo> args = new List<CSArgInfo>();

        private CSAccessType accessType = CSAccessType.Public;
        #endregion

        #region 属性

        public string Name
        {
            get { return name; }
            set { name = StrUtil.FirstUpper(value); }
        }


        public string ReturnType
        {
            get { return returnType; }
            set { returnType = value; }
        }


        public List<CSArgInfo> Args
        {
            get { return args; }
            set { args = value; }
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
        public CodeFunc()
        {

        }

        public CodeFunc(string name, string returnType, CSAccessType accessType)
        {
            Name = name;
            this.returnType = returnType;
            this.accessType = accessType;
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public void ApdFunc(StringBuilder sb, int tap)
        {
            CodeUtil.SetTap(sb, tap);
            CodeUtil.SetAccessType(sb, accessType);
            sb.Append(" ").Append(returnType).Append(" ").Append(name);
            sb.Append("(");
            if (args != null && args.Count > 0)
            {
                int length = args.Count;
                var last = length - 1;
                for (int i = 0; i < length; i++)
                {
                    var arg = args[i];
                    sb.Append(arg.Type);
                    sb.Append(" ").Append(arg.Name);
                    if (i < last) sb.Append(", ");
                }
            }

            sb.Append(")\n");
            CodeUtil.SetTap(sb, tap);
            sb.Append("{\n");


            //BEG_方法体
            var body = ConfuseCodeBodyFty.Create(this);
            body.ApdBody(sb, tap, this);
            //END_方法体
            sb.Append("\n");
            CodeUtil.SetTap(sb, tap);
            sb.Append("}\n");
        }


        public void Dispose()
        {
            name = null;
            returnType = null;
            args.Clear();
        }
        #endregion
    }
}