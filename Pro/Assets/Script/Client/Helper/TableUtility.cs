using System;
using System.IO;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;


namespace Table
{
    public interface IKey
    {
        UInt64 Key();
    }

    public abstract class Binary
    {
        public abstract int Load(byte[] buffer, int index);
    }

    public class String
    {
        private int m_pos = 0;
        private bool m_load = false;
        private byte[] m_data = null;
        private string m_value = string.Empty;

        public String()
        {
        }

        public String(byte[] data, int pos)
        {
            m_pos = pos;
            m_data = data;
        }

        public void Set(byte[] data, int pos)
        {
            m_pos = pos;
            m_data = data;
        }

        public override string ToString()
        {
            if (!m_load)
            {
                m_value = Utility.ToString(m_data, m_pos);
                m_load = true;
            }

            return m_value;
        }

        public static implicit operator string(String data)
        {
            return data.ToString();
        }

        /*public static explicit operator string(String data)
        {
            return data.ToString();
        }*/
    }

    public class NewHelper
    {
        public delegate object Handle();
        private static Dictionary<Type, Handle> ms_map = new Dictionary<Type, Handle>();

        public static void Clear()
        {
            ms_map.Clear();
        }

        public static void Register(Type type, Handle handle)
        {
            ms_map.Add(type, handle);
        }

        public static void New<T>(ref T value) where T : Binary
        {
            value = ms_map[typeof(T)]() as T;
        }
    }

    public sealed class TableHeader
    {
        UInt32 m_version;
        UInt16 m_size;

        public UInt32 Version
        {
            get { return m_version; }
        }

        public UInt16 Size
        {
            get { return m_size; }
        }

        public int AllSize
        {
            get { return Marshal.SizeOf(m_version) + Marshal.SizeOf(m_size) + m_size; }
        }

        public int Load(byte[] buffer, int index)
        {
            m_version = BitConverter.ToUInt32(buffer, index);
            m_size = BitConverter.ToUInt16(buffer, index + Marshal.SizeOf(m_version));

            return Marshal.SizeOf(m_version) + Marshal.SizeOf(m_size);
        }
    }

    public sealed class RepeatHeader
    {
        Int32 m_size;
        Int32 m_offset;

        public Int32 Size
        {
            get { return m_size; }
        }

        public Int32 Offset
        {
            get { return m_offset; }
        }

        public int Load(byte[] buffer, int index)
        {
            m_size = BitConverter.ToInt32(buffer, index);
            m_offset = BitConverter.ToInt32(buffer, index + Marshal.SizeOf(m_size));

            return Marshal.SizeOf(m_size) + Marshal.SizeOf(m_offset);
        }
    }

    public class Loader
    {
        byte[] m_array;
        int m_index;
        int m_begin;

        public Loader(ref byte[] array, int index)
        {
            m_array = array;
            m_index = index;
            m_begin = index;
        }

        public int Index
        {
            get { return m_index; }
        }

        public int Size
        {
            get { return m_index - m_begin; }
        }

        public Loader Load(ref SByte value)
        {
            value = (SByte)m_array[Index];
            m_index += Marshal.SizeOf(value);
            return this;
        }

        public Loader Load(ref Byte value)
        {
            value = m_array[Index];
            m_index += Marshal.SizeOf(value);
            return this;
        }

        public Loader Load(ref Int16 value)
        {
            value = BitConverter.ToInt16(m_array, Index);
            m_index += Marshal.SizeOf(value);
            return this;
        }

        public Loader Load(ref UInt16 value)
        {
            value = BitConverter.ToUInt16(m_array, Index);
            m_index += Marshal.SizeOf(value);
            return this;
        }

        public Loader Load(ref Int32 value)
        {
            value = BitConverter.ToInt32(m_array, Index);
            m_index += Marshal.SizeOf(value);
            return this;
        }

        public Loader Load(ref UInt32 value)
        {
            value = BitConverter.ToUInt32(m_array, Index);
            m_index += Marshal.SizeOf(value);
            return this;
        }

