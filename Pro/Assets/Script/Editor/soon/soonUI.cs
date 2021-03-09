using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;


public class soonUI
{

    public static string BaseLua =
       @"类名 = {Name=""类名""}
local My = 类名
function My:Init()

end

function My:Clear()

end

return My
";
    public static string UILua =
       @"类名 = 继承:New{Name=""类名""}
local My = 类名
function My:初始化()
    --常用工具
    local tip = ""类名""
	local root = self.root
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local CG = ComTool.Get

--查找
    
    self:lnsr(""Add"")
    self:ClickEvent()
end

function My:lnsr( fun )

end

function My:ClickEvent()
   local US = UITool.SetLsnrSelf
--点击监听
end

--点击事件

function My:Clear()
    self:lnsr(""Remove"")

end

return My
";
}

public class ClientPrefabToScript : Editor
{
    public static string ObjName = "";
    private static Transform seclectGbj = null;
    private static string OneFindObjStr = "";
    private static string FindObjStr = "";
    private static string ClickEventStr = "";
    private static string ClickFunStr = "";

    private static string TFNameStr = "tf_";             //transform
    private static string TFCNameStr = "gbj_";           //gameObject
    private static string BtnNameStr = "btn_";           //butten
    private static string SprNameStr = "spr_";          //prite
    private static string LabNameStr = "lab_";           //uilabel
    private static string ToggleNameStr = "tog_";      //toggle
    private static string SliderNameStr = "sld_";       //slider
    private static string ScrollviewNameStr = "sv_";    //Scrollview
    private static string GridNameStr = "grid_";        //Grid
    private static string TextureNameStr = "tex_";      //Texture
    private static string StopFindStr = "_end";          //不再寻找此物体以下的子物体

    public static void CreateField(string root)
    {
        if (File.Exists(root))
        {
            Debug.LogError("文件已存在禁止重复创建");
        }
        else
        {
            Directory.CreateDirectory(root);
        }

    }

    public static void CreateBase(string ScriptName)
    {
        ObjName = ScriptName ;
        ClearData();
        if ((File.Exists(soonUIwin.root + "\\" + ObjName + ".lua")))
        {
            Debug.LogError("路径下存在此脚本");
        }
        else
        {
            CreateScript(ObjName, soonUI.BaseLua);
            Debug.Log("创建成功");
        }
    }
    public static void CreateUI(string ScriptName,GameObject game, string init,string tem )
    {
        ObjName = ScriptName;
        ClearData();
        if ((File.Exists(soonUIwin.root + "\\" + ObjName + ".lua")))
        {
            Debug.LogError("路径下存在此脚本");
        }
        else
        {
            seclectGbj = game.transform;
            GetObjsDefintion(seclectGbj);
            CreateScript(ObjName, soonUI.UILua, init,tem);
            Debug.Log("创建成功");
        }
    }
  

