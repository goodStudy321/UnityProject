/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/12/14 12:27:13
 * 如果清单损坏,则在修复过程中一次将未下载的所有资源在修复过程中修复
 ============================================================================*/

using System;
using System.IO;
using UnityEngine;
using System.Threading;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    using Lang = Phantom.Localization;

    /// <summary>
    /// 资源修复
    /// </summary>
    public class AssetRepair : IStart
    {
        public enum State
        {
            /// <summary>
            /// 无
            /// </summary>
            None,

            /// <summary>
            /// 检查中
            /// </summary>
            Check,
            /// <summary>
            /// 修复清单中
            /// </summary>
            RepairMf,

            /// <summary>
            /// 修复中
            /// </summary>
            Repair,
        }

        #region 字段
        /// <summary>
        /// 检查计数
        /// </summary>
        private int checkCnt = 0;

        private bool running = false;

        private bool isInit = false;

        /// <summary>
        /// 校验文件列表长度
        /// </summary>
        private float checkLen = 0f;

        private bool isQuit = false;


        private IProgress iPro = null;

        private AssetDl dl = new AssetDl();

        private State _state = AssetRepair.State.None;

        /// <summary>
        /// 修复损坏的清单内容集合
        /// </summary>
        private Md5Set repairSet = null;


        /// <summary>
        /// 检查列表
        /// </summary>
        private List<Md5Info> checks = new List<Md5Info>();

        /// <summary>
        /// 修复列表
        /// </summary>
        private List<Md5Info> repairs = new List<Md5Info>();

        /// <summary>
        /// 检查线程列表
        /// </summary>
        private List<AssetRepairCheck> arcs = new List<AssetRepairCheck>();


        public static readonly AssetRepair Instance = new AssetRepair();
        #endregion

        #region 属性
        /// <summary>
        /// true:退出
        /// </summary>
        public bool IsQuit
        {
            get { return isQuit; }
            private set { isQuit = value; }
        }


        public bool Running
        {
            get { return running; }
            set { running = value; }
        }


        /// <summary>
        /// true:校验中
        /// </summary>
        public State state
        {
            get { return _state; }
            private set { _state = value; }
        }

        /// <summary>
        /// 进度接口
        /// </summary>
        public IProgress IPro
        {
            get { return iPro; }
            set { iPro = value; }
        }

        #endregion

        #region 委托事件
        /// <summary>
        /// 开始事件
        /// </summary>
        public event Action start = null;

        /// <summary>
        /// 结束事件,参数bool:true,代表会提示重启
        /// </summary>
        public event Action<bool> complete = null;
        #endregion

        #region 构造方法
        private AssetRepair()
        {

        }
        #endregion

        #region 私有方法
        #region 进度

        private void SetMessage(string msg)
        {
            if (iPro != null) iPro.SetMessage(msg);
        }

        private void SetMessage(uint id)
        {
            var msg = Lang.Instance.GetDes(id);
            if (iPro != null) iPro.SetMessage(msg);
        }
        #endregion

        /// <summary>
        /// 设置校验线程
        /// </summary>
        private void SetArcs()
        {
            for (int i = 0; i < 4; i++)
            {
                var arc = new AssetRepairCheck();
                arc.complete += EndCheck;
                arcs.Add(arc);
            }
        }

        /// <summary>
        /// 设置校验列表
        /// </summary>
        private void SetChecks()
        {
            if (App.IsSubAssets)
            {
                var basePath = UpgUtil.GetLocalPath(AssetMf.BaseName);
                var dic = AssetMf.Read(basePath);
                var infos = AssetMf.Infos;
                int length = infos.Count;
                var targetOp = (int)AssetOp.Verify;
                for (int i = 0; i < length; i++)
                {
                    var info = infos[i];
                    var path = info.path;
                    if (dic.ContainsKey(path))
                    {
                        checks.Add(info);
                    }
                    else if (info.Op == targetOp)
                    {
                        checks.Add(info);
                    }
                }
            }
            else
            {
                checks.AddRange(AssetMf.Infos);
            }

        }

        /// <summary>
        /// 开始校验
        /// </summary>
        private void BegCheckFirst()
        {
            SetChecks();
            BegCheck();
        }

        private void BegCheckAll()
        {
            if (checks == null) checks = new List<Md5Info>();
            checks.AddRange(AssetMf.Infos);
            BegCheck();
        }

        private void BegCheck()
        {
            checkLen = checks.Count;
            if (checks.Count < 1)
            {
                Complete(false);
                return;
            }
            checkCnt = 0;
            state = State.Check;
            int len = arcs.Count;
            for (int i = 0; i < len; i++)
            {
                var arc = arcs[i];
                arc.StartUp();
            }
        }


        /// <summary>
        /// 校验结束
        /// </summary>
        private void EndCheck()
        {
            lock (checks)
            {
                ++checkCnt;
                if (checkCnt < arcs.Count) return;
                Debug.LogWarning("Loong,AssetRepair check end");
                Thread.Sleep(5);
                BegRepair(null);
            }
        }

        /// <summary>
        /// 开始修复
        /// </summary>
        private void BegRepair(object o = null)
        {
            Debug.LogWarningFormat("Loong, beg repair, count:{0}", repairs.Count);
            Thread.Sleep(50);
            if (repairs.Count > 0)
            {
                state = State.Repair;
                dl.Infos = repairs;
                dl.Dic = AssetMf.Dic;
                dl.Start();
                dl.SetTotalNoFilter();
            }
            else
            {
                Complete(false);
            }
        }

        #region 修复清单


        /// <summary>
        /// 开始修复清单
        /// </summary>
        private void BegRepairMf()
        {
            var upgAssets = UpgMgr.Instance.UpgAssets;
            var prefix = upgAssets.SvrPrefix;
            var path = string.Format("{0}{1}/{2}", prefix, upgAssets.SvrVer, AssetMf.Name);
            if (iPro != null) iPro.Open();
            SetMessage(617006);//"修复中,请稍候"
            Debug.LogWarningFormat("Loong, BegRepairMf path:{0}", path);
            MonoEvent.Start(DownloadMf(path));
        }


        /// <summary>
        /// 下载清单
        /// </summary>
        private IEnumerator DownloadMf(string path)
        {
            state = State.RepairMf;
            var tempPath = GetTempMfPath();
            var localPath = UpgUtil.GetLocalPath(AssetMf.Name);
            using (WWW www = new WWW(path))
            {
                yield return www;
                var err = www.error;
                if (string.IsNullOrEmpty(err))
                {
                    FileTool.SafeSaveBytes(tempPath, www.bytes);
                    Debug.LogWarningFormat("Loong,download mf:{0} suc, save:{1}", path, tempPath);
                    var decomp = DecompFty.Create();
                    decomp.Src = tempPath;
                    decomp.Dest = localPath;
                    if (decomp.Execute())
                    {
                        EndRepairMf(null);
                    }
                    else
                    {
                        ShowGetMfErr();
                    }
                }
                else
                {
                    Debug.LogWarningFormat("Loong,download mf:{0},err:{1}", path, err);
                    ShowGetMfErr();

                }
            }
        }

        /// <summary>
        /// 修复清单
        /// 遍历本地(持久化)文件,已确认其是否在清单中
        /// </summary>
        private void EndRepairMf(object o)
        {
            var mfPath = UpgUtil.GetLocalPath(AssetMf.Name);
            SetMessage(617007);//"校对清单中,请稍候"
            repairSet = AssetMf.ReadSet(mfPath);
            var repairDic = AssetMf.Read(repairSet);
            AssetMf.Reset(repairDic, repairSet);
            BegCheckAll();
        }

        /// <summary>
        /// 获取缓存清单路径
        /// </summary>
        /// <returns></returns>
        private string GetTempMfPath()
        {
            var path = string.Format("{0}/{1}_{2}_{3}", AssetPath.Cache, App.VerCode, App.AssetVer, AssetMf.Name);
            return path;
        }

        /// <summary>
        /// 显示获取清单成功对话框
        /// </summary>
        private void ShowGetMfSuc()
        {
            MsgBoxProxy.Instance.Show(617010, 690000, Quit);
            //MsgBoxProxy.Instance.Show("修复成功,请重启", "确定", Quit);
        }

        /// <summary>
        /// 显示获取清单失败对话框
        /// </summary>
        private void ShowGetMfErr()
        {
            var msg = UpgUtil.GetCheckNetDes();
            MsgBoxProxy.Instance.Show(msg, 690019, BegRepairMf);
            //MsgBoxProxy.Instance.Show(msg, "重试", BegRepairMf);
        }

        /// <summary>
        /// 判断清单损坏
        /// </summary>
        /// <returns></returns>
        private bool IsDestroyMf()
        {
            var mfDic = AssetMf.Dic;
            if (mfDic == null || mfDic.Count < 1) return true;
            return false;
        }
        #endregion

        /// <summary>
        /// 显示重启对话框
        /// </summary>
        private void ShowRestart()
        {
            MsgBoxProxy.Instance.Show(617011, 690000, Quit);
            //var msg = "修复完成,请重启游戏";
            //UITip.Log(msg);
            //MsgBoxProxy.Instance.Show(msg, "确定", Quit);
        }

        private void Complete()
        {
            if (complete != null) complete(isQuit);
            Running = false;
            if (IPro != null) IPro.Close();
            MsgBoxProxy.Instance.Show(617011, 690000, Quit);
            //var msg = "修复完成,请重启游戏";
            //MsgBoxProxy.Instance.Show(msg, "确定", Quit);
            Debug.LogWarningFormat("Loong,AssetRepair complete:{0}", isQuit);
        }

        /// <summary>
        /// 直接设置完成回调
        /// </summary>
        /// <param name="quit"></param>
        private void Complete(bool quit)
        {
            IsQuit = quit;
            MonoEvent.AddOneShot(Complete);
        }


        /// <summary>
        /// 下载校验完成回调
        /// </summary>
        /// <param name="suc"></param>
        /// <param name="err"></param>
        private void Complete(bool suc, string err)
        {
            if (suc)
            {
                Debug.LogFormat("Loong, repair complete:{0}", repairs.Count);
                Complete(true);
            }
            else
            {
                Debug.LogWarning("Loong, repair failure");
                Failure();
            }
        }

        private void Failure()
        {
            var msg = UpgUtil.GetCheckNetDes();
            MsgBoxProxy.Instance.Show(msg, 690020, Quit);
            //MsgBoxProxy.Instance.Show(msg, "退出", Quit);
        }


        private void Quit()
        {
            Debug.LogFormat("Loong, AssetRepair complete,need quit,{0}", isQuit);

#if UNITY_EDITOR
            UITip.Log("已退出");
#elif UNITY_ANDROID
				
            App.Restart();
#else
            App.Quit();
#endif
        }


        private void Cancel()
        {

        }


        /// <summary>
        /// 开始时取消
        /// </summary>
        private void BegCancel()
        {
            Debug.Log("Loong, cancel AssetRepair");
        }

#if UNITY_EDITOR
        private void OnDestroy()
        {
            dl.Stop();
        }
#endif

        private void Begin()
        {
            PackDl.Instance.complete -= Begin;
            if (IsDestroyMf())
            {
                BegRepairMf();
            }
            else
            {
                BegCheckFirst();
            }
        }

        /// <summary>
        /// 设置校验进度
        /// </summary>
        /// <param name="count"></param>
        private void SetCheckPro(int count)
        {
            if (iPro == null) return;
            float val = checkLen - count;
            float pro = (val / checkLen);
            iPro.SetProgress(pro);
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void RealInit()
        {
            if (isInit) return;
            isInit = true;
            SetArcs();
            dl.IStart = this;
            dl.complte += Complete;
            dl.Url = UpgMgr.Instance.UpgAssets.SvrPrefix;
            IPro = ProgressProxy.Instance;
            dl.IPro = IPro;
            dl.Init();
            MsgBoxProxy.Instance.Refresh<UIMsgBox>("MsgBox");
            ProgressProxy.Instance.Refresh<UIEntryLoading>("UILoading");
#if UNITY_EDITOR
            MonoEvent.onDestroy += OnDestroy;
#endif
        }

        public void Reset()
        {
            checkCnt = 0;
            checkLen = 0;
            isQuit = false;
            checks.Clear();
            repairs.Clear();
        }

        public void Start()
        {
            Reset();
            if (iPro != null)
            {
                iPro.Open();
                iPro.SetProgress(0f);
            }
            SetMessage(620018);
            //SetMessage("校验中,请稍候");
            if (start != null) start();
            if (PackDl.Instance.Running)
            {
                Debug.LogWarning("Loong,call packdl stop,ready Begin");
                PackDl.Instance.complete -= Begin;
                PackDl.Instance.complete += Begin;
                PackDl.Instance.Stop();
            }
            else
            {
                Begin();
            }
        }


        public void StartUp(params object[] args)
        {
#if UNITY_EDITOR && !LOONG_TEST_UPG
            UITip.Log("环境不正确,无法修复");
#else
            if (!isInit) RealInit();
            if (Running)
            {
                UITip.Log("请稍候"); return;
            }
            MonoEvent.update -= Update;
            MonoEvent.update += Update;

            string msg = null;
            if (args == null || args.Length < 1)
            {
                msg = @"修复可能耗时较长,完成后请重新启动游戏";
            }
            else
            {
                msg = args[0].ToString();
            }
            MsgBoxProxy.Instance.Show(msg, "确定", Start, "取消", BegCancel);
#endif
        }

        public void Update()
        {
            MsgBoxProxy.Instance.Update();
            ProgressProxy.Instance.Update();
            if (_state == State.None) return;
            if (_state == State.Check)
            {
                SetCheckPro(checks.Count);
            }
            else if (_state == State.RepairMf)
            {

            }
            else if (_state == State.Repair)
            {
                dl.Update();
            }
        }

        /// <summary>
        /// 获取校验条目
        /// </summary>
        /// <returns></returns>
        public Md5Info GetCheck()
        {
            lock (checks)
            {
                var last = checks.Count - 1;
                if (last < 0) return null;
                var info = checks[last];
                checks.RemoveAt(last);
                return info;
            }
        }

        /// <summary>
        /// 添加修复信息
        /// </summary>
        /// <param name="info"></param>
        public void AddRepair(Md5Info info)
        {
            lock (repairs)
            {
                if (info == null) return;
                repairs.Add(info);
            }
        }
        public void Init()
        {
            EventMgr.Add("AssetRepairStart", StartUp);
        }
        #endregion
    }
}