        public Loader Load(ref Int64 value)
        {
            value = BitConverter.ToInt64(m_array, Index);
            m_index += Marshal.SizeOf(value);
            return this;
        }

        public Loader Load(ref UInt64 value)
        {
            value = BitConverter.ToUInt64(m_array, Index);
            m_index += Marshal.SizeOf(value);
            return this;
        }

        public Loader Load(ref float value)
        {
            value = BitConverter.ToSingle(m_array, Index);
            m_index += Marshal.SizeOf(value);
            return this;
        }

        public Loader Load(ref double value)
        {
            value = BitConverter.ToDouble(m_array, Index);
            m_index += Marshal.SizeOf(value);
            return this;
        }

        public Loader Load(ref String value)
        {
            Int32 index = 0;
            Load(ref index);
            value = new String(m_array, index);
            return this;
        }

        public Loader Load<T>(ref T value) where T : Binary
        {
            if (value == null)
                NewHelper.New(ref value);

            m_index += value.Load(m_array, m_index);
            return this;
        }

        public Loader Load(ref List<Byte> list)
        {
            RepeatHeader header = new RepeatHeader();
            m_index += header.Load(m_array, Index);

            list = new List<Byte>();
            Loader loader = new Loader(ref m_array, header.Offset);
            for (Int32 i = 0; i < header.Size; ++i)
            {
                Byte item = 0;
                loader.Load(ref item);
                list.Add(item);
            }

            return this;
        }

        public Loader Load(ref List<Int16> list)
        {
            RepeatHeader header = new RepeatHeader();
            m_index += header.Load(m_array, Index);

            list = new List<Int16>();
            Loader loader = new Loader(ref m_array, header.Offset);
            for (Int32 i = 0; i < header.Size; ++i)
            {
                Int16 item = 0;
                loader.Load(ref item);
                list.Add(item);
            }

            return this;
        }

        public Loader Load(ref List<UInt16> list)
        {
            RepeatHeader header = new RepeatHeader();
            m_index += header.Load(m_array, Index);

            list = new List<UInt16>();
            Loader loader = new Loader(ref m_array, header.Offset);
            for (Int32 i = 0; i < header.Size; ++i)
            {
                UInt16 item = 0;
                loader.Load(ref item);
                list.Add(item);
            }

            return this;
        }

        public Loader Load(ref List<Int32> list)
        {
            RepeatHeader header = new RepeatHeader();
            m_index += header.Load(m_array, Index);

            list = new List<Int32>();
            Loader loader = new Loader(ref m_array, header.Offset);
            for (Int32 i = 0; i < header.Size; ++i)
            {
                Int32 item = 0;
                loader.Load(ref item);
                list.Add(item);
            }

            return this;
        }

        public Loader Load(ref List<UInt32> list)
        {
            RepeatHeader header = new RepeatHeader();
            m_index += header.Load(m_array, Index);

            list = new List<UInt32>();
            Loader loader = new Loader(ref m_array, header.Offset);
            for (Int32 i = 0; i < header.Size; ++i)
            {
                UInt32 item = 0;
                loader.Load(ref item);
                list.Add(item);
            }

            return this;
        }

        public Loader Load(ref List<Int64> list)
        {
            RepeatHeader header = new RepeatHeader();
            m_index += header.Load(m_array, Index);

            list = new List<Int64>();
            Loader loader = new Loader(ref m_array, header.Offset);
            for (Int32 i = 0; i < header.Size; ++i)
            {
                Int64 item = 0;
                loader.Load(ref item);
                list.Add(item);
            }

            return this;
        }

        public Loader Load(ref List<UInt64> list)
        {
            RepeatHeader header = new RepeatHeader();
            m_index += header.Load(m_array, Index);

            list = new List<UInt64>();
            Loader loader = new Loader(ref m_array, header.Offset);
            for (Int32 i = 0; i < header.Size; ++i)
            {
                UInt64 item = 0;
                loader.Load(ref item);
                list.Add(item);
            }

            return this;
        }