    public static void CreateScript(string scriptName, string text, string init = null,string tem = null)
    {
        string scriptPath = soonUIwin.root + "\\" + scriptName + ".lua";
        string classStr = text;
        classStr = classStr.Replace("类名", scriptName);
        if (init!= null)
        {
            classStr = classStr.Replace("继承", tem);
            classStr = classStr.Replace("初始化", init);
            classStr = classStr.Replace("--查找", FindObjStr);
            classStr = classStr.Replace("--点击监听", ClickEventStr);
            classStr = classStr.Replace("--点击事件", ClickFunStr);
        }
        FileStream file = new FileStream(scriptPath, FileMode.CreateNew);
        StreamWriter filew = new StreamWriter(file, System.Text.Encoding.UTF8);
        filew.Write(classStr);
        filew.Flush();
        filew.Close();
        file.Close();
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
    }
    public static void GetObjsDefintion(Transform tf)
    {
        if (tf != null)
        {
            for (int i = 0; i < tf.childCount; i++)
            {
                string m_name = string.Empty;
                string m_chilName = tf.GetChild(i).name;
                if (m_chilName.StartsWith(BtnNameStr))
                {
                    ObjPathHandle(tf.GetChild(i));
                    m_name = m_chilName.Replace(BtnNameStr, string.Empty);
                    NameHandle("UIButton",m_name);
                    ClickEventStr = string.Format("{0}   US(self.{1}, self.{2}Click, self)",ClickEventStr,m_name,m_name);
                    ClickFunStr = string.Format("{0}function My:{1}Click(go)\n     \nend\n\n",ClickFunStr, m_name);
                }
                else if (m_chilName.StartsWith(SprNameStr))
                {
                    ObjPathHandle(tf.GetChild(i));
                    m_name = m_chilName.Replace(SprNameStr, string.Empty);
                    NameHandle("UISprite", m_name);
                }
                else if (m_chilName.StartsWith(LabNameStr))
                {
                    ObjPathHandle(tf.GetChild(i));
                    m_name = m_chilName.Replace(LabNameStr, string.Empty);
                    NameHandle("UILabel",m_name);
                }
                else if (m_chilName.StartsWith(ToggleNameStr))
                {
                    ObjPathHandle(tf.GetChild(i));
                    m_name = m_chilName.Replace(ToggleNameStr, string.Empty);
                    NameHandle("UIToggle", m_name);
                    ClickEventStr = string.Format("{0}   US(self.{1}, self.{1}Click, self)\n", ClickEventStr, m_name, m_name);
                    ClickFunStr = string.Format("{0}function My:{1}Click(go)\n    if self.{1}.value then\n         \n   end \n\nend\n\n", ClickFunStr, m_name);
                }
                else if (m_chilName.StartsWith(SliderNameStr))
                {
                    ObjPathHandle(tf.GetChild(i));
                    m_name = m_chilName.Replace(SliderNameStr, string.Empty);
                    NameHandle("UISlider", m_name);
                 
                }
                else if (m_chilName.StartsWith(ScrollviewNameStr))
                {
                    ObjPathHandle(tf.GetChild(i));
                    m_name = m_chilName.Replace(ScrollviewNameStr, string.Empty);
                    NameHandle("UIScrollView", m_name);
                }
                else if (m_chilName.StartsWith(GridNameStr))
                {
                    ObjPathHandle(tf.GetChild(i));
                    m_name = m_chilName.Replace(GridNameStr, string.Empty);
                    NameHandle("UIGrid", m_name);
                }
                else if (m_chilName.StartsWith(TextureNameStr))
                {
                    ObjPathHandle(tf.GetChild(i));
                    m_name = m_chilName.Replace(TextureNameStr, string.Empty);
                    NameHandle("UITexture", m_name);
                }
                else if (m_chilName.StartsWith(TFNameStr))
                {
                    ObjPathHandle(tf.GetChild(i));
                    m_name = m_chilName.Replace(TFNameStr, string.Empty);
                    NameHandle("TF", m_name);
                }
                else if (m_chilName.StartsWith(TFCNameStr))
                {
                    ObjPathHandle(tf.GetChild(i));
                    m_name = m_chilName.Replace(TFCNameStr, string.Empty);
                    NameHandle("TFC", m_name);
                }  
                if (tf.GetChild(i).childCount > 0 && !m_chilName.EndsWith(StopFindStr))
                {
                    GetObjsDefintion(tf.GetChild(i));
                }
            }
        }
    }

    private static void ObjPathHandle(Transform transform)
    {
        if (OneFindObjStr=="")
        {
            OneFindObjStr = transform.name;
        }
        else
        {
            OneFindObjStr = transform.name + "/" + OneFindObjStr;
        }
        if (transform.parent != seclectGbj)
        {
            ObjPathHandle(transform.parent);
        }
    }

    public static void NameHandle(string type, string name)
    {
        if (type == "TF")
        {
            FindObjStr = string.Format("{0}    self.{1}=TF(root,\"{2}\",tip)\n", FindObjStr, name, OneFindObjStr);
        }
        else if (type == "TFC")
        {
            FindObjStr = string.Format("{0}    self.{1}=TFC(root,\"{2}\",tip)\n", FindObjStr, name, OneFindObjStr);
        }
        else
        {
            FindObjStr = string.Format("{0}    self.{1}=CG({2},root,\"{3}\",tip)\n", FindObjStr,name,type,OneFindObjStr);
        }
        OneFindObjStr = "";
    }

    public static void ClearData()
    {
        FindObjStr = "";
        ClickEventStr = "";
        ClickFunStr = "";

    }

}
