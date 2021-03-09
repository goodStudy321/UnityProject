using System;
using System.IO;
using Loong.Game;
using System.Text;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

using NPOI;
using NPOI.HSSF.UserModel;
using NPOI.SS.UserModel;

/*
 * 如有改动需求,请联系Loong
 * 如果必须改动,请知会Loong
*/

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2016.08.15
    /// BG:Excel工具
    /// </summary>
    public static class ExcelTool
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 获取工作簿
        /// </summary>
        /// <param name="filePath">文件路径</param>
        /// <param name="sheetName">表单名称</param>
        /// <returns></returns>
        public static IWorkbook GetWrokBook(string filePath, string sheetName)
        {
            if (!File.Exists(filePath))
            {
                UIEditTip.Error("Excel配置文件路径:{0},不存在", filePath);
                return null;
            }
            FileStream stream = null;
            IWorkbook workbook = null;
            try
            {
                stream = File.Open(filePath, FileMode.Open, FileAccess.ReadWrite);
                workbook = new HSSFWorkbook(stream);
                ISheet sheet = workbook.GetSheet(sheetName);
                if (sheet == null)
                {
                    UIEditTip.Error("Excel:{0}中不存在工作表:{1}", filePath, sheetName);
                }
            }
            catch (IOException)
            {
                UIEditTip.Error("读写Excel:{0}发生错误,原因可能如下:\n1,已经被打开\n2,被别的进程占用", filePath);
            }
            catch (System.Exception e)
            {
                UIEditTip.Error("写入解析文件{0},发生错误{1}", filePath, e.Message);
                workbook = null;
            }
            finally
            {
                if (stream != null) stream.Dispose();
            }
            return workbook;
        }

        /// <summary>
        /// 保存工作簿
        /// </summary>
        /// <param name="wrokbook"></param>
        public static void Save(IWorkbook wrokbook, string path)
        {
            if (wrokbook == null) return;
            if (string.IsNullOrEmpty(path))
            {
                UIEditTip.Error("Excel路径为空"); return;
            }
            if (File.Exists(path)) File.Delete(path);
            using (FileStream stream = new FileStream(path, FileMode.Create))
            {
                wrokbook.Write(stream);
            }
            wrokbook.Close();
            UIEditTip.Log("向Excel:{0}写入数据成功", path);
        }

        /// <summary>
        /// 打开Excel
        /// </summary>
        /// <param name="path"></param>
        public static void Open(string path)
        {
            if (string.IsNullOrEmpty(path)) return;
            string fullPath = Path.GetFullPath(path);
            if (File.Exists(fullPath))
            {
                ProcessUtil.Execute(fullPath, wairForExit: false);
                UIEditTip.Log("打开成功:{0}", fullPath);
            }
            else
            {
                UIEditTip.Error("Excel:{0},不存在", fullPath);
            }
        }

        /// <summary>
        /// 查找表单中某一行具有指定值的列号/如果没有找到返回-1
        /// </summary>
        /// <param name="sheet">表单</param>
        /// <param name="rowIdx">行号</param>
        /// <param name="value">值</param>
        /// <returns></returns>
        public static int GetColumn(ISheet sheet, int rowIdx, string value)
        {
            if (sheet == null) return -1;
            if (rowIdx > (sheet.PhysicalNumberOfRows - 1)) return -1;
            IRow row = sheet.GetRow(rowIdx);
            int length = row.Cells.Count;
            for (int i = 0; i < length; i++)
            {
                string target = row.Cells[i].ToString();
                if (target.Equals(value)) return i;
            }
            return -1;
        }

        /// <summary>
        /// 查找表单中某一列具有指定值的行号/如果没有找到返回-1
        /// </summary>
        /// <param name="sheet">表单</param>
        /// <param name="columnIndex">列号</param>
        /// <param name="value">值</param>
        /// <returns></returns>
        public static int GetRow(ISheet sheet, int columnIndex, string value)
        {
            if (sheet == null) return -1;
            IEnumerator rowEnum = sheet.GetRowEnumerator();
            int index = 0;
            while (rowEnum.MoveNext())
            {
                IRow row = rowEnum.Current as IRow;
                if (row == null) break;
                ICell cell = row.GetCell(columnIndex);
                if (cell == null) break;
                string str = cell.ToString();
                if (str.Equals(value))
                {
                    return index;
                }
                index++;
            }
            return -1;
        }

        /// <summary>
        /// 通过指定的分隔符将字符串转化为三维向量
        /// 因为服务器要整型,为了精度将小数保留一位并乘以100转换为整数,所以这里要反过来乘以0.01转换为浮点型
        /// </summary>
        /// <param name="value">字符串</param>
        /// <param name="split">分隔符</param>
        /// <param name="scale">缩放</param>
        /// <param name="ignoreY">忽略Y轴</param>
        /// <returns></returns>
        public static Vector3 StringToVector3(string value, char split, float scale, bool ignoreY = false)
        {
            if (string.IsNullOrEmpty(value)) return Vector3.zero;
            Vector3 vec = Vector3.zero;
            if (scale == 0) scale = 1;
            float factor = 1 / scale;
            string[] arr = value.Split(split);
            if (ignoreY)
            {
                if (arr.Length == 2)
                {
                    float y = 1;
                    float x = float.Parse(arr[0]);
                    float z = float.Parse(arr[1]);
                    x *= factor; z *= factor;
                    vec.Set(x, y, z);
                }
            }
            else
            {
                if (arr.Length == 3)
                {
                    float x = float.Parse(arr[0]);
                    float y = float.Parse(arr[1]);
                    float z = float.Parse(arr[2]);
                    x *= factor; y *= factor; z *= factor;
                    vec.Set(x, y, z);
                }
            }
            return vec;
        }


        /// <summary>
        /// 通过指定的分隔符将三维向量转化为字符串
        /// 因为服务器要整型,为了精度将小数保留一位并乘以100转换为整数
        /// </summary>
        /// <param name="value">三维向量</param>
        /// <param name="split">分隔符</param>
        /// <param name="scale">缩放</param>
        /// <param name="ignoreY">忽略Y轴</param>
        /// <returns></returns>
        public static string Vector3ToString(Vector3 value, char split, uint scale, bool ignoreY = false)
        {
            StringBuilder sb = new StringBuilder();
            float x = value.x * scale;
            float y = value.y * scale;
            float z = value.z * scale;
            int vX = (int)x;
            int vY = (int)y;
            int vZ = (int)z;

            sb.Append(vX).Append(split);
            if (!ignoreY) sb.Append(vY).Append(split);
            sb.Append(vZ);
            return sb.ToString();
        }
        #region 读取
        /// <summary>
        /// 从单元格里 读取字符串并同通过分隔符将其转换为三维向量
        /// </summary>
        /// <param name="row">行</param>
        /// <param name="index">列号</param>
        /// <param name="split">分隔符</param>
        /// <param name="scale">缩放</param>
        /// <param name="ignoreY">忽略Y轴</param>
        /// <returns></returns>
        public static Vector3 ReadVector3(IRow row, int index, char split, float scale, bool ignoreY = false)
        {
            ICell cell = row.GetCell(index);
            if (cell == null) return Vector3.zero;
            return ExcelTool.StringToVector3(cell.ToString(), split, scale, ignoreY);
        }

        /// <summary>
        /// 从单元格 读取字符
        /// </summary>
        /// <param name="row">行</param>
        /// <param name="index">列号</param>
        /// <returns></returns>
        public static string ReadString(IRow row, int index)
        {
            ICell cell = row.GetCell(index);
            if (cell == null) return "";
            string value = cell.ToString();
            return value;
        }

        /// <summary>
        /// 从单元格里 读取字符串并将其转换为整型
        /// </summary>
        /// <param name="row">行</param>
        /// <param name="index">列号</param>
        /// <returns></returns>
        public static int ReadInt(IRow row, int index)
        {
            ICell cell = row.GetCell(index);
            if (cell == null) return 0;
            string value = cell.ToString();
            return int.Parse(value);
        }

        /// <summary>
        /// 从单元格里 读取字符串并通过分隔符将其转换为整型列表
        /// </summary>
        /// <param name="row"></param>
        /// <param name="index"></param>
        /// <param name="split"></param>
        /// <returns></returns>
        public static List<int> ReadInts(IRow row, int index, char split)
        {
            ICell cell = row.GetCell(index);
            if (cell == null) return null;
            string value = cell.ToString();
            if (string.IsNullOrEmpty(value)) return null;
            List<int> ints = new List<int>();
            string[] arr = value.Split(split);
            int length = arr.Length;
            for (int i = 0; i < length; i++)
            {
                string str = arr[i];
                int target = 0;
                if (int.TryParse(str, out target)) ints.Add(target);
            }
            return ints;
        }

        #endregion

        #region 写入
        /// <summary>
        /// 将三维向量 转化为为指定格式字符串后 写入单元格
        /// </summary>
        /// <param name="row">行</param>
        /// <param name="index">列号</param>
        /// <param name="value">向量值</param>
        /// <param name="split">分隔符</param>
        /// <param name="scale">缩放</param>
        /// <param name="ignoreY">忽略Y轴</param>
        /// <returns></returns>
        public static void WriteVector3(IRow row, int index, Vector3 value, char split, uint scale, bool ignoreY = false)
        {
            ICell cell = row.GetCell(index);
            if (cell == null) cell = row.CreateCell(index);
            string str = ExcelTool.Vector3ToString(value, split, scale, ignoreY);
            cell.SetCellValue(str);
        }

        /// <summary>
        /// 将字符写入指定行指定列的单元格
        /// </summary>
        /// <param name="row">行</param>
        /// <param name="index">列号</param>
        /// <param name="value">字符</param>
        public static void WriteString(IRow row, int index, string value)
        {
            ICell cell = row.GetCell(index);
            if (cell == null) cell = row.CreateCell(index);
            cell.SetCellValue(value);
        }

        /// <summary>
        /// 将整型值 转化为字符串后 写入单元格
        /// </summary>
        /// <param name="row">行</param>
        /// <param name="index">列号</param>
        /// <param name="value">整型值</param>
        /// <returns></returns>
        public static void WriteInt(IRow row, int index, int value)
        {
            ICell cell = row.GetCell(index);
            if (cell == null) cell = row.CreateCell(index);
            cell.SetCellValue(value);
        }

        /// <summary>
        /// 将整型列表 转化为为指定格式字符串后 写入单元格
        /// </summary>
        /// <param name="row">行</param>
        /// <param name="index">列号</param>
        /// <param name="value">整型列表</param>
        /// <param name="split">分隔符</param>
        public static void WriteInts(IRow row, int index, List<int> value, char split)
        {
            ICell cell = row.GetCell(index);
            if (cell == null) cell = row.CreateCell(index);
            if (value == null) return;
            int length = value.Count;
            if (length == 0) return;
            if (length == 1)
            {
                cell.SetCellValue(value[0].ToString());
            }
            else
            {
                StringBuilder sb = new StringBuilder();
                int appendLen = length - 1;
                for (int i = 0; i < appendLen; i++)
                {
                    sb.Append(value[i]).Append(split);
                }
                sb.Append(value[appendLen]);
                cell.SetCellValue(sb.ToString());
            }
        }

        /// <summary>
        /// 设置列字典
        /// </summary>
        /// <param name="sheet"></param>
        /// <param name="columnDic"></param>
        public static void SetColumnDic(ISheet sheet, Dictionary<string, int> columnDic)
        {
            if (sheet == null) return;
            if (columnDic == null) return;
            if (columnDic.Count == 0) return;
            IRow row = sheet.GetRow(0);
            int length = row.Cells.Count;
            for (int i = 0; i < length; i++)
            {
                string key = row.Cells[i].ToString(); ;
                if (!columnDic.ContainsKey(key)) continue;
                columnDic[key] = i;
            }
        }
        #endregion
        #endregion
    }
}