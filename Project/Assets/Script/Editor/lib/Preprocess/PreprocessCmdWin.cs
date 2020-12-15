using Hello.Game;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace Hello.Edit
{
    public class PreprocessCmdWin : EditWinBase
    {
        /// <summary>
        /// 菜单优先级
        /// </summary>
        public const int Pri = MenuTool.NormalPri + 1;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Hello + "预处理指令工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.AHello + "预处理指令工具/";

        [MenuItem(menu + "窗口", false, Pri)]
        [MenuItem(AMenu + "窗口", false, Pri)]
        private static void Open()
        {
            WinUtil.Open<PreprocessCmdWin, PreprocessCmdView>("预处理指令", 600, 700);
        }
    }

}