        public Loader Load<T>(ref List<T> list) where T : Binary
        {
            RepeatHeader header = new RepeatHeader();
            m_index += header.Load(m_array, Index);

            list = new List<T>();
            Loader loader = new Loader(ref m_array, header.Offset);
            for (Int32 i = 0; i < header.Size; ++i)
            {
                T item = null;
                NewHelper.New(ref item);
                loader.Load(ref item);
                list.Add(item);
            }

            return this;
        }

        public Loader Load(ref List<String> list)
        {
            RepeatHeader header = new RepeatHeader();
            m_index += header.Load(m_array, Index);

            list = new List<String>();
            Loader loader = new Loader(ref m_array, header.Offset);
            for (Int32 i = 0; i < header.Size; ++i)
            {
                String str = null;
                loader.Load(ref str);
                list.Add(str);
            }

            return this;
        }
    }

    public struct Utility
    {
        /// LY add begin ///
        public static bool ContainsFolder(string path, string folderName)
        {
            path += "/" + folderName + "/";
            DirectoryInfo di = new DirectoryInfo(path);
            return di.Exists;
        }
        /// LY add end ///

        public static string ToString(byte[] array, int index)
        {
            int count = 0;
            while (0 < array[index + count])
                ++count;

            Encoding code = Encoding.GetEncoding("utf-8");
            return code.GetString(array, index, count);
        }

        public static int BinarySearch<T>(List<T> list, UInt64 key)
        {
            int start = 0, end = list.Count - 1, middle;
            while (start <= end)
            {
                middle = (start + end) >> 1;
                T item = list[middle];
                IKey kb = item as IKey;
                if (kb.Key() == key)
                    return middle;
                else if (key < kb.Key())
                    end = middle - 1;
                else
                    start = middle + 1;
            }

            return -1;
        }

        public static UInt64 Combine(UInt64 k1, UInt64 k2, int l)
        {
            return (k1 << (l * 8)) + k2;
        }

        public static UInt64 Combine(UInt64 k1, UInt64 k2, int l1, UInt64 k3, int l2)
        {
            return Combine(Combine(k1, k2, l1), k3, l2);
        }

        public static UInt64 Combine(UInt64 k1, UInt64 k2, int l1, UInt64 k3, int l2, UInt64 k4, int l3)
        {
            return Combine(Combine(k1, k2, l1, k3, l2), k4, l3);
        }

        public static UInt64 Combine(UInt64 k1, UInt64 k2, int l1, UInt64 k3, int l2, UInt64 k4, int l3, UInt64 k5, int l4)
        {
            return Combine(Combine(k1, k2, l1, k3, l2, k4, l3), k5, l4);
        }

        public static UInt64 Combine(UInt64 k1, UInt64 k2, int l1, UInt64 k3, int l2, UInt64 k4, int l3, UInt64 k5, int l4, UInt64 key6, int l5)
        {
            return Combine(Combine(Combine(k1, k2, l1, k3, l2, k4, l3), k5, l4), key6, l5);
        }

        public static UInt64 Combine(UInt64 k1, UInt64 k2, int l1, UInt64 k3, int l2, UInt64 k4, int l3, UInt64 k5, int l4, UInt64 key6, int l5, UInt64 key7, int l6)
        {
            return Combine(Combine(Combine(Combine(k1, k2, l1, k3, l2, k4, l3), k5, l4), key6, l5), key7, l6);
        }

