/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2017/5/19, 11:42:19
 ============================================================================*/

using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.Networking;

namespace Loong.Game
{
    using TexDic = Dictionary<string, Texture2D>;
    /// <summary>
    /// 入口进度
    /// </summary>
    public class UIEntryLoading : IProgress
    {
        #region 字段

        private UILabel tipLbl = null;

        private UILabel msgLbl = null;

        private UISprite slider = null;

        private GameObject go = null;

        protected UITexture bg = null;

        protected string prefix = null;

        protected TexDic dic = new TexDic();
        #endregion

        #region 属性

        /// <summary>
        /// 
        /// </summary>
        public GameObject Go
        {
            get { return go; }
            set { go = value; }
        }

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private IEnumerator SetBg()
        {
            string bgName = "loading_1.jpg";
            string fullPath = prefix + bgName;
            using (UnityWebRequest request = UnityWebRequest.Get(fullPath))
            {
                DownloadHandlerTexture dlhTex = new DownloadHandlerTexture();
                request.downloadHandler = dlhTex;
                yield return request.SendWebRequest();
                string err = request.error;
                if (string.IsNullOrEmpty(err))
                {
                    var tex = dlhTex.texture;
                    tex.name = "cs_" + bgName;
                    bg.mainTexture = tex;
                    dic.Add(bgName, tex);
                }
                else
                {
                    iTrace.Error("Loong", "load:{0},err:{1}", bgName, err);
                    bg.mainTexture = TexTool.Black;
                }
            }
        }
        #endregion

        #region 保护方法


        #endregion

        #region 公开方法
        public virtual void Init(GameObject go)
        {
            this.go = go;
            prefix = AssetPath.WwwStreaming + "chg/";
            string msg = this.GetType().Name;
            var root = go.transform;
            bg = ComTool.Get<UITexture>(root, "bg", msg);
            tipLbl = ComTool.Get<UILabel>(root, "tip", msg);
            msgLbl = ComTool.Get<UILabel>(root, "msg", msg);
            slider = ComTool.Get<UISprite>(root, "sliderFg", msg);
            MonoEvent.Start(SetBg());
            SetProgress(0);
        }

        public void Open()
        {
            if (go != null) go.SetActive(true);
        }

        public void Close()
        {
            if (go != null) go.SetActive(false);
        }
        /// <summary>
        /// 设置进度
        /// </summary>
        /// <param name="value"></param>
        public virtual void SetProgress(float value)
        {
            if (slider == null) return;
            if (value > 0.96f) slider.fillAmount = value;
            else if (value < 0.04f) slider.fillAmount = value;
            else slider.fillAmount = Mathf.Lerp(slider.fillAmount, value, Time.unscaledDeltaTime * 10);
        }

        /// <summary>
        /// 设置信息
        /// </summary>
        /// <param name="value"></param>
        public void SetMessage(string value)
        {
            if (msgLbl != null) msgLbl.text = value;
        }

        public void SetTip(string value)
        {
            if (tipLbl != null) tipLbl.text = value;
        }


        public void SetTotal(string size, int total)
        {

        }

        public void SetCount(int count)
        {

        }


        public virtual void Dispose()
        {
            var em = dic.GetEnumerator();
            while (em.MoveNext())
            {
                var tex = em.Current.Value;
                if (tex == null) continue;
                try
                {
                    Object.DestroyImmediate(tex);
                }
                catch (System.Exception)
                {
                }
            }
            dic.Clear();
            if (Go == null) return;
            iTool.Destroy(Go);
        }
        #endregion
    }
}