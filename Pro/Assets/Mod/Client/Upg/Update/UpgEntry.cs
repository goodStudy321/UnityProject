/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.3 20:09:25
 ============================================================================*/

using System;
using Phantom;
using System.Text;
using UnityEngine;
using LuaInterface;
using Object = UnityEngine.Object;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.6.3
    /// BG:更新入口
    /// </summary>
    public class UpgEntry : IDisposable
    {
        #region 字段

        /// <summary>
        /// 进度UI游戏对象
        /// </summary>
        private GameObject proGo = null;

        /// <summary>
        /// 消息框UI游戏对象
        /// </summary>
        private GameObject boxGo = null;
        #endregion

        #region 属性

        #endregion

        #region 事件
        public event Action complete = null;

        #endregion

        #region 私有方法

        private void ExeComplete()
        {
            if (complete != null) complete();
            complete = null;
        }

        private void Complete()
        {
            iTrace.Log("Loong", "结束更新");
            ExeComplete();
        }

        private void StartUpg()
        {
            UpgMgr mgr = UpgMgr.Instance;

            mgr.complete += Complete;
            mgr.URL = GetURL();
            mgr.Init();
            mgr.Start();
        }

        /// <summary>
        /// 获取连接
        /// </summary>
        /// <returns></returns>
        private string GetURL()
        {
            string release = null;
            if (App.IsReleaseDebug)
            {
                release = "Release";
            }
            else
            {
                release = (App.IsDebug ? "Debug" : "Release");
            }
            var sb = new StringBuilder();
            sb.Append(UpgUtil.URL);
            sb.Append(App.Info.GFlag);
            sb.Append("/").Append(release);
            string ip = sb.ToString();
            return ip;
        }

        /// <summary>
        /// 设置进度接口
        /// </summary>
        /// <param name="go">游戏对象</param>
        /// <param name="at">激活状态</param>
        private void SetIPro(GameObject go, bool at)
        {
            var loading = new UIExLoading();
            loading.Init(go);
            proGo.SetActive(at);
            ProgressProxy.Instance.Real = loading;
        }

        private void SetMsgBox(GameObject go, bool at)
        {
            var box = new UIMsgBox();
            box.Init(go);
            MsgBoxProxy.Instance.Real = box;
        }

        private GameObject SetUI(Object obj)
        {
            GameObject go = GameObject.Instantiate(obj) as GameObject;
            TransTool.AddChild(UIMgr.Root, go.transform);
            go.name = obj.name;
            return go;
        }

        private void LoadMsgBoxCb(Object obj)
        {
            var go = SetUI(obj);
            SetMsgBox(go, false);
            go.SetActive(false);
            iTool.Destroy(boxGo);
        }

        /// <summary>
        /// 加载进度条资源包回调
        /// </summary>
        /// <param name="obj"></param>
        private void LoadLoadingCb(Object obj)
        {
            var go = SetUI(obj);
            SetIPro(go, true);
            iTool.Destroy(proGo);
        }

        /// <summary>
        /// 加载所有资源结束
        /// </summary>
        private void LoadComplete()
        {
            AssetMgr.Instance.complete -= LoadComplete;
            StartUpg();
        }

        /// <summary>
        /// 设置进度属性
        /// </summary>
        private void SetProp()
        {
            /*if (AssetPath.ExistInPersistent)
            {
                var am = AssetMgr.Instance;
                string sfx = Suffix.Prefab;
                am.Add(UIName.MsgBox, sfx, LoadMsgBoxCb);
                am.Add(UIName.UILoading, sfx, LoadLoadingCb);
                am.complete += LoadComplete;
                am.Start();
            }
            else */
            if (proGo == null)
            {
                iTrace.Error("Loong", "入口无UI节点:UI Root/UILoading");
            }
            else if (boxGo == null)
            {
                iTrace.Error("Loong", "入口无UI节点:UI Root/MsgBox");
            }
            else
            {
                SetIPro(proGo, true);
                SetMsgBox(boxGo, false);
                StartUpg();
            }
        }

        /*private void OnGUI()
        {
            if (GUILayout.Button("暂停"))
            {
                UpgradeMgr.Instance.Pause();
            }
            else if (GUILayout.Button("恢复"))
            {
                UpgradeMgr.Instance.Resume();
            }
            else if (GUILayout.Button("yes"))
            {
                MessageBox.Show("yes?", "Yes", ClickYes);
            }
            else if (GUILayout.Button("yes no"))
            {
                MessageBox.Show("yes no?", "Yes", ClickYes, "No", ClickNo);
            }
            else if (GUILayout.Button("yes no cancel"))
            {
                MessageBox.Show("yes no cancel?", "Yes", ClickYes, "No", ClickNo, "Cancel", ClickCancel);
            }
        }

        private void ClickNo()
        {
            iTrace.Log("Loong", "no");
        }
        private void ClickYes()
        {
            iTrace.Log("Loong", "yes");
        }
        private void ClickCancel()
        {
            iTrace.Log("Loong", "cancel");
        }*/
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void Init()
        {
            var root = GameObject.Find("UI Root");
            if (root == null) return;
            var des = this.GetType().Name;
            boxGo = TransTool.Find(root, "MsgBox", des);
            proGo = TransTool.Find(root, "UILoading", des);
            if (boxGo != null) boxGo.SetActive(false);
        }

        public void Start()
        {
#if LOONG_USE_ZIP
            SetProp();
#else
            Dispose();
            ExeComplete();
#endif
        }

        public void Dispose()
        {
            iTool.Destroy(proGo);
            iTool.Destroy(boxGo);
        }
        #endregion
    }
}