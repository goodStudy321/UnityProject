using System;
using UnityEngine;
using LuaInterface;
using System.Collections;
using System.Collections.Generic;

/*
 * 如有改动需求,请联系Loong
 * 如果必须改动,请知会Loong
*/

namespace Loong.Game
{
    using Lang = Phantom.Localization;
    /// <summary>
    /// AU:Loong
    /// TM:2014.09.20
    /// BG:显示信息框
    /// </summary>
    public static class MsgBox
    {
        public enum CloseOpt
        {
            None,
            Yes,
            No
        }
        #region 字段

        private static string noValue = "";

        private static string yesValue = "";


        public static string msgValue = "";

        private static Action noCb = null;

        private static Action yesCb = null;


        private static CloseOpt _closeOpt;

        private static LuaTable table = null;
        #endregion

        #region 属性
        /// <summary>
        /// 关闭时,No:走N回调 Yes:走Y回调,None:无
        /// </summary>
        public static CloseOpt closeOpt
        {
            get { return _closeOpt; }
            set
            {
                _closeOpt = value;
                SetCloseOpt(value);
            }
        }

        #endregion

        #region 构造方法
        static MsgBox()
        {
            Add();
        }
        #endregion

        #region 私有方法

        private static void SetCloseOpt(CloseOpt value)
        {
            if (table == null) table = LuaMgr.Lua.GetTable("MsgBox");
            if (table == null) return;
            table["CloseOpt"] = (int)value;
        }

        private static void ShowYes(string uiName)
        {
            EventMgr.Trigger(EventKey.MsgBoxYes, msgValue, yesValue);
        }

        private static void ShowYesNo(string uiName)
        {
            EventMgr.Trigger(EventKey.MsgBoxYesNo, msgValue, yesValue, noValue);
        }

        private static void ClickNo(params object[] args)
        {
            if (noCb != null)
            {
                noCb();
            }
            Clear();
        }

        private static void ClickYes(params object[] args)
        {
            if (yesCb != null)
            {
                yesCb();
            }
            Clear();
        }

        private static void Clear(params object[] args)
        {
            noCb = null;
            yesCb = null;
            closeOpt = CloseOpt.None;
        }

        private static void SetYesVal(string val)
        {
            if (val == null) val = Lang.Instance.GetDes(690000);
            yesValue = val;
        }

        private static void SetNoVal(string val)
        {
            if (val == null) val = Lang.Instance.GetDes(690001);
            noValue = val;
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 显示
        /// </summary>
        /// <param name="msg">信息</param>
        /// <param name="yes">确定按钮字符</param>
        /// <param name="yesCb">按钮回调</param>
        public static void Show(string msg, string yes, Action yesCb)
        {
            SetYesVal(yes);
            msgValue = msg;
            MsgBox.yesCb = yesCb;
            UIMgr.Open(UIName.MsgBox, ShowYes);
        }

        /// <summary>
        /// 显示
        /// </summary>
        /// <param name="msg">信息</param>
        /// <param name="yes">确定按钮字符</param>
        /// <param name="yesCb">确定按钮回调</param>
        /// <param name="no">否定按钮字符</param>
        /// <param name="noCb">否定按钮回调</param>
        public static void Show(string msg, string yes, Action yesCb, string no, Action noCb)
        {
            SetNoVal(no);
            SetYesVal(yes);
            msgValue = msg;
            MsgBox.noCb = noCb;
            MsgBox.yesCb = yesCb;
            UIMgr.Open(UIName.MsgBox, ShowYesNo);
        }

        #region 本地化

        /// <summary>
        /// 显示
        /// </summary>
        /// <param name="msg">信息</param>
        /// <param name="yes">确定按钮字符</param>
        /// <param name="yesCb">按钮回调</param>
        public static void Show(uint msg, uint yes, Action yesCb)
        {
            yesValue = Lang.Instance.GetDes(yes);
            msgValue = Lang.Instance.GetDes(msg);
            MsgBox.yesCb = yesCb;
            UIMgr.Open(UIName.MsgBox, ShowYes);
        }

        /// <summary>
        /// 显示
        /// </summary>
        /// <param name="msg">信息</param>
        /// <param name="yes">确定按钮字符</param>
        /// <param name="yesCb">确定按钮回调</param>
        /// <param name="no">否定按钮字符</param>
        /// <param name="noCb">否定按钮回调</param>
        public static void Show(uint msg, uint yes, Action yesCb, uint no, Action noCb)
        {
            noValue = Lang.Instance.GetDes(no);
            yesValue = Lang.Instance.GetDes(yes);
            msgValue = Lang.Instance.GetDes(msg);
            MsgBox.noCb = noCb;
            MsgBox.yesCb = yesCb;
            UIMgr.Open(UIName.MsgBox, ShowYesNo);
        }

        #endregion

        /// <summary>
        /// 设置对话框是否持久显示
        /// </summary>
        /// <param name="val"></param>
        public static void SetConDisplay(bool val)
        {
            EventMgr.Trigger("MsgBoxConDisplay", val);
        }

        public static void Add()
        {
            EventMgr.Add("MsgBoxClear", Clear);
            EventMgr.Add(EventKey.MsgBoxClickNo, ClickNo);
            EventMgr.Add(EventKey.MsgBoxClickYes, ClickYes);
        }
        #endregion
    }
}