#if UNITY_EDITOR

namespace Hello.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.5.14
    /// BG:编辑器样式工具
    /// </summary>
    public static class StyleTool
    {
        /// <summary>
        /// 背景样式
        /// </summary>
        public static string Bg { get { return "flow background"; } }

        /// <summary>
        /// 盒子样式
        /// </summary>
        public static string Box { get { return "box"; } }

        /// <summary>
        /// 窗口样式
        /// </summary>
        public static string Win { get { return "window"; } }

        /// <summary>
        /// 主样式
        /// </summary>
        public static string Host { get { return "hostview"; } }

        /// <summary>
        /// 加号样式
        /// </summary>
        public static string Plus { get { return "OL Plus"; } }

        /// <summary>
        /// 减号样式
        /// </summary>
        public static string Minus { get { return "OL Minus"; } }

        /// <summary>
        /// 组合框样式
        /// </summary>
        public static string Group { get { return "groupBox"; } }

        /// <summary>
        /// 选择样式
        /// </summary>
        public static string Rect { get { return "SelectionRect"; } }

        /// <summary>
        /// 覆盖样式
        /// </summary>
        public static string Overlay { get { return "flow overlay box"; } }

        /// <summary>
        /// 手里剑样式
        /// </summary>
        public static string Shuriken { get { return "ShurikenEffectBg"; } }

        #region 图标
        /// <summary>
        /// 标签图标
        /// </summary>
        public static string LabelIcon { get { return "AssetLabel Icon"; } }

        /// <summary>
        /// 输入0样式 灰
        /// </summary>
        public static string In0 { get { return "flow shader in 0"; } }

        /// <summary>
        /// 输入1样式 橙
        /// </summary>
        public static string In1 { get { return "flow shader in 1"; } }

        /// <summary>
        /// 输入2样式 绿
        /// </summary>
        public static string In2 { get { return "flow shader in 2"; } }

        /// <summary>
        /// 输入3样式 青
        /// </summary>
        public static string In3 { get { return "flow shader in 3"; } }

        /// <summary>
        /// 输入4样式 蓝
        /// </summary>
        public static string In4 { get { return "flow shader in 4"; } }

        /// <summary>
        /// 输入5样式 红
        /// </summary>
        public static string In5 { get { return "flow shader in 5"; } }

        /// <summary>
        /// 输出0样式 灰
        /// </summary>
        public static string Out0 { get { return "flow shader out 0"; } }

        /// <summary>
        /// 输出1样式 橙
        /// </summary>
        public static string Out1 { get { return "flow shader out 1"; } }

        /// <summary>
        /// 输出2样式 绿
        /// </summary>
        public static string Out2 { get { return "flow shader out 2"; } }

        /// <summary>
        /// 输出3样式 青
        /// </summary>
        public static string Out3 { get { return "flow shader out 3"; } }

        /// <summary>
        /// 输出4样式 蓝
        /// </summary>
        public static string Out4 { get { return "flow shader out 4"; } }

        /// <summary>
        /// 输出5样式 红
        /// </summary>
        public static string Out5 { get { return "flow shader out 5"; } }
        #endregion

        #region 点普通样式
        /// <summary>
        /// 点0样式 灰
        /// </summary>
        public static string Node0 { get { return "flow node 0"; } }

        /// <summary>
        /// 点1样式 蓝
        /// </summary>
        public static string Node1 { get { return "flow node 1"; } }

        /// <summary>
        /// 点2样式 青
        /// </summary>
        public static string Node2 { get { return "flow node 2"; } }

        /// <summary>
        /// 点3样式 绿
        /// </summary>
        public static string Node3 { get { return "flow node 3"; } }

        /// <summary>
        /// 点4样式 黄
        /// </summary>
        public static string Node4 { get { return "flow node 4"; } }

        /// <summary>
        /// 点5样式 橙
        /// </summary>
        public static string Node5 { get { return "flow node 5"; } }

        /// <summary>
        /// 点6样式 红
        /// </summary>
        public static string Node6 { get { return "flow node 6"; } }

        /// <summary>
        /// 点0之上样式 灰
        /// </summary>
        public static string NodeOn0 { get { return "flow node 0 on"; } }

        /// <summary>
        /// 点1之上样式 蓝
        /// </summary>
        public static string NodeOn1 { get { return "flow node 1 on"; } }

        /// <summary>
        /// 点2之上样式 青
        /// </summary>
        public static string NodeOn2 { get { return "flow node 2 on"; } }

        /// <summary>
        /// 点3之上样式 绿
        /// </summary>
        public static string NodeOn3 { get { return "flow node 3 on"; } }

        /// <summary>
        /// 点4之上样式 黄
        /// </summary>
        public static string NodeOn4 { get { return "flow node 4 on"; } }

        /// <summary>
        /// 点5之上样式 橙
        /// </summary>
        public static string NodeOn5 { get { return "flow node 5 on"; } }

        /// <summary>
        /// 点6之上样式 红
        /// </summary>
        public static string NodeOn6 { get { return "flow node 6 on"; } }
        #endregion

        #region 点魔法样式
        /// <summary>
        /// 点0魔法样式 灰
        /// </summary>
        public static string Hex0 { get { return "flow node hex 0"; } }

        /// <summary>
        /// 点1魔法样式 蓝
        /// </summary>
        public static string Hex1 { get { return "flow node hex 1"; } }

        /// <summary>
        /// 点2魔法样式 青
        /// </summary>
        public static string Hex2 { get { return "flow node hex 2"; } }

        /// <summary>
        /// 点3魔法样式 绿
        /// </summary>
        public static string Hex3 { get { return "flow node hex 3"; } }

        /// <summary>
        /// 点4魔法样式 黄
        /// </summary>
        public static string Hex4 { get { return "flow node hex 4"; } }

        /// <summary>
        /// 点5魔法样式 橙
        /// </summary>
        public static string Hex5 { get { return "flow node hex 5"; } }

        /// <summary>
        /// 点6魔法样式 红
        /// </summary>
        public static string Hex6 { get { return "flow node hex 6"; } }


        /// <summary>
        /// 点0魔法之上样式 灰
        /// </summary>
        public static string HexOn0 { get { return "flow node hex 0 on"; } }

        /// <summary>
        /// 点1魔法之上样式 蓝
        /// </summary>
        public static string HexOn1 { get { return "flow node hex 1 on"; } }

        /// <summary>
        /// 点2魔法之上样式 青
        /// </summary>
        public static string HexOn2 { get { return "flow node hex 2 on"; } }

        /// <summary>
        /// 点3魔法之上样式 绿
        /// </summary>
        public static string HexOn3 { get { return "flow node hex 3 on"; } }

        /// <summary>
        /// 点4魔法之上样式 黄
        /// </summary>
        public static string HexOn4 { get { return "flow node hex 4 on"; } }

        /// <summary>
        /// 点5魔法之上样式 橙
        /// </summary>
        public static string HexOn5 { get { return "flow node hex 5 on"; } }

        /// <summary>
        /// 点6魔法之上样式 红
        /// </summary>
        public static string HexOn6 { get { return "flow node hex 6 on"; } }
        #endregion

        #region 变量样式
        /// <summary>
        /// 变量0样式 灰
        /// </summary>
        public static string Var0 { get { return "flow var 0"; } }

        /// <summary>
        /// 变量1样式 蓝
        /// </summary>
        public static string Var1 { get { return "flow var 1"; } }

        /// <summary>
        /// 变量2样式 青
        /// </summary>
        public static string Var2 { get { return "flow var 2"; } }

        /// <summary>
        /// 变量3样式 绿
        /// </summary>
        public static string Var3 { get { return "flow var 3"; } }

        /// <summary>
        /// 变量4样式 黄
        /// </summary>
        public static string Var4 { get { return "flow var 4"; } }

        /// <summary>
        /// 变量5样式 橙
        /// </summary>
        public static string Var5 { get { return "flow var 5"; } }

        /// <summary>
        /// 变量6样式 红
        /// </summary>
        public static string Var6 { get { return "flow var 6"; } }


        /// <summary>
        /// 变量0之上样式 淡灰
        /// </summary>
        public static string VarOn0 { get { return "flow var 0 on"; } }

        /// <summary>
        /// 变量1之上样式 淡蓝
        /// </summary>
        public static string VarOn1 { get { return "flow var 1 on"; } }

        /// <summary>
        /// 变量2之上样式 淡青
        /// </summary>
        public static string VarOn2 { get { return "flow var 2 on"; } }

        /// <summary>
        /// 变量3之上样式 淡绿
        /// </summary>
        public static string VarOn3 { get { return "flow var 3 on"; } }

        /// <summary>
        /// 变量4之上样式 淡黄
        /// </summary>
        public static string VarOn4 { get { return "flow var 4 on"; } }

        /// <summary>
        /// 变量5之上样式 淡橙
        /// </summary>
        public static string VarOn5 { get { return "flow var 5 on"; } }

        /// <summary>
        /// 变量6之上样式 淡红
        /// </summary>
        public static string VarOn6 { get { return "flow var 6 on"; } }
        #endregion

        #region 标签样式
        /// <summary>
        /// 标签样式0 灰
        /// </summary>
        public static string Label0 { get { return "sv_label_0"; } }

        /// <summary>
        /// 标签样式1 蓝
        /// </summary>
        public static string Label1 { get { return "sv_label_1"; } }

        /// <summary>
        /// 标签样式2 青
        /// </summary>
        public static string Label2 { get { return "sv_label_2"; } }

        /// <summary>
        /// 标签样式3 绿
        /// </summary>
        public static string Label3 { get { return "sv_label_3"; } }

        /// <summary>
        /// 标签样式4 黄
        /// </summary>
        public static string Label4 { get { return "flow var 4"; } }

        /// <summary>
        /// 标签样式5  橙
        /// </summary>
        public static string Label5 { get { return "sv_label_5"; } }

        /// <summary>
        /// 标签样式6 红
        /// </summary>
        public static string Label6 { get { return "sv_label_6"; } }


        /// <summary>
        /// 标签样式7 紫
        /// </summary>
        public static string Label7 { get { return "sv_label_7"; } }
        #endregion

        /// <summary>
        /// 通知背景样式
        /// </summary>
        public static string Notification { get { return "NotificationBackground"; } }


        public static string Info
        {
            get { return "CN EntryInfo"; }
        }
        public static string Error
        {
            get { return "CN EntryError"; }
        }
        public static string Warning
        {
            get { return "CN EntryWarn"; }
        }

        public static string GradDown
        {
            get { return "Grad Down Swatch"; }
        }

        public static string GradUp
        {
            get { return "Grad Up Swatch"; }
        }

        public static string MultiTog
        {
            get { return "MuteToggle"; }
        }

        public static string Cancel
        {
            get { return "SearchCancelButton"; }
        }

        public static string X
        {
            get { return "TL SelectionBarCloseButton"; }
        }

        public static string Ping
        {
            get { return "WinBtnMaxMac"; }
        }


    }
}
#endif