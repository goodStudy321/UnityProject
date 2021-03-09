//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/24 17:49:01
//=============================================================================

using System;
using Loong.Game;
using System.Text;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// CodeClass
    /// </summary>
    public class CodeClass : ICodeClass
    {
        #region 字段
        private string name;

        private string baseClass;

        private List<ICodeProp> props = new List<ICodeProp>();

        private List<ICodeFunc> funcs = new List<ICodeFunc>();

        private CSAccessType accessType = CSAccessType.Public;

        protected StringBuilder sb = new StringBuilder();
        #endregion

        #region 属性

        public string Name
        {
            get { return name; }
            set { name = StrUtil.FirstUpper(value); }
        }


        public string BaseClass
        {
            get { return baseClass; }
            set { baseClass = value; }
        }



        public List<ICodeProp> Props
        {
            get { return props; }
            set { props = value; }
        }


        public List<ICodeFunc> Funcs
        {
            get { return funcs; }
            set { funcs = value; }
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
        public CodeClass()
        {

        }

        public CodeClass(string name, string baseClass, CSAccessType accessType)
        {
            Name = name;
            BaseClass = baseClass;
            AccessType = accessType;
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        public void Dispose()
        {
            name = null;
            int length = funcs.Count;
            for (int i = 0; i < length; i++)
            {
                var func = funcs[i];
                func.Dispose();
            }
            funcs.Clear();

            length = props.Count;
            for (int i = 0; i < length; i++)
            {
                props[i].Dispose();
            }
            props.Clear();
        }
        #endregion

        #region 公开方法
        public void Gen(StringBuilder sb, string path)
        {
            sb.Append("using System;\n");
            sb.Append("using UnityEngine;\n");
            sb.Append("using System.Collections.Generic;\n\n");

            CodeUtil.SetAccessType(sb, accessType);
            sb.Append(" class ").Append(name);
            if (!string.IsNullOrEmpty(baseClass))
            {
                sb.Append(" : ").Append(baseClass);
            }
            sb.Append("\n{\n");

            //BEG_字段
            int tap1 = 1;
            int length = props.Count;
            for (int i = 0; i < length; i++)
            {
                var prop = props[i];
                prop.ApdField(sb, tap1);
                sb.Append("\n\n");
            }
            //END_字段

            //BEG_属性
            for (int i = 0; i < length; i++)
            {
                var prop = props[i];
                prop.ApdProp(sb, tap1);
                sb.Append("\n\n");
            }
            //END_属性


            //BEG_方法
            length = funcs.Count;
            for (int i = 0; i < length; i++)
            {
                var func = funcs[i];
                func.ApdFunc(sb, tap1);
                sb.Append("\n\n");
            }
            //END_方法

            sb.Append("\n}");
            FileTool.Save(path, sb.ToString());
            //sb.Remove(0, sb.Length);
        }
        #endregion
    }
}