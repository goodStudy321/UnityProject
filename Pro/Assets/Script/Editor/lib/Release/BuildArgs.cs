/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/12/25 16:33:52
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
    /// 构建参数
    /// </summary>
    public static class BuildArgs
    {
        #region 字段
        public const string K_PKG = "K_PKG";

        public const string K_DELAB = "-DelAB";

        public const string K_BACKEND = "-Backend";

        public const string K_BUILDAB = "-BUILD_AB";

        public const string K_LANGUAGE = "-APP_LANG";

        public const string K_ASSET_VER = "-ASSET_VER";

        public const string K_CONTAIN_ALLUPGS = "-CONTAIN_ALLUPGS";

        public const string K_ASSET_UPG_MODE = "-ASSET_UPG_MODE";

        public const string K_CHANNEL_UID = "-CHANNEL_UID";

        public const string K_DISPLAYNAME = "-DISPLAY_NAME";

        public const string K_CONFUSE_FREQ = "-CONFUSE_FREQ";

        public const string K_ENABLE_ASSET_OPT = "-ENABLE_ASSET_OPT";

        public const string K_ENABLE_CONFUSE = "-ENABLE_CONFUSE";

        public const string K_CONFUSE_UNUSED_FILE_COUNT = "-CONFUSE_UNUSED_FILE_COUNT";

        public const string K_RELEASE_DEBUG = "-RELEASE_DEBUG";


        #endregion

        #region 属性

        /// <summary>
        /// true:删除资源包
        /// </summary>
        public static bool DelAB
        {
            get
            {
                return CmdArgs.GetBool(K_DELAB);
            }
        }

        /// <summary>
        /// true:打包AB,false:不打包
        /// </summary>
        public static bool BuildAB
        {
            get
            {
                return CmdArgs.GetInt(K_BUILDAB, 1) > 0;
            }
        }

        /// <summary>
        /// true:添加了GAME_DEBUG预处理指令
        /// </summary>
        public static bool IsDebug
        {
            get { return CmdArgs.GetBool(Preprocess.GAME_DEBUG); }
        }

        /// <summary>
        /// 资源版本号
        /// </summary>
        public static int AssetVer
        {
            get
            {
                return CmdArgs.GetInt(K_ASSET_VER, 0);
            }
        }

        /// <summary>
        /// 打递增包时,是否需要包含所有已热更资源
        /// </summary>
        public static bool ContainAllUpgs
        {
            get { return CmdArgs.GetBool(K_CONTAIN_ALLUPGS, true); }
        }

        public static int AssetUpgMode
        {
            get { return CmdArgs.GetInt(K_ASSET_UPG_MODE, 0); }
        }

        /// <summary>
        /// 渠道唯一标识
        /// 是游戏对渠道的分类
        /// </summary>
        public static int ChannelUID
        {
            get { return CmdArgs.GetInt(K_CHANNEL_UID, 0); }
        }

        /// <summary>
        /// 获取语言
        /// </summary>
        public static string Language
        {
            get
            {
                return CmdArgs.GetStr(K_LANGUAGE, "zh_CN");
            }
        }

        /// <summary>
        /// 获取显示名称
        /// </summary>
        public static string DisplayName
        {
            get
            {
                return CmdArgs.GetStr(K_DISPLAYNAME, "天道问情");
            }
        }

        /// <summary>
        /// 混淆次数
        /// < 0 重置
        /// = 0 正常递增
        /// > 0 指定次数
        /// </summary>
        public static int ConfuseFreq
        {
            get
            {
                return CmdArgs.GetInt(K_CONFUSE_FREQ, 0);
            }
        }

        /// <summary>
        /// true:激活混淆
        /// </summary>
        public static bool EnableConfuse
        {
            get
            {
                return CmdArgs.GetBool(K_ENABLE_CONFUSE);
            }
        }



        /// <summary>
        /// true:激活资源操作,包含:收集版本资源/拷贝首包/整包资源
        /// </summary>
        public static bool EnableAssetOpt
        {
            get
            {
                return CmdArgs.GetBool(K_ENABLE_ASSET_OPT);
            }
        }


        /// <summary>
        /// 无用资源文件数量
        /// < 0 重置
        /// = 0 正常递增
        /// > 0 指定数量
        /// </summary>
        public static int ConfuseUnusedFileCount
        {
            get
            {
                return CmdArgs.GetInt(K_CONFUSE_UNUSED_FILE_COUNT, 0);
            }
        }

        /// <summary>
        /// true:正式环境下测试
        /// </summary>
        public static bool IsReleaseDebug
        {
            get { return CmdArgs.GetBool(K_RELEASE_DEBUG); }
        }


        /// <summary>
        /// 脚本后端
        /// </summary>
        public static ScriptingImplementation Backend
        {
            get
            {
                var str = CmdArgs.GetStr(K_BACKEND, "mono").ToLower();
                return str == "il2cpp" ? ScriptingImplementation.IL2CPP : ScriptingImplementation.Mono2x;
            }
        }

        /// <summary>
        /// 包内资源类型
        /// </summary>
        public static PkgKind Pkg
        {
            get
            {
                var val = CmdArgs.GetInt(K_PKG, 1);
                return (PkgKind)val;
            }
        }

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

        #endregion
    }
}