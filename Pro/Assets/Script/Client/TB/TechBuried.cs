/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/7/18 12:30:45
 * 技术埋点基类
 ============================================================================*/

using System;
using Loong.Game;
using System.Text;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.Networking;

namespace Loong.Game
{
    /// <summary>
    /// 技术埋点
    /// </summary>
    public class TechBuried
    {
        #region 字段

        #endregion

        #region 属性
        private string ip = App.BSUrl + "buried/logs/";

        public static readonly TechBuried Instance = new TechBuried();

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        private TechBuried()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        /// <summary>
        /// 所有共有字段
        /// </summary>
        /// <param name="fm"></param>
        protected void SetForm(WWWForm fm)
        {
            var sTm = TimeTool.GetServerTimeNow();
            sTm = sTm * 0.001f;
            var tm = Mathf.FloorToInt((float)sTm);
            var user = User.instance;
            fm.AddField("time", tm);
            var svrID = user.ServerID;
            if (string.IsNullOrEmpty(svrID)) svrID = "0";
            fm.AddField("server_id", svrID);
            fm.AddField("log_time", tm);
            var uid = GetUID();

            var cid = GetChannelID();

            var accUID = string.Format("{0}_{1}", cid, uid);
            fm.AddField("account_id", accUID);
            fm.AddField("uid", uid);
            var gcid = GetGameChannelID();
            fm.AddField("user_register_channel_id", gcid);
            fm.AddField("user_login_channel_id", cid);
            var plat = GetPlat();
            fm.AddField("mobile_os_type", plat);
            var data = user.MapData;
            fm.AddField("user_add_time", 0);
            fm.AddField("game_version", App.Ver);
        }

        protected void SetForm1(WWWForm fm)
        {
            var di = Device.Instance;
            fm.AddField("ip", Get(di.IP));
            fm.AddField("imei", Get(di.IMEI));
            fm.AddField("mac", Get(di.Mac));
            fm.AddField("sdk_version", di.SysSDKVer);
            fm.AddField("mobile_operator", Get(di.SIMName));
            fm.AddField("network_type", Get(di.NetType));
            fm.AddField("client_type", Get(di.Brand));
            fm.AddField("client_version", Get(di.Model));
        }

        protected string Get(string str)
        {
            if (string.IsNullOrEmpty(str)) return "unknown";
            return str;
        }

        /// <summary>
        /// 判断内存是否充足
        /// </summary>
        /// <param name="mem">单位MB</param>
        /// <returns></returns>
        protected int MemIsEnough(int mem)
        {
            var res = (mem > 300 ? 0 : 1);
            return res;
        }

        /// <summary>
        /// 获取平台
        /// </summary>
        /// <returns></returns>
        protected int GetPlat()
        {
#if UNITY_EDITOR
            return 0;
#elif UNITY_ANDROID
            return 4;
#elif UNITY_IOS || UNITY_IPHONE
            return 5;
#else
            return 0;
#endif
        }

        /// <summary>
        /// 获取分辨率
        /// </summary>
        /// <returns></returns>
        protected string GetResolution()
        {
            var res = string.Format("{0}X{1}", Screen.width, Screen.height);
            return res;
        }


        /// <summary>
        /// 获取UID
        /// </summary>
        /// <returns></returns>
        protected string GetUID()
        {
            var uid = User.instance.UID;
            if (string.IsNullOrEmpty(uid)) uid = "0";
            return uid;
        }


        protected string GetChannelID()
        {
            string cid = null;
            cid = User.instance.ChannelID;
            if (string.IsNullOrEmpty(cid)) cid = "0";
            return cid;
        }

        protected string GetGameChannelID()
        {
            string gcid = null;
            gcid = User.instance.GameChannelId;
            if (string.IsNullOrEmpty(gcid)) gcid = "0";
            return gcid;
        }

        #endregion

        #region 公开方法
        /// <summary>
        /// true:可以发送
        /// </summary>
        /// <returns></returns>
        public bool Check()
        {
            if (Application.isEditor) return false;
            return true;
        }

        /// <summary>
        /// 上传首次打开数据
        /// </summary>
        public void First()
        {
            if (!Check()) return;
            if (!App.FirstInstall) return;
            var fm = new WWWForm();
            var path = "firstOpen";

            SetForm(fm);
            SetForm1(fm);
            var di = Device.Instance;

            fm.AddField("os_version", di.SysVer);
            fm.AddField("os_type", di.OS);
            fm.AddField("cpu_name", di.CpuName);
            fm.AddField("cpu_frequency", di.CpuFreq);
            fm.AddField("cpu_core_number", di.CpuCount);
            fm.AddField("gpu_name", di.GpuName);
            fm.AddField("memory", di.TotalMem);
            var avaiMem = di.AvaiMem;
            fm.AddField("now_memory_free", avaiMem);
            var memIsEnough = MemIsEnough(avaiMem);
            fm.AddField("memory_isFull", memIsEnough);
            fm.AddField("disk_size", di.TotalRom);
            fm.AddField("now_disk_size_free", di.AvaiRom);
            fm.AddField("sd_max_size", di.TotalSD);
            fm.AddField("now_sd_free", di.AvaiSD);
            var rs = GetResolution();
            fm.AddField("resolution", rs);
            fm.AddField("baseband_version", di.BBVer);
            fm.AddField("core_version", di.BBVer);
            fm.AddField("OpenGL_VENDOR", di.GpuVerdor);
            fm.AddField("OpenGL_VERSION", di.GpuVer);
            MonoEvent.Start(Upload(fm, path));
        }
#if LOONG_ENABLE_UPG
        /// <summary>
        /// 升级资源
        /// </summary>
        /// <param name="upg"></param>
        public void UpgAssets(UpgAssets upg)
        {
            if (!Check()) return;
            var path = "patch";
            var suc = (string.IsNullOrEmpty(upg.Error) ? true : false);
            var code = (suc ? "patch_finish" : "patch_exception");
            var fm = new WWWForm();

            SetForm(fm);
            SetForm1(fm);
            var sb = ObjPool.Instance.Get<StringBuilder>();
            var size = ByteUtil.GetMB(upg.Total);
            sb.Append("last_client_version:").Append(upg.LastVer);
            if (suc)
            {
                sb.Append("#time_download:").Append(upg.Elapsed.Elapsed.TotalSeconds);
            }
            else
            {
                sb.Append("#reason:").Append(upg.Error);
            }
            sb.Append("#size_path:").Append(size);

            fm.AddField("action_code", code);
            fm.AddField("statistics_field", sb.ToString());
            MonoEvent.Start(Upload(fm, path));
            sb.Remove(0, sb.Length);
            ObjPool.Instance.Add(sb);
        }
#endif

        /// <summary>
        /// 上传数据
        /// </summary>
        /// <param name="fm"></param>
        /// <param name="tip"></param>
        /// <returns></returns>
        public IEnumerator Upload(WWWForm fm, string tip)
        {
            string url = ip + tip;
            using (UnityWebRequest request = UnityWebRequest.Post(url, fm))
            {
                iTrace.Log("Loong", string.Format("upload {0} beg", tip));
                yield return request.SendWebRequest();
                var err = request.error;
                if (string.IsNullOrEmpty(err))
                {
                    iTrace.Log("Loong", string.Format("upload {0} {1} suc:", tip, request.downloadHandler.text));
                }
                else
                {
                    iTrace.Warning("Loong", string.Format("upload {0} {1} fail:", tip, err));
                }
            }
        }

        #endregion
    }
}