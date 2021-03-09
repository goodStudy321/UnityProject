/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2015/4/15 21:35:31
 ============================================================================*/
#if UNITY_ANDROID && !UNITY_EDITOR


using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{

    /// <summary>
    /// Android设置信息
    /// </summary>
    public class Device : DeviceBase
    {
#region 字段

        private string imei = null;
        private string brand = null;
        private string model = null;
        private string simName = null;
        private string cpuName = null;
        private int totalRom = -1;
        private int totalSD = -1;
        private string bbVer = null;
        private string keneelVer = null;
        private string sysVer = null;
        private int sysSDKVer = -1;
        private AndroidJavaObject javaObj = null;


        public static readonly Device Instance = new Device();
#endregion

#region 属性
        public override string IMEI
        {
            get { return imei; }
        }

        public override string Brand
        {
            get { return brand; }
        }

        public override string Model
        {
            get { return model; }
        }

        public override string SIMName
        {
            get { return simName; }
        }

        public override int WifiRSSI
        {
            get { return GetVal("getWifiRSSI", base.WifiRSSI); }
        }

        public override string NetType
        {
            get
            {
                string res = GetVal<string>("getNetType", null);
                if (res == null || res == "unknown") res = base.NetType;
                return res;
            }
        }

        public override string CpuName
        {
            get { return cpuName; }
        }

        public override int AvaiMem
        {
            get { return (GetVal("getAvaiMem", base.AvaiMem) / 1024); }
        }

        public override int TotalRom
        {
            get { return totalRom; }
        }

        public override int AvaiRom
        {
            get
            {
                long sRom = base.AvaiRom;
                long aRom = GetVal("getAvailRom", sRom);
                int rRom = (int)(aRom * ByteUtil.mbfactor);
                return rRom;
            }
        }

        public override int TotalSD
        {
            get { return totalSD; }
        }

        public override int AvaiSD
        {
            get
            {
                long sSD = base.AvaiRom;
                long aSD = GetVal("getAvailSD", sSD);
                int rSD = (int)(aSD * ByteUtil.mbfactor);
                return rSD;
            }
        }

        public override string BBVer
        {
            get { return bbVer; }
        }

        public override string KernelVer
        {
            get { return keneelVer; }
        }

        public override string SysVer
        {
            get { return sysVer; }
        }

        public override int SysSDKVer
        {
            get { return sysSDKVer; }
        }

#endregion

#region 委托事件

#endregion

#region 构造方法
        private Device()
        {

        }
#endregion

#region 私有方法
        /// <summary>
        /// 设置java对象
        /// </summary>
        private void SetJavaObj()
        {
#if !UNITY_EDITOR
            string javaObjName = "loong.lib.Device";
            try
            {
                javaObj = new AndroidJavaObject(javaObjName);
                javaObj.Call("Refresh");
            }
            catch (Exception e)
            {
                iTrace.Error("Loong", string.Format("获取Java对象:{0},错误:{1}", javaObjName, e.Message));
            }
#endif
        }


        private T GetVal<T>(string fn, T defaultVal)
        {
            if (javaObj == null) return defaultVal;
            T res = defaultVal;
            try
            {
                res = javaObj.Call<T>(fn);
            }
            catch (Exception e)
            {
                Debug.LogWarningFormat("Loong,call {0}, err:{1}", fn, e.Message);
            }
            return res;
        }

#endregion

#region 保护方法

#endregion

#region 公开方法
        public override void Init()
        {
            base.Init();
            if (Application.isEditor) return;
            SetJavaObj();
            imei = GetVal("getIMEI", base.IMEI);
            brand = GetVal("getBrand", base.Brand);
            model = GetVal("getModel", base.Model);
            simName = GetVal("getSIMName", base.SIMName);
            cpuName = GetVal("getCpuName", base.CpuName);
            long stRom = base.TotalRom;
            long tRom = GetVal("getTotalRom", stRom);
            totalRom = (int)(tRom * ByteUtil.mbfactor);
            long stSD = base.TotalSD;
            long tSD = GetVal("getTotalSD", stSD);
            totalSD = (int)(tSD * ByteUtil.mbfactor);
            bbVer = GetVal("getBBVer", base.BBVer);
            sysVer = GetVal("getSysVer", base.SysVer);
            keneelVer = GetVal("getKernelVer", base.KernelVer);
            sysSDKVer = GetVal("getSDKVer", base.SysSDKVer);
            IsLiuHai = GetVal("isLiuHai", false);
        }
#endregion
    }
}
#endif