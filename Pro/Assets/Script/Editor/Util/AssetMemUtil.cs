using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using UnityEngine.Profiling;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Hello.Edit
{
    public static class AssetMemUtil
    {
        public static long GetTexMemSize(TextureImporter ti,Object tex)
        {
            if (tex == null) return 0;
            long size = Profiler.GetRuntimeMemorySizeLong(tex);
            float factor = 1f / 3f;
            if (ti.mipmapEnabled)
            {
                {
                    size = (long)(size * (1 - factor) / (0.5f + factor));
                }
            }
            else
            {
                if (!ti.isReadable)
                {
                    size = (long)(size * 0.5f);
                }
            }
            return size;
        }

        public static long GetMemSize(Object obj)
        {
            if (obj == null) return 0;
            string path = AssetDatabase.GetAssetPath(obj);
            return GetMemSize(path, obj);
        }

        public static long GetMemSize(string path)
        {
            var obj = AssetDatabase.LoadAssetAtPath<Object>(path);
            return GetMemSize(path, obj);
        }

        public static long GetMemSize(string path,Object obj)
        {
            if (obj == null) return 0L;
            if (string.IsNullOrEmpty(path)) return 0L;
            var size = 0L;
            var import = AssetImporter.GetAtPath(path);
            if(import is TextureImporter)
            {
                TextureImporter ti = import as TextureImporter;
                size = GetTexMemSize(ti, obj);
            }
            else
            {
                size = Profiler.GetRuntimeMemorySizeLong(obj);
            }
            return size;
        }
    }
}

