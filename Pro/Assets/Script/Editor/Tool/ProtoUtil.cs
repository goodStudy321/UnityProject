/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2017/4/19 10:37:01
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
    /// 协议工具
    /// </summary>
    public static class ProtoUtil
    {
        #region 字段
        /// <summary>
        /// 优先级
        /// </summary>
        public const int Pri = MenuTool.NormalPri + 90;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Loong + "协议/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "协议/";
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        /// <summary>
        /// 打开结构文件
        /// </summary>
        #region 公开方法

        [MenuItem(menu + "CS/打开结构文件", false, Pri)]
        [MenuItem(AMenu + "CS/打开结构文件", false, Pri)]
        public static void OpenProto()
        {
            string path = "../Protobuf/Proto/proto.proto";
            ProcessUtil.Execute(path, "协议结构文件");

        }

        /// <summary>
        /// 打开目录
        /// </summary>
        [MenuItem(menu + "CS/打开目录", false, Pri + 1)]
        [MenuItem(AMenu + "CS/打开目录", false, Pri + 1)]
        public static void OpenDir()
        {
            string path = "../Protobuf";
            ProcessUtil.Start(path, "协议目录");
        }

        /// <summary>
        /// 生成并且有提示框
        /// </summary>
        [MenuItem(menu + "CS/生成 &g", false, Pri + 2)]
        [MenuItem(AMenu + "CS/生成", false, Pri + 2)]

        public static void GenCSWithDialog()
        {
            DialogUtil.Show("", "确定生成CS协议", GenCS);
        }

        /// <summary>
        /// 生成协议
        /// </summary>
        public static void GenCS()
        {
            string path = "../Protobuf/Proto.bat";
            ProcessUtil.Execute(path, "协议批处理");
        }


        /// <summary>
        /// 打开目录
        /// </summary>
        [MenuItem(menu + "Lua/打开目录", false, Pri + 5)]
        [MenuItem(AMenu + "Lua/打开目录", false, Pri + 5)]
        public static void OpenLuaDir()
        {
            string path = "../Protobuf_lua";
            ProcessUtil.Start(path, "lua协议目录");
        }

        /// <summary>
        /// 生成并且有提示框
        /// </summary>
        [MenuItem(menu + "Lua/生成 &b", false, Pri + 2)]
        [MenuItem(AMenu + "Lua/生成", false, Pri + 2)]

        public static void GenLuaWithDialog()
        {
            DialogUtil.Show("", "确定生成LUA协议", GenLua);
        }

        /// <summary>
        /// 生成协议
        /// </summary>
        public static void GenLua()
        {
            string path = "../Protobuf_lua/make_lua_proto.bat";
            ProcessUtil.Execute(path, "lua协议批处理");
        }
        #endregion
    }
}