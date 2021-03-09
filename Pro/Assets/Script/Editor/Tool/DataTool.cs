using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /*
     * CO:            
     * Copyright:   2014-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        4b958932-d758-450b-87ee-a5d65c57975f
    */

    /// <summary>
    /// AU:Loong
    /// TM:2014/6/24 10:27:29
    /// BG:数据批处理
    /// </summary>
    public class DataTool : EditWinBase
    {
        #region 字段
        private static DataView data = null;
        /// <summary>
        /// 优先级
        /// </summary>
        public const int Pri = MenuTool.NormalPri + 1;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Loong + "配置表工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "配置表工具/";
        #endregion

        #region 属性

        public static DataView Data
        {
            get
            {
                if (data == null)
                {
                    data = AssetDataUtil.Get<DataView>();
                }
                return data;
            }
        }

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 打开窗口
        /// </summary>
        [MenuItem(menu + "设置窗口", false, Pri)]
        [MenuItem(AMenu + "设置窗口", false, Pri)]
        public static void Open()
        {
            WinUtil.Open<DataTool, DataView>("数据处理窗口", 600, 800);
        }

        /// <summary>
        /// Excel导出lua
        /// </summary>
        [MenuItem(menu + "Excel导出Lua(MakeLua) %&u", false, Pri + 1)]
        [MenuItem(AMenu + "Excel导出Lua(MakeLua)", false, Pri + 1)]
        public static void MakeLua()
        {
            ProcessUtil.Execute(Data.executeLua);
        }

        /// <summary>
        /// Excel导出C#数据
        /// </summary>
        [MenuItem(menu + "Excel导出C#数据(MakeTableClient) &#u", false, Pri + 2)]
        [MenuItem(AMenu + "Excel导出C#数据(MakeTableClient)", false, Pri + 2)]
        public static void MakeTableClient()
        {
            ProcessUtil.Execute(Data.executeData2);
        }

        /// <summary>
        /// Excel导出所有配置
        /// </summary>
        [MenuItem(menu + "Excel导出所有配置(MakeTable) %#u", false, Pri + 3)]
        [MenuItem(AMenu + "Excel导出所有配置(MakeTable)", false, Pri + 3)]

        public static void MakeTable()
        {
            ProcessUtil.Execute(Data.executeData1);
        }


        /// <summary>
        /// 一键生成所有
        /// </summary>
        [MenuItem(menu + "生成所有配置和协议 &r", false, Pri + 4)]
        public static void MakeAll()
        {
            if (!EditorUtility.DisplayDialog("", "生成所有配置和协议", "是", "否")) return;
            MakeTable();
            ProtoUtil.GenCS();
            ProtoUtil.GenLua();
        }

        /// <summary>
        /// 一键生成所有
        /// </summary>
        [MenuItem(menu + "生成所有配置_清理生成lua_打包AB", false, Pri + 5)]
        public static void ClearGenLuaMakeCfgAB()
        {
            if (!EditorUtility.DisplayDialog("", "生成所有配置_清理生成lua_打包AB", "是", "否")) return;
            ToLuaMenu.ClearLuaWraps();
            ToLuaMenu.GenLuaAllWithoutDialog();
            ABTool.BuildUserSettings();
            MakeTable();
        }
        #endregion
    }
}