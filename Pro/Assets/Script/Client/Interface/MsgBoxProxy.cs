/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2015.3.20 20:38:52
 ============================================================================*/

using System;
using UnityEngine;
namespace Loong.Game
{
    using Lang = Phantom.Localization;

    /// <summary>
    /// 消息框代理
    /// </summary>
    public class MsgBoxProxy : UIThreadProxy<IMsgBox>, IMsgBox
    {
        #region 字段
        private string no = null;
        private string yes = null;
        private string msg = null;
        private Action noCb = null;
        private Action yesCb = null;

        public static readonly MsgBoxProxy Instance = new MsgBoxProxy();

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        private MsgBoxProxy()
        {

        }
        #endregion

        #region 私有方法
        private string GetDefaultYes(string yes)
        {
            if (yes == null) yes = Lang.Instance.GetDes(690002);
            return yes;
        }

        private string GetDefaultNo(string no)
        {
            if (no == null) no = Lang.Instance.GetDes(690003);
            return no;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public override void Update()
        {
            if (Real == null) return;
            if (no != null)
            {
                Real.Show(msg, yes, yesCb, no, noCb);
                no = yes = msg = null;
                yesCb = noCb = null;
            }
            else if (yes != null)
            {
                Real.Show(msg, yes, yesCb);
                yes = msg = null;
                yesCb = null;
            }
            CheckSetActive();
        }

        public void Show(string msg, string yes = null, Action cb = null)
        {
            yesCb = cb;
            this.msg = msg;
            this.yes = GetDefaultYes(yes);
        }

        public void Show(string msg, string yes = null, Action yesCb = null, string no = null, Action noCb = null)
        {
            this.msg = msg;
            this.noCb = noCb;
            this.yesCb = yesCb;
            this.no = GetDefaultNo(no);
            this.yes = GetDefaultNo(yes);
        }


        #region 本地化
        public void Show(uint msg, uint yes = 690002, Action cb = null)
        {
            var msgStr = Lang.Instance.GetDes(msg);
            var yesStr = Lang.Instance.GetDes(yes);
            Show(msgStr, yesStr, cb);
        }

        public void Show(uint msg, uint yes = 690002, Action yesCb = null, uint no = 690003, Action noCb = null)
        {
            var msgStr = Lang.Instance.GetDes(msg);
            var yesStr = Lang.Instance.GetDes(yes);
            var noStr = Lang.Instance.GetDes(no);

            Show(msgStr, yesStr, yesCb, noStr, noCb);
        }

        #endregion

        public override void Dispose()
        {
            base.Dispose();
            yesCb = noCb = null;
            no = yes = msg = null;
        }
        #endregion
    }
}