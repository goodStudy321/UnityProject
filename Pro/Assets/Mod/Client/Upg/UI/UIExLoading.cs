using UnityEngine;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.Networking;

namespace Loong.Game
{


    public class UIExLoading : UIEntryLoading
    {
        #region 字段
        private int idx = 1;

        private int desIdx = 0;

        private float tm = 0;

        private bool forward = true;

        protected UILabel des = null;

        protected UILabel title = null;

        protected UILabel percent = null;

        protected UITexture bg2 = null;

        protected TweenAlpha tweenBg1 = null;

        protected TweenAlpha tweenBg2 = null;


        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void Register()
        {
            Table.NewHelper.Clear();
            Table.NewHelper.Register(typeof(InitDesCfg), NewCfg);
        }

        private object NewCfg()
        {
            return new InitDesCfg();
        }

        private void ReadCfg()
        {
            Register();
            var path = string.Format("Tmp/{0}/{1}", FileLoader.Home, InitDesCfgManager.instance.source);
            var src = Path.Combine(AssetPath.WwwStreaming, path);
            using (var www = UnityWebRequest.Get(src))
            {
                www.SendWebRequest();
                while (!www.isDone) continue;
                if (www.isHttpError || www.isNetworkError)
                {
                    var err = www.error;
                    iTrace.Error("Loong", "加载初始化文本异常:{0}", err);
                }
                else
                {
                    var buf = www.downloadHandler.data;
                    InitDesCfgManager.instance.Load(buf);
                }
            }
        }


        private void Update()
        {
            tm += Time.unscaledDeltaTime;
            if (tm > 4)
            {
                tm = 0;
                var texName = string.Format("loading_{0}.jpg", idx);
                if (dic.ContainsKey(texName))
                {
                    var tex = dic[texName];
                    SetBg(tex);
                }
                else
                {
                    MonoEvent.Start(SetBg(texName));
                }
                ++idx;
                if (idx > 4)
                {
                    idx = 1;
                }

                SetDes();
            }
        }

        private void SetBg(Texture2D tex)
        {
            if (tex == null) tex = TexTool.Black;
            if (forward)
            {
                bg2.mainTexture = tex;
                if (tweenBg1 != null) tweenBg1.PlayReverse();
                if (tweenBg2 != null) tweenBg2.PlayForward();
            }
            else
            {
                bg.mainTexture = tex;
                if (tweenBg1 != null) tweenBg1.PlayForward();
                if (tweenBg2 != null) tweenBg2.PlayReverse();
            }
            forward = !forward;
        }

        private void SetDes()
        {
            if (desIdx >= InitDesCfgManager.instance.Size)
            {
                desIdx = 0;
            }
            var cfg = InitDesCfgManager.instance.Get(desIdx);
            if (des != null)
            {
                des.text = cfg.des;
            }
            if (title != null)
            {
                title.text = cfg.title;
            }

            ++desIdx;

        }

        private IEnumerator SetBg(string name)
        {
            string fullPath = prefix + name;
            using (UnityWebRequest request = UnityWebRequest.Get(fullPath))
            {
                DownloadHandlerTexture dlhTex = new DownloadHandlerTexture();
                request.downloadHandler = dlhTex;
                yield return request.SendWebRequest();
                string err = request.error;
                if (string.IsNullOrEmpty(err))
                {
                    var tex = dlhTex.texture;
                    tex.name = "cs_" + Path.GetFileName(name);
                    SetBg(tex);
                    if (!dic.ContainsKey(name))
                    {
                        dic.Add(name, tex);
                    }
                }
                else
                {
                    iTrace.Error("Loong", "load:{0},err:{1}", name, err);
                    bg.mainTexture = TexTool.Black;
                }

            }
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override void Init(GameObject go)
        {
            base.Init(go);
            var root = go.transform;
            var name = this.GetType().Name;
            des = ComTool.Get<UILabel>(root, "des/des", name);
            title = ComTool.Get<UILabel>(root, "des/title", name);
            bg2 = ComTool.Get<UITexture>(root, "bg2", name);
            if (bg2 == null) return;
            tweenBg1 = ComTool.Get<TweenAlpha>(root, "bg", name);
            tweenBg2 = ComTool.Get<TweenAlpha>(root, "bg2", name);
            percent = ComTool.Get<UILabel>(root, "p", name);
            MonoEvent.update += Update;
            ReadCfg();
            SetDes();
        }

        public override void Dispose()
        {
            base.Dispose();
            MonoEvent.update -= Update;
        }


        public override void SetProgress(float value)
        {
            base.SetProgress(value);
            if (percent == null) return;
            var v = value * 100;
            var iv = Mathf.FloorToInt(v);
            percent.text = string.Format("{0}%", iv);
        }

        #endregion

    }
}
