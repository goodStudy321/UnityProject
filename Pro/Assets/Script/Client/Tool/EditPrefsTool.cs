#if UNITY_EDITOR
using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;



namespace Loong.Game
{
    /*
     * 通过类型和属性名称组合成新名称
     * 将新名称作为偏好设置键值/属性
     */

    /// <summary>
    /// AU:Loong
    /// TM:2013.12.5
    /// BG:编辑器偏好属性设置工具
    /// </summary>
    public static class EditPrefsTool
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
        /// 获取类型的编辑器属性值
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        /// <param name="key">属性名称</param>
        /// <returns></returns>
        public static string GetKey<T>(string key)
        {
            return GetKey(typeof(T), key);
        }

        /// <summary>
        /// 获取类型的编辑器属性值
        /// </summary>
        /// <param name="type">类型</param>
        /// <param name="key">属性名称</param>
        /// <returns></returns>
        public static string GetKey(Type type, string key)
        {
            if (type == null) return key;
            string typeName = type.FullName;
            string fullKey = string.Format("{0}{1}", typeName, key);
            return fullKey;
        }

        #region 获取bool型属性值
        /// <summary>
        /// 获取对象类型的编辑器bool属性值
        /// </summary>
        /// <param name="obj">对象</param>
        /// <param name="key">属性名称</param>
        /// <param name="defaultValue"></param>
        /// <returns></returns>
        public static bool GetBool(object obj, string key, bool defaultValue = false)
        {
            if (obj == null) return defaultValue;
            return GetBool(obj.GetType(), key, defaultValue);
        }

        /// <summary>
        /// 获取类型的编辑器bool属性值
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        /// <param name="key">属性名称</param>
        /// <param name="defaultValue">默认值:false</param>
        /// <returns></returns>
        public static bool GetBool<T>(string key, bool defaultValue = false)
        {
            return GetBool(typeof(T), key, defaultValue);
        }

        /// <summary>
        /// 获取类型的编辑器bool属性值
        /// </summary>
        /// <param name="type">类型</param>
        /// <param name="key">属性名称</param>
        /// <param name="defaultValue"></param>
        /// <returns></returns>
        public static bool GetBool(Type type, string key, bool defaultValue = false)
        {
            string fullKey = GetKey(type, key);
            if (EditorPrefs.HasKey(fullKey))
            {
                return EditorPrefs.GetBool(fullKey);
            }
            else
            {
                EditorPrefs.SetBool(fullKey, defaultValue);
                return defaultValue;
            }
        }
        #endregion

        #region 获取浮点型属性值
        /// <summary>
        /// 获取对象类型的编辑器float属性值
        /// </summary>
        /// <param name="obj">对象</param>
        /// <param name="key">属性名称</param>
        /// <param name="defaultValue"></param>
        /// <returns></returns>
        public static float GetFloat(object obj, string key, float defaultValue = 0)
        {
            if (obj == null) return defaultValue;
            return GetFloat(obj.GetType(), key, defaultValue);
        }

        /// <summary>
        /// 获取类型的编辑器float属性值
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        /// <param name="key">属性名称</param>
        /// <param name="defaultValue">默认值:0</param>
        /// <returns></returns>
        public static float GetFloat<T>(string key, float defaultValue = 0)
        {
            return GetFloat(typeof(T), key, defaultValue);
        }

        /// <summary>
        /// 获取类型的编辑器float属性值
        /// </summary>
        /// <param name="type">类型</param>
        /// <param name="key">属性名称</param>
        /// <param name="defaultValue"></param>
        /// <returns></returns>
        public static float GetFloat(Type type, string key, float defaultValue = 0)
        {
            string fullKey = GetKey(type, key);
            if (EditorPrefs.HasKey(fullKey))
            {
                return EditorPrefs.GetFloat(fullKey);
            }
            else
            {
                EditorPrefs.SetFloat(fullKey, defaultValue);
                return defaultValue;
            }
        }
        #endregion

