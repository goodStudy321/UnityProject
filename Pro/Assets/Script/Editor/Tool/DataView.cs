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
     * GUID:        74bbd433-264c-4443-a2a0-71ab76c80b0d
    */

    /// <summary>
    /// AU:Loong
    /// TM:2014/6/24 10:27:42
    /// BG:数据处理
    /// </summary>
    public class DataView : EditViewBase
    {
        #region 字段
        /// <summary>
        /// 客户端Excel导出lua配置
        /// </summary>
        public string executeLua = "../Table/MakeLua.bat";

        /// <summary>
        /// 执行数据文件,并拷贝数据和脚本
        /// </summary>
        public string executeData1 = "../Table/MakeTable.bat";

        /// <summary>
        /// 执行数据文件,并拷贝数据
        /// </summary>
        public string executeData2 = "../Table/MakeTableClient.bat";
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void SetProperty()
        {
            if (!UIEditTool.DrawHeader("基础属性", "DataViewProperty", StyleTool.Host)) return;
            EditorGUILayout.BeginVertical(StyleTool.Box);
            UIEditLayout.SetPath("Excel导出所有配置:", ref executeData1, this, "bat");
            UIEditLayout.SetPath("Excel导出C#数据:", ref executeData2, this, "bat");
            UIEditLayout.SetPath("Excel导出Lua:", ref executeLua, this, "bat");
            EditorGUILayout.EndVertical();
        }

        private void ShowCommand()
        {
            if (!UIEditTool.DrawHeader("命令", "DataViewCommand", StyleTool.Host)) return;
            EditorGUILayout.BeginVertical(StyleTool.Box);
            if (GUILayout.Button("执行MakeTableClient")) DataTool.MakeTableClient();
            if (GUILayout.Button("执行MakeTable")) DataTool.MakeTable();
            EditorGUILayout.EndVertical();
        }
        #endregion

        #region 保护方法
        protected override void OnGUICustom()
        {
            SetProperty();
            EditorGUILayout.Space();
            ShowCommand();
        }
        #endregion

        #region 公开方法

        #endregion
    }
}