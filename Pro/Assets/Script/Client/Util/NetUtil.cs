/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2013/10/11 21:10:23
 ============================================================================*/

using System;
using System.IO;
using System.Net;
using System.Text;
using UnityEngine;
using System.Net.Sockets;
using System.Net.NetworkInformation;

using Ping = System.Net.NetworkInformation.Ping;

namespace Loong.Game
{
    /// <summary>
    /// 网络工具
    /// </summary>
    public static class NetUtil
    {

        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 根据寻址方案获取本机IP 
        /// </summary>
        /// <param name="af">默认AddressFamily.InterNetwork为IPv4寻址</param>
        /// <returns></returns>
        public static IPAddress GetIP(AddressFamily af = AddressFamily.InterNetwork)
        {
            string hostName = Dns.GetHostName();
            IPAddress[] arr = Dns.GetHostAddresses(hostName);
            int length = arr.Length;
            for (int i = 0; i < length; i++)
            {
                var it = arr[i];
                if (it.AddressFamily == af) return it;
            }
            return null;
        }

        /// <summary>
        /// 根据寻址方案获取本地IP地址字符串
        /// </summary>
        /// <param name="af">默认AddressFamily.InterNetwork为IPv4寻址</param>
        /// <returns></returns>
        public static string GetIpStr(AddressFamily af = AddressFamily.InterNetwork)
        {
            IPAddress addr = GetIP(af);
            string str = (addr == null) ? "" : addr.ToString();
            return str;
        }

        /// <summary>
        /// 获取物理地址
        /// </summary>
        /// <returns></returns>
        public static string GetMac()
        {
            NetworkInterface[] arr = null;
            try
            {
                arr = NetworkInterface.GetAllNetworkInterfaces();
            }
            catch (Exception e)
            {
                Debug.LogWarningFormat("Loong, getMac err:{0}", e.Message);
            }
            if (arr == null) return "";
            string mac = "";
            int length = arr.Length;
            for (int i = 0; i < length; i++)
            {
                var it = arr[i];
                var type = it.NetworkInterfaceType;
                if (type == NetworkInterfaceType.Loopback) continue;
                if (type == NetworkInterfaceType.Tunnel) continue;
                mac = it.GetPhysicalAddress().ToString();
                if (string.IsNullOrEmpty(mac)) continue;
                break;
            }
            return mac;
        }


        /// <summary>
        /// 验证IP有效性/网络是否通畅
        /// </summary>
        /// <param name="ip"></param>
        /// <returns></returns>
        public static bool Ping(IPAddress ip)
        {
            using (Ping ping = new Ping())
            {
                PingOptions options = new PingOptions();
                options.DontFragment = true;
                byte[] buf = Encoding.UTF8.GetBytes("Data");
                PingReply reply = ping.Send(ip, 120, buf, options);
                if (reply.Status == IPStatus.Success) return true;
            }
            return false;
        }

        /// <summary>
        /// 验证IP有效性/网络是否通畅
        /// </summary>
        /// <param name="ip"></param>
        /// <returns></returns>
        public static bool Ping(string ip)
        {
            IPAddress address = null;
            try
            {
                address = IPAddress.Parse(ip);
            }
            catch (FormatException)
            {
                Debug.LogError(string.Format("IP:{0},格式错误", ip));
                return false;
            }
            return Ping(address);
        }
#if LOONG_ENABLE_UPG
        /// <summary>
        /// 测试下载速度
        /// </summary>
        /// <param name="url"></param>
        /// <returns>B/S</returns>
        public static long Speed(string url)
        {
            if (NetObserver.NoNet()) return 0;
            var dl = new Download();
            var name = Path.GetFileName(url);
            dl.Src = url;
            var dest = AssetPath.Cache + name;
            dl.Dest = dest;
            if (dl.Execute())
            {
                return dl.AveSpeed;
            }
            return 0;
        }
#endif
        #endregion
    }
}