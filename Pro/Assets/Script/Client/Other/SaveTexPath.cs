using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;

public class SaveTexPath
{
    /// <summary>
    /// 保存图片到指定路径
    /// </summary>
    /// <param name="tex">图片</param>
    /// <param name="path">路径</param>
    /// <param name="png">是否png</param>
    /// <returns>true:保存成功</returns>
    public static bool Save(Texture2D tex, string path, bool png)
    {
        bool suc = true;
        try
        {

            byte[] bytes = png ? tex.EncodeToPNG() : tex.EncodeToJPG();
            File.WriteAllBytes(path, bytes);
        }
        catch (System.Exception e)
        {
            suc = false;
            Debug.LogErrorFormat("LGS ,save tex to:{0} ,err:{1}", path, e.Message);
        }
        return suc;
    }

}
