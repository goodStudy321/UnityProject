using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Loong.Game
{

    /// <summary>
    /// AU:Loong
    /// TM:2015.10.13
    /// BG:名称头顶显示基类
    /// </summary>
    public abstract class NameBarBase : TopBarBase
    {
        #region 字段
        private string name = "";

        private string title = "";

        private int titleId = 0;

        protected UILabel nameLbl = null;
        protected UILabel titleLbl = null;


        protected GameObject titlePrefab = null;

        protected UILabel timeLbl = null;
        #endregion

        #region 属性
        /// <summary>
        /// 名称 在下
        /// </summary>
        public string Name
        {
            get { return name; }
            set
            {
                name = value;
                SetText(nameLbl, name);
            }
        }

        /// <summary>
        /// 名称 
        /// </summary>
        public UILabel NameLab
        {
            get { return nameLbl; }
        }

        /// <summary>
        /// 称号 在上
        /// </summary>
        public string Title
        {
            get { return title; }
            set
            {
                title = value;
                SetText(titleLbl, title);
            }
        }

        /// <summary>
        /// 头顶时间 在名称下
        /// </summary>
        public string TimeStr
        {
            set { SetText(timeLbl, value); }
        }

        /// <summary>
        /// 称号Prefab
        /// </summary>
        public int TitleId
        {
            get { return titleId; }
            set
            {
                titleId = value;
                SetTitle(titleId);
            }
        }

        #endregion

        #region 构造方法
        public NameBarBase()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法


        protected override void LoadCallback(GameObject go)
        {
            transform = go.transform;
            transform.parent = SymbolMgr.Root;
            SetProperty();
            SetText(nameLbl, name);
            SetText(titleLbl, title);
            SetTitle(titleId);
            go.SetActive(true);
        }

        /// <summary>
        /// 设置名称
        /// </summary>
        protected void SetText(UILabel label, string text)
        {
            if (label == null) return;
            label.text = text;
            bool off = string.IsNullOrEmpty(text);
            label.gameObject.SetActive(!off);
            SetRootPos();
        }

        /// <summary>
        /// 设置称号
        /// </summary>
        /// <param name="texture"></param>
        /// <param name="texTitle"></param>
        protected void SetTitle(int titleId)
        {
            string name = UnitHelper.instance.GetTitleTexture((uint)titleId);
            if (string.IsNullOrEmpty(name))
            {
                GbjPool.Instance.Add(titlePrefab);
                titlePrefab = null;
                return;
            }
            name = QualityMgr.instance.GetQuaEffName(name);
            GameObject go = GbjPool.Instance.Get(name);
            if (go != null)
            {
                SetTitle(go);
            }
            else
            { 
                AssetMgr.LoadPrefab(name, LoadTitleCb);
             }
        }

        private void LoadTitleCb(GameObject go)
        {
            AssetMgr.Instance.SetPersist(go.name + Suffix.Prefab);  
            SetTitle(go);
        }

        private void SetTitle(GameObject go)
        {
            if (BarName == TopBarFty.OtherPlayerBarStr)
            {
                go.SetActive(User.instance.IsShowTitle);
            }
            GbjPool.Instance.Add(titlePrefab);
            titlePrefab = go;
            go.transform.SetParent(transform);
            go.transform.localScale = Vector3.one; 
            //go.transform.localPosition = new Vector3(0, 0.6f, 0);
            go.transform.localRotation = Quaternion.identity;
            go.SetActive(true);
            SetRootPos();
        }



        protected void SetTitlePos(Vector3 pos, float offset = 0)
        {
            if (titlePrefab == null) return;
            if(offset == 0)
            {
                titlePrefab.transform.localPosition = new Vector3(0, 0.6f, 0);
            }
            else
            {
                pos.y += offset + 0.6f;
                titlePrefab.transform.localPosition = pos;
            }
        }

        /// <summary>
        /// 设置属性
        /// </summary>
        protected abstract void SetProperty();

        protected virtual void SetRootPos() { }
        #endregion

        #region 公开方法



        public override void Dispose()
        {
            base.Dispose();
            timeLbl = null;
            nameLbl = null;
            titleLbl = null;
            name = "";
            title = "";
            if (titlePrefab != null)
            {
                GameObject.Destroy(titlePrefab);
                titlePrefab = null;
            }
        }

        /// <summary>
        /// 改变称号状态
        /// </summary>
        /// <param name="state"></param>
        public void ChgTitleState(bool state)
        {
            if (titlePrefab != null)
            {
                titlePrefab.SetActive(state);
            }
        }


        #endregion
    }
}