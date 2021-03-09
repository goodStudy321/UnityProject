using NPOI.SS.UserModel;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;
using Loong.Game;
using Loong.Edit;

public class FamilyWarTool : Editor
{
    [MenuItem("Developer Tools/导出帮战占领点数据")]  
    private static void ExportFamilyWarExcel()
    {
        string filePath = Path.GetFullPath("../table/B 帮战占领点.xls");
        Debug.Log("              " + filePath);

        IWorkbook resWorkbook = ExcelTool.GetWrokBook(filePath, "Sheet1");
        try
        {
            ISheet resSheet = resWorkbook.GetSheet("Sheet1");
            GameObject go = GameObject.Find("OccupPoint");
            OccupTrigger[] occupTriggers = go.GetComponentsInChildren<OccupTrigger>();

            for (int i = 0; i < occupTriggers.Length; i++)
            {
                int snCol = ExcelTool.GetColumn(resSheet, 0, "id");
                int hCol = ExcelTool.GetColumn(resSheet, 0, "坐标");
                int lCol = ExcelTool.GetColumn(resSheet, 0, "半径");
                ExcelTool.WriteInt(resSheet.GetRow(i+1), snCol, occupTriggers[i].Index);
                ExcelTool.WriteVector3(resSheet.GetRow(i+1), hCol, occupTriggers[i].transform.position, ',', 1);
                ExcelTool.WriteString(resSheet.GetRow(i+1), lCol, occupTriggers[i].GetComponent<SphereCollider>().radius.ToString());             
            }
            ExcelTool.Save(resWorkbook, filePath);
        }
        catch (System.Exception e)
        {
            UIEditTip.Error("XGY,写入Excel发生错误:{0}" , e.Message);
        }
        finally
        {
            if (resWorkbook != null) resWorkbook.Close();
        }
    }
}
