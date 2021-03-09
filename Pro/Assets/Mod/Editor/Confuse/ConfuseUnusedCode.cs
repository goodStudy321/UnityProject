//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/15 11:47:08
//=============================================================================

using System;
using System.IO;
using Loong.Edit;
using Loong.Game;
using System.Text;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit.Confuse
{
    using Random = UnityEngine.Random;

    /// <summary>
    /// ConfuseUnusedCode
    /// </summary>
    public class ConfuseUnusedCode : ConfuseBase
    {
        #region 字段
        private ConfuseCfg cfg = null;

        private ConfuseCodeCfg codeCfg = null;

        /// <summary>
        /// 属性名称列表
        /// </summary>
        private List<string> propNames = null;

        /// <summary>
        /// 方法名称列表
        /// </summary>
        private List<string> funcNames = null;

        /// <summary>
        /// 类型名称列表
        /// </summary>
        private List<string> typeNames = null;

        private List<ICodeClass> codeClasses = new List<ICodeClass>();
        #endregion

        #region 属性


        public List<ICodeClass> CodeClasses
        {
            get { return codeClasses; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public ConfuseUnusedCode()
        {

        }

        public ConfuseUnusedCode(ConfuseCfg cfg, ConfuseCodeCfg codeCfg)
        {
            this.cfg = cfg;
            this.codeCfg = codeCfg;
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected string GetClassName(string name)
        {
            name = string.Format("{0}{1}{2}{3}", name, codeCfg.unusedFlag, codeCfg.flag, cfg.freq);
            return name;
        }

        protected int GetClassCount()
        {
            return Random.Range(codeCfg.unusedTypeMin, codeCfg.unusedTypeMax);
        }

        protected int GetPropCount()
        {
            return Random.Range(codeCfg.unusedPropMin, codeCfg.unusedPropMax);
        }

        protected int GetFuncCount()
        {
            return Random.Range(codeCfg.unusedFuncMin, codeCfg.unusedFuncMax);
        }

        protected int GetFuncArgCount()
        {
            return Random.Range(codeCfg.unusedFuncArgMin, codeCfg.unusedFuncArgMax);
        }


        protected void AddProps(CodeClass codeClass, List<string> newPropNames)
        {
            newPropNames.Clear();
            newPropNames.AddRange(propNames);
            int propLen = GetPropCount();
            for (int p = 0; p < propLen; p++)
            {
                var pn = CodeUtil.GetRandomStr(newPropNames);
                var type = CSTypeMgr.GetRandomType();
                var isList = CodeUtil.GetRandomIsList();
                var propType = CodeUtil.GetRandomPropType();
                var accessType = CodeUtil.GetRandomAccessType();
                var prop = new CodeProp(pn, type, isList, propType, accessType);

                codeClass.Props.Add(prop);
            }
        }


        protected void AddFuncs(CodeClass codeClass, List<string> newFuncNames, List<string> newPropNames)
        {
            bool hasPublic = false;
            var funcs = codeClass.Funcs;
            int funcLen = GetFuncCount();
            for (int f = 0; f < funcLen; f++)
            {
                newFuncNames.Clear();
                newFuncNames.AddRange(funcNames);
                var fn = CodeUtil.GetRandomStr(newFuncNames);
                var retrunType = CSTypeMgr.GetRandomType();
                var accessType = CodeUtil.GetRandomAccessType();
                if (accessType == CSAccessType.Public) hasPublic = true;
                var codeFunc = new CodeFunc(fn, retrunType, accessType);
                int argCount = GetFuncArgCount();
                for (int j = 0; j < argCount; j++)
                {
                    var argType = CSTypeMgr.GetRandomType();
                    var argName = CodeUtil.GetRandomStr(newPropNames);
                    var arg = new CSArgInfo(argType, argName);
                    codeFunc.Args.Add(arg);
                }
                funcs.Add(codeFunc);
            }
            if (!hasPublic)
            {
                int idx = Random.Range(0, funcs.Count);
                funcs[idx].AccessType = CSAccessType.Public;
            }
        }

        #endregion

        #region 公开方法
        public override void Apply()
        {

            var cCfg = codeCfg;
            propNames = CodeUtil.GetStrs(cCfg.fieldNamePath);
            funcNames = CodeUtil.GetStrs(cCfg.funcNamePath);
            typeNames = CodeUtil.GetStrs(cCfg.destTypePath);

            var newPropNames = new List<string>();
            var newFuncNames = new List<string>();

            var sb = new StringBuilder();
            var typeLen = GetClassCount();
            for (int i = 0; i < typeLen; i++)
            {
                var className = CodeUtil.GetRandomStr(typeNames);
                className = GetClassName(className);
                var baseClass = CodeUtil.GetRandomBase(cCfg.baseClasses);
                var accessType = CodeUtil.GetRandomClassAccessType();
                var codeClass = new CodeClass(className, baseClass, accessType);

                className = codeClass.Name;
                var fileName = className + Suffix.CS;
                var path = Path.Combine(cCfg.cacheDir, cCfg.unusedDir);
                path = Path.Combine(path, fileName);


                //BEG_插入属性
                AddProps(codeClass, newPropNames);
                //END_插入属性

                //BEG_插入方法
                AddFuncs(codeClass, newFuncNames, newPropNames);
                //END_插入方法


                codeClass.Gen(sb, path);
                codeClasses.Add(codeClass);
                sb.Remove(0, sb.Length);
            }

        }
        #endregion
    }
}