        public static UInt64 Combine(Byte k1, Byte k2, Byte k3, Byte k4, Byte k5, Byte k6, Byte k7, Byte k8)
        {
            return Combine(Combine(k1, k2, 1, k3, 1, k4, 1, k5, 1, k6, 1, k7, 1), k8, 1);
        }

#if UNITY_IOS || UNITY_IPHONE
/*        static string ms_path = string.Empty;

        public static byte[] LoadFile(string name)
        {
            string filename = string.Empty;
            if (GameSetup.instance.publish)
            {
                filename = ResourceSystem.instance.FindSync(name);
                if (string.IsNullOrEmpty(filename))
                {
                    return null;
                }

                //Logger.Debug("================================ {0}", filename);
                if (32 < filename.Length)
                {
                    return ReadFile(filename);
                }

                TextAsset ta = Resources.Load(filename) as TextAsset;

                return ta.bytes;
            }

            if (!GameSetup.instance.publish && ms_path == string.Empty)
            {
                ms_path = Application.dataPath;

                while (!ContainsFolder(ms_path, "resource"))
                {
                    ms_path = Path.GetDirectoryName(ms_path);
                }

                ms_path += "/resource/";
            }

            filename = ms_path + name;

            return ReadFile(filename);
        }

        private static bool ContainsFolder(string path, string folderName)
        {
            path += "/" + folderName + "/";
            DirectoryInfo di = new DirectoryInfo(path);
            return di.Exists;
        }

        private static byte[] ReadFile(string filename)
        {
            FileStream fs = File.OpenRead(filename);
            byte[] data = new byte[fs.Length];
            fs.Read(data, 0, (int)fs.Length);
            fs.Close();
            fs.Dispose();
            return data;
        }*/
#endif
    }

    public class Manager<T> where T : Binary
    {
        private List<T> m_list = new List<T>();

        protected Manager()
        {
        }

        public int Size
        {
            get { return m_list.Count; }
        }

        public T Get(int index)
        {
            return index < Size ? m_list[index] : default(T);
        }

        protected T FindInternal(UInt64 key)
        {
            int index = Table.Utility.BinarySearch(m_list, key);
            return index == -1 ? default(T) : Get(index);
        }

        private bool ContainsFolder(string path, string folderName)
        {
            path += "/" + folderName + "/";
            DirectoryInfo di = new DirectoryInfo(path);
            return di.Exists;
        }

        protected bool Load(string path, string filename, uint verson)
        {
            //string fullname = path + "/" + filename;

            // #if UNITY_IOS || UNITY_IPHONE
            //             byte[] array = Utility.LoadFile(fullname);
            // #else
            /// LY edit begin///
            byte[] array = null;
            if (Application.isPlaying == false)
            {
                //array = LoadTableInEditor(fullname, "");
                array = LoadTableInEditor(filename, path);
            }
            else
            {
                //array = ResourceCenter.instance.LoadFile(fullname, "");
                array = FileLoader.instance.LoadFile(filename, path);
            }

            /// LY edit end///
            //#endif

            return Load(array);
        }

        /// LY add begin ///
        public byte[] LoadTableInEditor(string name, string folder)
        {
            //return ReadFile(GetFileUrl(name, folder, string.Empty, false, false));
            byte[] data = null;

            string path = Application.dataPath;
            while (!Utility.ContainsFolder(path, "Pro"))
            {
                path = Path.GetDirectoryName(path);
            }
            path += "/Assets/";

            name = name.ToLower();

            string url = path;
            if (string.IsNullOrEmpty(folder) == false)
            {
                url = Path.Combine(path, folder) + "/";
            }

            url = "file://" + url + name;
            url = url.Replace("file://", "");

            if (File.Exists(url))
            {
                FileStream fs = File.OpenRead(url);
                data = new byte[fs.Length];
                fs.Read(data, 0, (int)fs.Length);
                fs.Close();
                fs.Dispose();
            }
            else
            {
#if UNITY_EDITOR
                Debug.LogError("File Not Exist : " + url);
#endif
            }

            return data;
        }
        /// LY add end ///

        public bool Load(byte[] array)
        {
            TableHeader header = new TableHeader();
            header.Load(array, 0);
            int size = header.AllSize;

            // TODO: check version

            Table.Loader loader = new Table.Loader(ref array, size);
            loader.Load(ref m_list);

            return true;
        }

        public List<T> GetList()
        {
            return m_list;
        }


        public void Clear()
        {
            m_list.Clear();
        }
    }

}
