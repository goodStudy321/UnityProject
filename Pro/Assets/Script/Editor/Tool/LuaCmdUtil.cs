/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2016/5/15 ‏‎20:11:26
 ============================================================================*/

using System;
using System.Collections;
using System.Collections.Generic;
using StrDic = System.Collections.Generic.Dictionary<string, string>;

namespace Loong.Edit
{
    /// <summary>
    /// Lua命令行工具
    /// </summary>
    public static class LuaCmdUtil
    {
        #region 字段
        /// <summary>
        /// 使用编码字段
        /// </summary>
        public const string K_UseEncode = "USE_ENCODE";
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        /// <summary>
        /// 解析编码参数
        /// </summary>
        /// <param name="dic"></param>
        private static void UseEncode(StrDic dic)
        {
            bool useEncode = CmdArgs.GetBool(dic, K_UseEncode);
            LuaUtil.CopyAndSetAB(useEncode);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Execute(StrDic dic)
        {
            if (BuildArgs.EnableAssetOpt)
            {
                UseEncode(dic);
            }
        }


        /// <summary>
        /// 热更处理
        /// </summary>
        public static void HandleOnHotfix()
        {
            AssetProcessor.Delete(ABNameUtil.luaName);
            UseEncode(CmdArgs.Dic);
        }
        #endregion
    }
}