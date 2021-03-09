/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/8/3 17:18:23
 ============================================================================*/

using System;
using System.IO;
using UnityEngine;
using System.Threading;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    using NRB = NetworkReachability;
    using Lang = Phantom.Localization;

    /// <summary>
    /// 分包下载
    /// </summary>
    public class PackDl : IStart
    {
        #region 字段

        private int begLv = 0;

        private long speed = 0;

        private bool netChg = false;

        private bool inited = false;

        private bool isOver = false;

        private bool isStop = false;

        private bool isQuiet = false;

        private bool running = false;

        private Thread thread = null;

        /// <summary>
        /// true:需要重新启动
        /// </summary>
        private bool reStartUp = false;

        private string packPath = null;

        private IProgress iPro = null;

        private AssetDl dl = new AssetDl();

        private PackCtrl ctrl = new PackCtrl();


        private List<Md5Info> infos = new List<Md5Info>();

        public const string FileName = "Pack.txt";

        public static readonly PackDl Instance = new PackDl();
        #endregion

        #region 属性

        /// <summary>
        /// 当前玩家等级
        /// </summary>
        public int Lv
        {
            get
            {
                var data = User.instance.MapData;
                return (data == null) ? 0 : data.Level;
            }
        }

        /// <summary>
        /// 开始检查等级
        /// </summary>
        public int BegLv
        {
            get { return begLv; }
            set { begLv = value; }
        }


        /// <summary>
        /// true:分包已经完成
        /// </summary>
        public bool IsOver
        {
            get { return isOver; }
            set { isOver = value; }
        }


        /// <summary>
        /// 停止
        /// </summary>
        public bool IsStop
        {
            get { return isStop; }
            private set { isStop = value; }
        }

        /// <summary>
        /// true:静默模式
        /// </summary>
        public bool IsQuiet
        {
            get { return isQuiet; }
            private set { isQuiet = value; }
        }

        /// <summary>
        /// true:运行中
        /// </summary>
        public bool Running
        {
            get { return running; }
            private set { running = value; }
        }


        public string PackPath
        {
            get
            {
                if (packPath == null)
                {
                    packPath = string.Format("{0}/{1}", AssetPath.Persistent, FileName);
                }
                return packPath;
            }
        }
        #endregion

        #region 委托事件
        /// <summary>
        /// 分包下载结束事件
        /// </summary>
        public event Action complete = null;

        #endregion

        #region 构造方法
        private PackDl()
        {

        }
        #endregion

        #region 私有方法

        private void OnPause(bool pause)
        {
            if (pause) return;
            if (!isQuiet) return;
            if (!running) return;
            if (thread == null) return;
            var ts = thread.ThreadState;
            if (ts == ThreadState.Running) return;
            if (ts == ThreadState.Background) return;
            if (File.Exists(PackPath)) return;
            Debug.LogFormat("Loong, 分包线程已被挂起,线程状态:{0},重新开始", ts);
            running = false;
            Run();
        }

        private void SetMsg(string msg)
        {
            if (isQuiet) return;
            if (iPro == null) return;
            iPro.SetMessage(msg);
        }
        
        private void SetMsg(uint id)
        {
            var msg = Lang.Instance.GetDes(id);
            SetMsg(msg);
        }

        private void SetCtrl()
        {
            dl.downloaded += Downloaded;
            iPro = ProgressProxy.Instance;
            dl.IPro = iPro;
        }

        /// <summary>
        /// 设置下载速度
        /// </summary>
        private bool SetSpeed()
        {
            if (isQuiet)
            {
                if (speed < 1 || netChg)
                {
#if LOONG_ENABLE_UPG
                    var url = UpgUtil.Host + "TestSpeed.txt";
                    //测试通过下载得到的真实网速
                    speed = NetUtil.Speed(url);
#endif
                }
                //最小协议速度
                var minPKps = 128 * 1024;
                //最小下载速度
                var minDlKbs = 64 * 1024;
                var maxDlKbs = 2 * 1024 * 1024;
                //设置下载速度
                long dlKbs = speed - minPKps;
                //下载速度下限判断
                var rdlKbs = ((dlKbs < minDlKbs) ? minDlKbs : dlKbs);
                rdlKbs = ((rdlKbs) > maxDlKbs ? maxDlKbs : rdlKbs);

                //设置下载速度
                dl.Dl.Limit = rdlKbs;
                var kbs = ByteUtil.GetKB(rdlKbs);
                var msg = string.Format("Loong, speed:{0} ,set maxspeed:{1},kbs:{2}", speed, rdlKbs, kbs);
                Debug.LogWarning(msg);
                return speed > 1;
            }
            else
            {
                dl.Dl.Limit = 0;
                return true;
            }
        }

        /// <summary>
        /// 重新启动
        /// </summary>
        private void Restart()
        {
            Debug.LogWarning("Loong, pack ready Restart");
            if (running) return;
            if (IsStop) return;
            Thread.Sleep(5000);
            Debug.LogWarning("Loong, pack beg Restart");
            if (running) return;
            if (IsStop) return;
            if (NetObserver.NoNet())
            {
                Restart();
            }
            else
            {
                Start();
            }
        }

        /// <summary>
        /// 网络发生改变
        /// </summary>
        private void NetChg(NRB last, NRB cur)
        {
            netChg = true;
        }

        /// <summary>
        /// 检查网络
        /// </summary>
        private void ChkNet()
        {
            var msgBox = MsgBoxProxy.Instance;
            if (NetObserver.NoNet())
            {
                msgBox.Show(617019, 690000, ChkNet, 690020, Quit);
                //var msg = "无网络";
                //msgBox.Show(msg, "确定", ChkNet, "退出", Quit);
            }
            if (NetObserver.IsCarrier())
            {
                msgBox.Show(617020, 690000, Start, 690020, Quit);
                //string msg = "继续将消耗流量";
                //msgBox.Show(msg, "确定", Start, "退出", Quit);
            }
            else
            {
                Start();
            }
        }

        private void Complete()
        {
            if (complete != null) complete();
            AssetMf.StopWatch();
            EventMgr.Trigger("PackDlComplete");
            Debug.LogWarning("Loong, PackDL Complete event");
        }

        private void Complete(bool suc, string err)
        {
            Running = false;
            if (IsStop)
            {
                Debug.LogWarning("Loong, packdl stoped");
                if (reStartUp)
                {
                    Debug.LogWarning("Loong, packdl reStartUp");
                    StartUp();
                }
                else
                {
                    MonoEvent.AddOneShot(Complete);
                }
            }
            else if (suc)
            {
                if (isQuiet)
                {
                    Debug.LogWarning("Loong, all pack complete");
                    FileTool.SafeSave(PackPath, App.VerCode.ToString());
                    IsOver = true;
                    MonoEvent.AddOneShot(Complete);
#if UNITY_IOS || UNITY_IPHONE
                    //MonoEvent.onPause -= OnPause;
#endif
                }
                else
                {
                    Thread.Sleep(20);
                    SetMsg(617021);
                    //SetMsg("下载完成");
                    Thread.Sleep(20);
                    Debug.Log("Loong, end pack suc");
                    IsQuiet = true;
                    BegLv = AssetMf.GetNext(Lv);
                    Run();
                }
            }
            else
            {
                if (string.IsNullOrEmpty(err)) err = "download fail";
                Debug.LogWarningFormat("Loong, end pack fail{0}:", err);
                if (isQuiet)
                {
                    Restart();
                }
                else
                {
                    var b1 = Lang.Instance.GetDes(690019);
                    var b2 = Lang.Instance.GetDes(690020);

                    MsgBoxProxy.Instance.Show(err, b1, Start, b2, Quit);
                    //MsgBoxProxy.Instance.Show(err, "重试", Start, "退出", Quit);
                }
            }
        }

        /// <summary>
        /// 启动线程下载
        /// </summary>
        private void Run()
        {
            if (ThreadUtil.IsMain)
            {

                /*#if UNITY_IOS || UNITY_IHONE
                                thread = new Thread(new ThreadStart(Begin));
                                thread.IsBackground = true;
                                thread.Start();
#else*/
                if (!ThreadPool.QueueUserWorkItem(Begin))
                {
                    Thread.Sleep(1);
                    Run();
                }
                /*#endif*/
            }
            else
            {
                Begin();
            }
        }

        private void Begin(object obj)
        {
            Begin();
        }

        private void SetSleep()
        {
            var dlSleep = 25;
            var vdSleep = 25;
            var vdDecompSleep = 25;
            var cfg = GlobalDataManager.instance.Find(162);
            if (cfg != null)
            {
                var lst = cfg.num2.list;
                var len = lst.Count;
                if (len > 0) dlSleep = (int)lst[0];
                if (len > 1) vdSleep = (int)lst[1];
                if (len > 2) vdDecompSleep = (int)lst[2];

            }
            dl.Sleep = dlSleep;
            dl.VD.Sleep = vdSleep;
            dl.VD.DecompSleep = vdDecompSleep;
            if (App.IsDebug || App.IsEditor)
            {
                Debug.LogWarningFormat("Loong, Packdl sleep{0}, vdSleep:{1}, vdDecompSleep:{2}", dlSleep, vdSleep, vdDecompSleep);
            }
        }

        private void Downloaded()
        {
            ctrl.Downloaded();
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public void Init()
        {
            if (inited) return;
            inited = true;
            dl.IStart = this;
            SetSleep();
            dl.complte += Complete;
            dl.VD.UseVerify = App.IsDebug;
            dl.Url = UpgMgr.Instance.UpgAssets.SvrPrefix;
            ctrl.Init();
            SetCtrl();
            dl.Init();
            NetObserver.change += NetChg;
            //EventMgr.Add("LogoutSuc", Stop);
            EventMgr.Add("packdl_tip", ShowTip);
            MonoEvent.update += Update;
#if UNITY_EDITOR
            MonoEvent.onDestroy += Stop;
#endif
#if UNITY_IOS || UNITY_IPHONE
           /* MonoEvent.onPause -= OnPause;
            MonoEvent.onPause += OnPause;*/
#endif
        }

        public void Quit()
        {
            App.Quit();
        }

        /// <summary>
        /// 通过当前等级判断是否可以静默下载
        /// </summary>
        /// <param name="cur"></param>
        /// <returns></returns>
        public bool Quiet(int cur)
        {
            if (cur < AssetMf.MinLv) return true;
            return false;
        }

        /// <summary>
        /// 根据当前等级启动下载
        /// </summary>
        public void Start()
        {
            if (!isQuiet)
            {
                if (iPro != null) iPro.Open();
            }
            Run();
        }

        /// <summary>
        /// 开始
        /// </summary>
        public void Begin()
        {
            if (running) return;
            thread = Thread.CurrentThread;
            IsStop = false;
            Running = true;
            if (!SetSpeed())
            {
                if (reStartUp)
                {
                    StartUp();
                }
                else
                {
                    Restart();
                }
            }
            else
            {
                SetMsg(617022);
                //SetMsg("校验文件中,请稍候···");
                Debug.LogWarning("Loong, pack beg chk manifest");
                AssetMf.SetInfos(BegLv, infos, IsQuiet);
                AssetMf.IsStop = false;
                Debug.LogWarning("Loong, pack end  chk manifest");
                if (isStop)
                {
                    Debug.LogWarning("Loong, packdl SetInfo stoped");
                    Running = false;
                    if (reStartUp)
                    {
                        StartUp();
                    }
                }
                else if (reStartUp)
                {
                    StartUp();
                }
                else if (infos.Count < 1)
                {
                    Complete(true, null);
                }
                else
                {
                    Debug.LogWarning("Loong, pack beg");
                    dl.Infos = infos;
                    dl.Dic = AssetMf.Dic;
                    dl.Start();
                }
            }
        }

        /// <summary>
        /// 启动
        /// 返回true:已下载完成或后台下载
        /// 返回false:1,弹出对话框,进行下载,2:等待停止完成
        /// </summary>
        /// <returns></returns>
        public bool StartUp()
        {
            if (App.IsDebug)
            {
                return true;
            }
            Init();
            IsOver = IsOverByFile();
            if (IsOver)
            {
                Debug.Log("Loong, pack dl isOver");
                return true;
            }
            var mfDic = AssetMf.Dic;
            if (mfDic == null || mfDic.Count < 1)
            {
                Debug.LogWarning("Loong,AssetMf destoryed,can't packdl");
                return true;
            }
            Debug.Log("Loong, startup pack dl");
            if (Running)
            {
                reStartUp = true;
                if (!isStop) Stop();
                Debug.LogWarning("Loong,packdl restartup");
                return false;
            }
            BegLv = Lv;
            reStartUp = false;
            AssetMf.IsStop = false;
            AssetMf.StartWatch();
            IsQuiet = true; //Quiet(BegLv);
            if (isQuiet)
            {
                Run();
            }
            else
            {
                AssetMf.SetInfos(BegLv, infos, false);
                if (infos.Count < 1)
                {
                    Run();
                }
                else
                {
                    //var msg = "为了您更好的游戏体验\n必须补充新资源才可进入";
                    var msgBox = MsgBoxProxy.Instance;
                    //msgBox.Show(msg, "确定", ChkNet, "退出", Quit);
                    msgBox.Show(617023, 690000, ChkNet, 690020, Quit);
                }
            }
            return isQuiet;
        }

        /// <summary>
        /// 同上
        /// </summary>
        /// <param name="lv"></param>
        /// <returns></returns>
        public bool StartUp(int lv)
        {
            User.instance.MapData.Level = lv;
            return StartUp();
        }

        public void Update()
        {
            ctrl.Update();
            //if (isQuiet) return;
            if (!running) return;
            if (dl.State != DownloadState.Suc) return;
            dl.Update();
        }


        public void Stop()
        {
            if (isStop) return;
            Debug.Log("Loong, packdl direct stop");
            dl.Stop();
            IsStop = true;
            AssetMf.IsStop = true;
        }

        public void Stop(params object[] args)
        {
            Debug.Log("Loong, packdl stop logoutsuc");
            Stop();
        }

        /// <summary>
        /// true:已经下载完成
        /// </summary>
        /// <returns></returns>
        public bool IsOverByFile()
        {
            if (!File.Exists(PackPath)) return false;
            bool over = false;
            var str = FileTool.Load(PackPath);
            if (string.IsNullOrEmpty(str)) return false;
            int ver = 0;
            str = str.Trim();
            if (int.TryParse(str, out ver))
            {
                var code = App.VerCode;
                if (code == ver)
                {
                    over = true;
                }
                Debug.LogWarningFormat("Loong, PackDl ver:{0}, App.Ver:{1}", ver, code);
            }
            return over;
        }


        /// <summary>
        /// 提示
        /// </summary>
        public void Tip()
        {
            var end = IsOverByFile();
            var msg = string.Format("dl:{0},vl:{1},end:{2}", dl.Pro, dl.VD.Pro, end);
            UITip.Error(msg);
        }

        public void ShowTip(params object[] args)
        {
            Tip();
        }

        public void DeleteOverFile()
        {
            FileTool.SafeDelete(PackPath);
        }
    }
    #endregion
}