/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2015.8.1 17:58:37
 ============================================================================*/

using System;
using UnityEngine;


namespace Loong.Game
{

    using Lang = Phantom.Localization;

    /// <summary>
    /// AU:Loong
    /// TM:2016.7.12
    /// BG:消息框
    /// </summary>
    public class UIMsgBox : IMsgBox
    {
        #region 字段
        private GameObject go = null;

        private float btnWidth = 0;

        private UISprite bg = null;

        private UILabel msgLbl = null;

        private UIButton noBtn = null;

        private UILabel noLbl = null;

        private UIButton yesBtn = null;

        private UILabel yesLbl = null;

        private UILabel titleLbl = null;

        private Action noCb = null;

        private Action yesCb = null;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void OnClickNo()
        {
            Close();
            if (noCb == null) return;
            noCb(); noCb = null;
        }

        private void OnClickYes()
        {
            Close();
            if (yesCb == null) return;
            yesCb(); yesCb = null;
        }

        private void SetYesPos()
        {
            Vector3 pos = bg.transform.localPosition;
            pos.Set(pos.x, yesBtn.transform.localPosition.y, 0);
            pos.x -= btnWidth * 0.05f;
            yesBtn.transform.localPosition = pos;
        }

        private void SetYesNoPos()
        {
            float interval = (bg.width - btnWidth * 2) / 3;
            Vector3 pos = bg.transform.localPosition;
            pos.Set(pos.x, yesBtn.transform.localPosition.y, 0);
            float offset = (btnWidth + interval) * 0.5f;
            pos.x -= offset;
            yesBtn.transform.localPosition = pos;

            pos.x = bg.transform.position.x;
            pos.x += offset;
            noBtn.transform.localPosition = pos;
        }

        private string GetDefaultYes(string val)
        {
            if (val == null)
            {
                val = Lang.Instance.GetDes(690002);
            }
            return val;
        }

        private string GetDefaultNo(string val)
        {
            if (val == null)
            {
                val = Lang.Instance.GetDes(690003);
            }
            return val;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void Init(GameObject go)
        {
            this.go = go;
            var root = go.transform;
            string msg = this.GetType().Name;
            bg = ComTool.Get<UISprite>(root, "bg", msg);
            msgLbl = ComTool.Get<UILabel>(root, "msg", msg);
            noBtn = ComTool.Get<UIButton>(root, "bg/noBtn", msg);
            noLbl = ComTool.Get<UILabel>(root, "bg/noBtn/Label", msg);
            yesBtn = ComTool.Get<UIButton>(root, "bg/yesBtn", msg);
            yesLbl = ComTool.Get<UILabel>(root, "bg/yesBtn/Label", msg);
            titleLbl = ComTool.Get<UILabel>(root, "title", msg);
            var yesSprite = yesBtn.GetComponent<UISprite>();
            if (yesSprite != null) btnWidth = yesSprite.width;
            var closeTran = root.Find("CloseBtn");
            if (closeTran != null) closeTran.gameObject.SetActive(false);
            EventDelegate.Add(noBtn.onClick, OnClickNo);
            EventDelegate.Add(yesBtn.onClick, OnClickYes);
            titleLbl.text = Lang.Instance.GetDes(690035);
        }

        public void Open()
        {
            go.SetActive(true);
        }

        public void Close()
        {
            go.SetActive(false);
        }

        public void Show(string msg, string yes = null, Action cb = null)
        {
            SetYesPos();
            yesCb = cb;
            yesLbl.text = GetDefaultYes(yes);
            msgLbl.text = msg;
            noBtn.gameObject.SetActive(false);
            yesBtn.gameObject.SetActive(true);
            Open();
        }

        public void Show(string msg, string yes = null, Action yesCb = null, string no = null, Action noCb = null)
        {
            SetYesNoPos();
            noLbl.text = GetDefaultNo(no);
            yesLbl.text = GetDefaultYes(yes);
            msgLbl.text = msg;
            this.noCb = noCb;
            this.yesCb = yesCb;
            noBtn.gameObject.SetActive(true);
            yesBtn.gameObject.SetActive(true);
            Open();
        }

        public void Dispose()
        {
            if (go != null)
            {
                GameObject.DestroyImmediate(go);
            }
        }
        #endregion
    }
}