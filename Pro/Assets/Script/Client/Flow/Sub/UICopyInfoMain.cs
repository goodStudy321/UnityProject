//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/5/10 10:33:51
//=============================================================================

using System;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Phantom
{
    /// <summary>
    /// UICopyInfoMain
    /// </summary>
    public class UICopyInfoMain : IModule
    {
        #region 字段
        private int oriLeft = 0;

        private int oriRight = 0;

        /// <summary>
        /// 根节点
        /// </summary>
        private Transform root = null;

        /// <summary>
        /// 数据
        /// </summary>
        private UICopyMainInfoData data = null;

        private UIWidget leftWidget = null;

        private UILabel titleLbl = null;

        private UILabel targetLbl = null;

        private UILabel unlockLbl = null;

        private UILabel exeLbl = null;

        private UITexture iconTex = null;

        private string iconName = null;

        public const string PrefabName = "UICopyInfoMain";

        public static readonly UICopyInfoMain Instance = new UICopyInfoMain();

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        private UICopyInfoMain()
        {

        }
        #endregion

        #region 私有方法
        private void SetIcon(Object o)
        {
            var tex = o as Texture2D;
            iconTex.mainTexture = tex;
        }

        private void LoadCb(GameObject go)
        {
            if (go == null)
            {
                return;
            }
            root = go.transform;
            TransTool.AddChild(UIMgr.Cam.transform, root);
            var des = PrefabName;
            leftWidget = ComTool.Get<UIWidget>(root, "Left", des);

            if (oriLeft == 0 && oriRight == 0)
            {
                oriLeft = leftWidget.leftAnchor.absolute;
                oriRight = leftWidget.rightAnchor.absolute;
            }

            var leftTran = leftWidget.transform;
            titleLbl = ComTool.Get<UILabel>(leftTran, "Name", des);
            targetLbl = ComTool.Get<UILabel>(leftTran, "Target", des);
            unlockLbl = ComTool.Get<UILabel>(leftTran, "Lab_2", des);
            exeLbl = ComTool.Get<UILabel>(leftTran, "exe/Label", des);
            iconTex = ComTool.Get<UITexture>(leftTran, "Icon", des);
            UITool.SetBtnClick(leftTran, "exe", des, OnClickExe);
            ScreenUtil.change += ScreenChange;
            ScreenChange(ScreenUtil.Orient);
            SetData();
        }

        private void ScreenChange(ScreenOrientation orient)
        {
            var reset = (orient == ScreenOrientation.LandscapeRight);
            UITool.SetLiuHaiAbsolute(leftWidget, reset, oriLeft, oriRight);
        }


        private void OnClickExe()
        {
            HangupMgr.instance.IsAutoHangup = true;
            EventMgr.Trigger("ExcuteMission", 1);
        }

        private void SetData()
        {
            titleLbl.text = Localization.Instance.GetDes(data.titleID);
            targetLbl.text = Localization.Instance.GetDes(data.targetID);
            var md = User.instance.MapData;
            var sex = (md == null ? 0 : md.Sex);
            exeLbl.text = Localization.Instance.GetDes(617036);
            unlockLbl.text = (sex == 1 ? Localization.Instance.GetDes(data.manUnlockID) : Localization.Instance.GetDes(data.womanUnlockID));
            var newIconName = (sex == 1 ? data.manIcon : data.womanIcon);
            if (iconName != newIconName)
            {
                UnloadTex();
                iconName = newIconName;
                AssetMgr.Instance.Load(newIconName, SetIcon);
            }
            SetMainmenuLeftActive(0);
        }

        /// <summary>
        /// 设置主界面左侧面板激活状态
        /// </summary>
        /// <param name="active">0:关闭,1激活</param>
        private void SetMainmenuLeftActive(int active)
        {
            EventMgr.Trigger("UIMainmenuLeftSetActive", active);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void Init()
        {

        }

        public void Open(UICopyMainInfoData db)
        {
            data = db;
            if (root == null)
            {
                AssetMgr.LoadPrefab(PrefabName, LoadCb);
            }
            else
            {
                SetData();
            }
        }


        public void Close()
        {
            SetMainmenuLeftActive(1);
            if (root != null)
            {
                ScreenUtil.change -= ScreenChange;
                GbjPool.Instance.Add(root.gameObject);
            }
            root = null;
        }

        public void UnloadTex()
        {
            if (iconName != null) AssetMgr.Instance.Unload(iconName);
            iconName = null;
        }

        public void Preload()
        {
            PreloadMgr.prefab.Add(PrefabName);
        }


        public void BegChgScene()
        {

        }

        public void EndChgScene()
        {

        }

        public void Clear(bool reconnect)
        {
            Close();
        }


        public void Dispose()
        {

        }

        public void LocalChanged()
        {
            //TODO
        }
        #endregion
    }
}