        #region 获取整型属性值
        /// <summary>
        /// 获取对象类型的编辑器int属性值
        /// </summary>
        /// <param name="obj">对象</param>
        /// <param name="key">属性名称</param>
        /// <param name="defaultValue">默认值:0</param>
        /// <returns></returns>
        public static int GetInt(object obj, string key, int defaultValue = 0)
        {
            if (obj == null) return defaultValue;
            return GetInt(obj.GetType(), key, defaultValue);
        }

        /// <summary>
        /// 获取类型的编辑器int属性值
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        /// <param name="key">属性名称</param>
        /// <param name="defaultValue">默认值:0</param>
        /// <returns></returns>
        public static int GetInt<T>(string key, int defaultValue = 0)
        {
            return GetInt(typeof(T), key, defaultValue);
        }

        /// <summary>
        /// 获取类型的编辑器int属性值
        /// </summary>
        /// <param name="type">类型</param>
        /// <param name="key">属性名称</param>
        /// <param name="defaultValue">默认值:0</param>
        /// <returns></returns>
        public static int GetInt(Type type, string key, int defaultValue = 0)
        {
            string fullKey = GetKey(type, key);
            if (EditorPrefs.HasKey(fullKey))
            {
                return EditorPrefs.GetInt(fullKey);
            }
            else
            {
                EditorPrefs.SetInt(fullKey, defaultValue);
                return defaultValue;
            }
        }
        #endregion

        #region 获取字符串型属性值
        /// <summary>
        /// 获取对象类型的编辑器string属性值
        /// </summary>
        /// <param name="obj">对象</param>
        /// <param name="key">属性名称</param>
        /// <param name="defaultValue">默认值:""</param>
        /// <returns></returns>
        public static string GetString(object obj, string key, string defaultValue = "")
        {
            if (obj == null) return defaultValue;
            return GetString(obj.GetType(), key, defaultValue);
        }

        /// <summary>
        /// 获取类型的编辑器string属性值
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        /// <param name="key">属性名称</param>
        /// <param name="defaultValue">默认值:""</param>
        /// <returns></returns>
        public static string GetString<T>(string key, string defaultValue = "")
        {
            return GetString(typeof(T), key, defaultValue);
        }

        /// <summary>
        /// 获取类型的编辑器string属性值
        /// </summary>
        /// <param name="type">类型</param>
        /// <param name="key">属性名称</param>
        /// <param name="defaultValue">默认值:""</param>
        /// <returns></returns>
        public static string GetString(Type type, string key, string defaultValue = "")
        {
            string fullKey = GetKey(type, key);
            if (EditorPrefs.HasKey(fullKey))
            {
                return EditorPrefs.GetString(fullKey);
            }
            else
            {
                EditorPrefs.SetString(fullKey, defaultValue);
                return defaultValue;
            }
        }
        #endregion

        #region 设置bool型属性值

        /// <summary>
        /// 设置对象类型的编辑器bool属性值
        /// </summary>
        /// <param name="obj">对象</param>
        /// <param name="key">属性名称</param>
        /// <param name="value">值</param>
        public static void SetBool(object obj, string key, bool value)
        {
            if (obj == null) return;
            SetBool(obj.GetType(), key, value);
        }

        /// <summary>
        /// 设置类型的编辑器bool属性值
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        /// <param name="key">属性名称</param>
        /// <param name="value">值</param>
        public static void SetBool<T>(string key, bool value)
        {
            SetBool(typeof(T), key, value);
        }

        /// <summary>
        /// 设置类型的编辑器bool属性值
        /// </summary>
        /// <param name="type">类型</param>
        /// <param name="key">属性名称</param>
        /// <param name="value">值</param>
        public static void SetBool(Type type, string key, bool value)
        {
            string fullKey = GetKey(type, key);
            EditorPrefs.SetBool(fullKey, value);
        }
        #endregion

