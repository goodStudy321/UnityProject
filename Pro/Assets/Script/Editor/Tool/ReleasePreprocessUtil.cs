/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.2.15 20:09:23
 ============================================================================*/

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{

    using StrDic = Dictionary<string, string>;

    /// <summary>
    /// 发布时预处理指令工具
    /// </summary>
    public static class ReleasePreprocessUtil
    {
        #region 字段
        /// <summary>
        /// 服务器选项键值
        /// </summary>
        public const string SVR_OP = "SVR_OP";

        /// <summary>
        /// 服务器选项参数列表
        /// </summary>
        private readonly static List<string> SvrOps = new List<string> {
            "SVR_OP_EVALUATION"
        };
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        /// <summary>
        /// 在符号列表中选择一个符号,移除其它符号,当参数不存在时,移除所有符号
        /// </summary>
        /// <param name="dic">参数字典</param>
        /// <param name="dic">选项列表</param>
        /// <param name="opKey">选项键值</param>
        private static void Switch(StrDic dic, List<string> ops, string opKey)
        {
            string op = null;
            if (dic.ContainsKey(opKey))
            {
                op = dic[opKey];
            }
            if (op == null)
            {
                PreprocessCmdUtil.Remove(ops);
            }
            else
            {
                PreprocessCmdUtil.Switch(ops, op);
            }
        }

        /// <summary>
        /// 根据Y或N设置符号
        /// </summary>
        /// <param name="dic">参数字典</param>
        /// <param name="dic">符号值</param>
        private static void Set(StrDic dic, string symbol)
        {
            if (!dic.ContainsKey(symbol)) return;
            if (CmdArgs.GetBool(dic, symbol))
            {
                PreprocessCmdUtil.Add(symbol);
            }
            else
            {
                PreprocessCmdUtil.Remove(symbol);
            }
            iTrace.Log("Loong", "{0} 预处理:{1}", CmdArgs.GetBool(dic, symbol), symbol);
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Execute(StrDic dic)
        {
            Set(dic, Preprocess.SUB_ASSET);
            Set(dic, Preprocess.GAME_DEBUG);
            Set(dic, Preprocess.CS_HOTFIX_ENABLE);
            Set(dic, Preprocess.ENABLE_POSTPROCESS);
            Switch(dic, SvrOps, SVR_OP);
        }

        /// <summary>
        /// 添加预处理指令,将字典中其它键值代表的预处理指令移除
        /// </summary>
        /// <param name="dic">命令行参数字典</param>
        /// <param name="preDic">预处理指令字典</param>
        /// <param name="key">目标预处理指令键值</param>
        public static void Switch(StrDic dic, StrDic preDic, string key)
        {
            if (!dic.ContainsKey(key)) return;
            var symbol = dic[key];
            PreprocessCmdUtil.Switch(preDic, symbol);
        }
        #endregion
    }
}