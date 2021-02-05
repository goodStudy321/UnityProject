using System.Text;


namespace Hello.Game
{
    public enum ByteUnit
    {
        /// <summary>
        /// 字节
        /// </summary>
        B,

        /// <summary>
        /// 1024字节
        /// </summary>
        KB,

        /// <summary>
        /// 1024*1024字节
        /// </summary>
        MB,

        /// <summary>
        /// 1024*1024*1024字节
        /// </summary>
        TB,
    }

    public static class ByteUtil
    {
        public const float kbfactor = 1 / 1024f;

        public const float mbfactor = 1 / (1024f * 1024f);

        public const float tbfactor = 1 / (1024f * 1024f * 1024f);

        public const int thresholdKB = 1024;

        public const int thresholdMB = 1024 * 1024;

        public const int thresholdTB = 1024 * 1024 * 1024;

        public static ByteUnit GetUnit(long size)
        {
            if (size < thresholdKB)
            {
                return ByteUnit.B;
            }
            else if(size < thresholdMB)
            {
                return ByteUnit.KB;
            }
            else if(size < thresholdTB)
            {
                return ByteUnit.MB;
            }
            else
            {
                return ByteUnit.TB;
            }
        }

        public static float Get(long size)
        {
            if(size < thresholdKB)
            {
                return size;
            }
            else if(size < thresholdMB)
            {
                return GetKB(size);
            }
            else if(size < thresholdTB)
            {
                return GetMB(size);
            }
            else
            {
                return GetTB(size);
            }
        }

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

        public static string GetSizeStr(long size)
        {
            string str = null;
            ByteUnit unit = GetUnit(size);
            float fs = Get(size);
            str = unit == ByteUnit.B ? fs.ToString() : fs.ToString("f2");
            str = str + unit.ToString();
            return str;
        }

        public static string GetSizeDetail(long size)
        {
            var str = GetSizeStr(size);
            return string.Format("{0}({1})", str, size);
        }


        public static float Get(long size,int decimals = 100)
        {
            decimals = (decimals < 1) ? 1 : decimals;
            float temp = Get(size);
            int value = (int)(temp * decimals);
            temp = value * (1f / decimals);
            return temp;
        }

        public static float GetTB(long size)
        {
            float temp = size * tbfactor;
            return temp;
        }

        public static float GetMB(long size)
        {
            float temp = size * mbfactor;
            return temp;
        }

        public static float GetKB(long size)
        {
            float temp = size * kbfactor;
            return temp;
        }

        public static double FmtByRound(long size,int decimals)
        {
            double temp = size * mbfactor;
            temp = System.Math.Round(temp, decimals);
            return temp;
        }

        public static float FmtByStrFmt(long size, string format = "{0:N2}")
        {
            float temp = size * mbfactor;
            string value = string.Format(format, temp);
            temp = float.Parse(value);
            return temp;
        }

        public static float FmtByToStr(long size, string format = "0.00")
        {
            float temp = size * mbfactor;
            string value = temp.ToString(format);
            temp = float.Parse(value);
            return temp;
        }

        public static float FmtByCalc(long size, int decimals)
        {
            decimals = (decimals < 10) ? 10 : decimals;
            float temp = size * mbfactor;
            int value = (int)(temp * decimals);
            temp = value * (1f / decimals);
            return temp;
        }

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

    }
}