        #region 设置浮点型属性值
        /// <summary>
        /// 设置对象类型的编辑器float属性值
        /// </summary>
        /// <param name="obj">对象</param>
        /// <param name="key">属性名称</param>
        /// <param name="value">值</param>
        public static void SetFloat(object obj, string key, float value)
        {
            if (obj == null) return;
            SetFloat(obj.GetType(), key, value);
        }

        /// <summary>
        /// 设置类型的编辑器float属性值
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        /// <param name="key">属性名称</param>
        /// <param name="value">值</param>
        public static void SetFloat<T>(string key, float value)
        {
            SetFloat(typeof(T), key, value);
        }

        /// <summary>
        /// 设置类型的编辑器float属性值
        /// </summary>
        /// <param name="type">类型</param>
        /// <param name="key">属性名称</param>
        /// <param name="value">值</param>
        public static void SetFloat(Type type, string key, float value)
        {
            string fullKey = GetKey(type, key);
            EditorPrefs.SetFloat(fullKey, value);
        }
        #endregion

        #region 设置整型属性值
        /// <summary>
        /// 设置对象类型的编辑器int属性值
        /// </summary>
        /// <param name="obj">对象</param>
        /// <param name="key">属性名称</param>
        /// <param name="value">值</param>
        public static void SetInt(object obj, string key, int value)
        {
            if (obj == null) return;
            SetInt(obj.GetType(), key, value);
        }

        /// <summary>
        /// 设置类型的编辑器int属性值
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        /// <param name="key">属性名称</param>
        /// <param name="value">值</param>
        public static void SetInt<T>(string key, int value)
        {
            SetInt(typeof(T), key, value);
        }

        /// <summary>
        /// 设置类型的编辑器int属性值
        /// </summary>
        /// <param name="type">类型</param>
        /// <param name="key">属性名称</param>
        /// <param name="value">值</param>
        public static void SetInt(Type type, string key, int value)
        {
            string fullKey = GetKey(type, key);
            EditorPrefs.SetInt(fullKey, value);
        }
        #endregion

        #region 设置字符串型属性值
        /// <summary>
        /// 设置对象类型的编辑器string属性值
        /// </summary>
        /// <param name="obj">对象</param>
        /// <param name="key">属性名称</param>
        /// <param name="value">值</param>
        public static void SetString(object obj, string key, string value)
        {
            if (obj == null) return;
            SetString(obj.GetType(), key, value);
        }

        /// <summary>
        /// 设置类型的编辑器string属性值
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        /// <param name="key">属性名称</param>
        /// <param name="value">值</param>
        public static void SetString<T>(string key, string value)
        {
            SetString(typeof(T), key, value);
        }

        /// <summary>
        /// 设置类型的编辑器string属性值
        /// </summary>
        /// <param name="type">类型</param>
        /// <param name="key">属性名称</param>
        /// <param name="value">值</param>
        public static void SetString(Type type, string key, string value)
        {
            string fullKey = GetKey(type, key);
            EditorPrefs.SetString(fullKey, value);
        }
        #endregion
        /// <summary>
        /// 删除对象类型的属性值
        /// </summary>
        /// <param name="obj">对象</param>
        /// <param name="key">属性名称</param>
        public static void Delete(object obj, string key)
        {
            if (obj == null) return;
            Delete(obj.GetType(), key);
        }

        /// <summary>
        /// 删除属性值
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        /// <param name="key">属性名称</param>
        public static void Delete<T>(string key)
        {
            Delete(typeof(T), key);
        }

        /// <summary>
        /// 删除属性值
        /// </summary>
        /// <param name="type">类型</param>
        /// <param name="key">属性名称</param>
        public static void Delete(Type type, string key)
        {
            string fullKey = GetKey(type, key);
            EditorPrefs.DeleteKey(fullKey);
        }
        #endregion
    }
}
#endif