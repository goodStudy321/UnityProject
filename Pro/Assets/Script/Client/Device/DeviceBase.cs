/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2015/4/15 21:35:31
 * 一般未获取时,字符串的返回值为:unknown,数字返回值为:-1
 ============================================================================*/

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Net.NetworkInformation;

namespace Loong.Game
{

    /// <summary>
    /// 设备信息基类
    /// </summary>
    public abstract class DeviceBase
    {
        #region 字段
        private string ip = null;
        private string mac = null;
        private string os = null;
        private string appVer = null;
        private bool isLiuHai = false;
        #endregion

        #region 属性
        /// <summary>
        /// IP地址
        /// </summary>
        public string IP
        {
            get { return ip; }
            protected set { ip = value; }
        }

        /// <summary>
        /// 物理地址
        /// </summary>
        public string Mac
        {
            get { return mac; }
            protected set { mac = value; }
        }


        /// <summary>
        /// 国际移动设备识别码
        /// </summary>
        public virtual string IMEI
        {
            get { return "unknown"; }
        }

        /// <summary>
        /// 电池等级
        /// </summary>
        public float BatteryLv
        {
            get { return SystemInfo.batteryLevel; }
        }

        /// <summary>
        /// 电池状态
        /// 0:未知
        /// 1:已插入并在充电
        /// 2:已拔出并在放电
        /// 3:已插入但未充电
        /// 4:已插入并已充满
        /// </summary>
        public int BatteryStatus
        {
            get { return (int)SystemInfo.batteryStatus; }
        }

        /// <summary>
        /// 手机品牌
        /// </summary>
        public virtual string Brand
        {
            get { return SystemInfo.deviceName; }
        }

        /// <summary>
        /// 手机型号
        /// </summary>
        public virtual string Model
        {
            get { return SystemInfo.deviceModel; }
        }

        /// <summary>
        /// 运营商名称
        /// </summary>
        public virtual string SIMName
        {
            get { return "unknown"; }
        }

        /// <summary>
        /// wifi强度
        /// </summary>
        public virtual int WifiRSSI
        {
            get { return -1; }
        }

        /// <summary>
        /// 网络类型 2g/3g/4g/wifi
        /// </summary>
        public virtual string NetType
        {
            get
            {
                var irb = Application.internetReachability;
                if (irb == NetworkReachability.ReachableViaLocalAreaNetwork)
                {
                    return "wifi";
                }
                else if (irb == NetworkReachability.ReachableViaCarrierDataNetwork)
                {
                    return "4g";
                }
                return "unknown";
            }
        }

        /// <summary>
        /// cpu名称
        /// </summary>
        public virtual string CpuName
        {
            get { return "unknown"; }
        }

        /// <summary>
        /// 处理器核心数
        /// </summary>
        public int CpuCount
        {
            get { return SystemInfo.processorCount; }
        }

        /// <summary>
        /// 处理器频率
        /// </summary>
        public int CpuFreq
        {
            get { return SystemInfo.processorFrequency; }
        }

        /// <summary>
        /// GPU ID
        /// </summary>
        public int GpuID
        {
            get { return SystemInfo.graphicsDeviceID; }
        }

        /// <summary>
        /// GPU名称
        /// </summary>
        public string GpuName
        {
            get { return SystemInfo.graphicsDeviceName; }
        }

        /// <summary>
        /// GPU类型
        /// </summary>
        public string GpuType
        {
            get { return SystemInfo.graphicsDeviceType.ToString(); }
        }

        /// <summary>
        /// GPU供应商
        /// </summary>
        public string GpuVerdor
        {
            get { return SystemInfo.graphicsDeviceVendor; }
        }

        /// <summary>
        /// GPU 版本
        /// </summary>
        public string GpuVer
        {
            get { return SystemInfo.graphicsDeviceVersion; }
        }

        /// <summary>
        /// Gpu 显存 单位M
        /// </summary>
        public int GpuMem
        {
            get { return SystemInfo.graphicsMemorySize; }
        }

        /// <summary>
        /// 剩余内存 M
        /// </summary>
        public virtual int AvaiMem
        {
            get { return -1; }
        }

        /// <summary>
        /// 总内存 单位M
        /// </summary>
        public virtual int TotalMem
        {
            get { return SystemInfo.systemMemorySize; }
        }

        /// <summary>
        /// 机身总存储 单位MB
        /// </summary>
        public virtual int TotalRom
        {
            get { return -1; }
        }

        /// <summary>
        /// 机身剩余存储 单位MB
        /// </summary>
        public virtual int AvaiRom
        {
            get { return -1; }
        }

        /// <summary>
        /// SD总大小 单位MB
        /// </summary>
        public virtual int TotalSD
        {
            get { return -1; }
        }

        /// <summary>
        /// SD剩余大小 单位MB
        /// </summary>
        public virtual int AvaiSD
        {
            get { return -1; }
        }

        /// <summary>
        /// 基带版本
        /// </summary>
        public virtual string BBVer
        {
            get { return "unknown"; }
        }

        /// <summary>
        /// 内核版本
        /// </summary>
        public virtual string KernelVer
        {
            get { return "unknown"; }
        }

        /// <summary>
        /// 系统版本
        /// </summary>
        public virtual string SysVer
        {
            get { return "unknown"; }
        }

        /// <summary>
        /// 系统SDK版本
        /// </summary>
        public virtual int SysSDKVer
        {
            get { return -1; }
        }


        /// <summary>
        /// 客户端版本
        /// </summary>
        public string AppVer
        {
            get { return appVer; }
        }

        /// <summary>
        /// 操作系统
        /// </summary>
        public string OS
        {
            get { return os; }
        }

        /// <summary>
        /// true:刘海屏
        /// </summary>
        public virtual bool IsLiuHai
        {
            get { return isLiuHai; }
            set { isLiuHai = value; }
        }
        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public virtual void Init()
        {
            Refresh();
            os = SystemInfo.operatingSystem;
            appVer = Application.version;
        }

        public virtual void Refresh()
        {
            IP = NetUtil.GetIpStr();
            Mac = NetUtil.GetMac();

        }
        #endregion
    }
}