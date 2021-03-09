/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.3 20:09:25
 ============================================================================*/

using System.Text;

namespace Loong.Game
{
    /// <summary>
    /// 字节工具
    /// </summary>
    public static class ByteUtil
    {
        #region 字段
        /// <summary>
        /// 1除以1024的值
        /// </summary>
        public const float kbfactor = 1 / 1024f;

        /// <summary>
        /// 1除以(1024*1024)的值
        /// </summary>
        public const float mbfactor = 1 / (1024f * 1024f);

        /// <summary>
        /// 1除以(1024*1024*1024)的值
        /// </summary>
        public const float tbfactor = 1 / (1024f * 1024f * 1024f);

        /// <summary>
        /// KB的字节临界值大小
        /// </summary>
        public const int thresholdKB = 1024;

        /// <summary>
        /// MB的字节临界值大小
        /// </summary>
        public const int thresholdMB = 1024 * 1024;

        /// <summary>
        /// TB的字节临界值大小
        /// </summary>
        public const int thresholdTB = 1024 * 1024 * 1024;

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
        /// 获取单位
        /// </summary>
        /// <param name="size"></param>
        /// <returns></returns>
        public static ByteUnit GetUnit(long size)
        {
            if (size < thresholdKB)
            {
                return ByteUnit.B;
            }
            else if (size < thresholdMB)
            {
                return ByteUnit.KB;
            }
            else if (size < thresholdTB)
            {
                return ByteUnit.MB;
            }
            else
            {
                return ByteUnit.TB;
            }
        }

        /// <summary>
        /// 将字节数转换为合适单位的浮点数
        /// 如果字节数小于1024,则转换为B
        /// 如果字节数小于1024*1024则转换为KB
        /// 如果字节数小于1024*1024*1024则转换为MB
        /// 反之转换为TB
        /// </summary>
        /// <param name="size"></param>
        /// <returns></returns>
        public static float Get(long size)
        {
            if (size < thresholdKB)
            {
                return size;
            }
            else if (size < thresholdMB)
            {
                return GetKB(size);
            }
            else if (size < thresholdTB)
            {
                return GetMB(size);
            }
            else
            {
                return GetTB(size);
            }
        }

        /// <summary>
        /// 将字节数根据转换为指定单位的数字
        /// </summary>
        /// <param name="size"></param>
        /// <param name="unit"></param>
        /// <returns></returns>
        public static float Get(long size, ByteUnit unit)
        {
            switch (unit)
            {
                case ByteUnit.KB:
                    return GetKB(size);
                case ByteUnit.MB:
                    return GetMB(size);
                case ByteUnit.TB:
                    return GetTB(size);
                default:
                    return size;
            }
        }

        /// <summary>
        /// 将大小转换为指定字符串
        /// </summary>
        /// <param name="size">字节大小</param>
        /// <returns></returns>
        public static string GetSizeStr(long size)
        {
            string str = null;
            ByteUnit unit = GetUnit(size);
            float fs = Get(size);
            str = unit == ByteUnit.B ? fs.ToString() : fs.ToString("f2");
            str = str + unit.ToString();
            return str;
        }

        /// <summary>
        /// 将大小转换为指定字符串,并包含原始大小信息
        /// </summary>
        /// <param name="size"></param>
        /// <returns></returns>
        public static string GetSizeDetail(long size)
        {
            var str = GetSizeStr(size);
            return string.Format("{0}({1})", str, size);
        }

        /// <summary>
        /// 将字节数转换为合适单位的浮点数
        /// </summary>
        /// <param name="size"></param>
        /// <param name="decimals">小数位</param>
        /// <returns></returns>
        public static float Get(long size, int decimals = 100)
        {
            decimals = (decimals < 1) ? 1 : decimals;
            float temp = Get(size);
            int value = (int)(temp * decimals);
            temp = value * (1f / decimals);
            return temp;
        }

        /// <summary>
        /// 将字节数转换为TB
        /// </summary>
        /// <param name="size"></param>
        /// <returns></returns>
        public static float GetTB(long size)
        {
            float temp = size * tbfactor;
            return temp;
        }

        /// <summary>
        /// 将字节数转换为MB
        /// </summary>
        /// <param name="size"></param>
        /// <returns></returns>
        public static float GetMB(long size)
        {
            float temp = size * mbfactor;
            return temp;
        }

        /// <summary>
        /// 将字节数转换为KB
        /// </summary>
        /// <param name="size"></param>
        /// <returns></returns>
        public static float GetKB(long size)
        {
            float temp = size * kbfactor;
            return temp;
        }

        /// <summary>
        /// 将字节数转换为MB后,通过数学方法将小数位保留指定数目
        /// </summary>
        /// <param name="size">字节数</param>
        /// <param name="decimals">小数位</param>
        /// <returns></returns>
        public static double FmtByRound(long size, int decimals)
        {
            double temp = size * mbfactor;
            temp = System.Math.Round(temp, decimals);
            return temp;
        }

        /// <summary>
        /// 将字节数转换为MB后,通过字符格式化将小数位保留指定位数
        /// </summary>
        /// <param name="size">字节数</param>
        /// <param name="format">格式</param>
        /// <returns></returns>
        public static float FmtByStrFmt(long size, string format = "{0:N2}")
        {
            float temp = size * mbfactor;
            string value = string.Format(format, temp);
            temp = float.Parse(value);
            return temp;
        }

        /// <summary>
        /// 将字节数转换为MB后,通过字符格式化将小数位保留指定位数
        /// </summary>
        /// <param name="size">字节数</param>
        /// <param name="format">格式</param>
        /// <returns></returns>
        public static float FmtByToStr(long size, string format = "0.00")
        {
            float temp = size * mbfactor;
            string value = temp.ToString(format);
            temp = float.Parse(value);
            return temp;
        }

        /// <summary>
        /// 将字节数转换为MB后,通过计算将小数位保留指定位数
        /// </summary>
        /// <param name="size"></param>
        /// <param name="decimals">小数位数</param>
        /// <returns></returns>
        public static float FmtByCalc(long size, int decimals)
        {
            decimals = (decimals < 10) ? 10 : decimals;
            float temp = size * mbfactor;
            int value = (int)(temp * decimals);
            temp = value * (1f / decimals);
            return temp;
        }

        /// <summary>
        /// 交换字节数组的两个索引的值
        /// </summary>
        /// <param name="arr"></param>
        /// <param name="left"></param>
        /// <param name="right"></param>
        public static void Swap(byte[] arr, int left, int right)
        {
            if (arr == null) return;
            int max = System.Math.Max(left, right);
            if (max < arr.Length)
            {
                byte b = arr[left];
                arr[left] = arr[right];
                arr[right] = b;
            }
        }

        /// <summary>
        /// 获取字节数组字符串
        /// </summary>
        /// <param name="arr"></param>
        /// <returns></returns>
        public static string GetStr(byte[] arr)
        {
            if (arr == null || arr.Length == 0) return null;
            int length = arr.Length;
            StringBuilder sb = new StringBuilder();
            sb.Append("<");
            int last = length - 1;
            for (int i = 0; i < length; i++)
            {
                sb.Append(arr[i]);
                if (i < last) sb.Append(",");
            }
            sb.Append(">");
            return sb.ToString();
        }
        #endregion
    }
}