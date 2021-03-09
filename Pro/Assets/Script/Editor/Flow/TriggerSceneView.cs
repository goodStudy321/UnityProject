using System;
using Phantom;
using System.IO;
using Loong.Edit;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;


/*
 *Loong 2015.11.7 整理
 */

public class TriggerSceneView : SelectViewBase<SelectTriggerInfo>
{

    private string assetDir = "Assets/Pkg/FlowTree";
    #region 字段

    public string AssetDir
    {
        get { return assetDir; }
        set { assetDir = value; }
    }

    #endregion

    #region 属性

    #endregion

    #region 私有方法

    private void EditorTree(SelectInfo info)
    {
        var sti = info as SelectTriggerInfo;
        var fn = sti.FlowTree;
        var cur = Directory.GetCurrentDirectory();
        var path = cur + "/" + AssetDir + "/" + fn;
        if (File.Exists(path))
        {
            var ft = new FlowChart();
            ft.ReadFromFile(path);
            Win.Get<TriggerEditView>().EditTree(ft);
            Win.Switch<TriggerEditView>();
        }
        else
        {
            EditorUtility.DisplayDialog("", "流程树不存在，请先创建", "确定");
        }
    }

    private void Create()
    {
        string name = "FTI";
        string path = EditorUtility.SaveFilePanelInProject("保存数据", name, "bytes", "", AssetDir);
        if (string.IsNullOrEmpty(path))
        {
            ShowTip("已取消");
        }
        else
        {
            var fn = Path.GetFileName(path);
            var info = new SelectTriggerInfo();
            info.FlowTree = fn;
            var ft = new FlowChart();
            ft.name = Path.GetFileNameWithoutExtension(fn);
            var curDir = Directory.GetCurrentDirectory();
            var fullPath = Path.Combine(curDir, path);
            ft.Save(fullPath);
            infos.Add(info);
        }
    }


    private void ToBytes()
    {
        string fullDir = AssetPathUtil.CurDir + AssetDir;
        if (!Directory.Exists(fullDir)) return;
        var files = Directory.GetFiles(fullDir, "*.json");
        if (files == null || files.Length == 0) return;
        int length = files.Length;
        for (int i = 0; i < length; i++)
        {
            var file = files[i];
            var name = Path.GetFileNameWithoutExtension(file);
            var newName = name + Suffix.Bytes;
            var newPath = Path.Combine(fullDir, newName);
            var fi = new FileInfo(file);
            if (File.Exists(newPath)) File.Delete(newPath);
            fi.MoveTo(newPath);
        }
        AssetDatabase.Refresh();

        files = Directory.GetFiles(fullDir, "*" + Suffix.Bytes);
        length = files.Length;
        for (int i = 0; i < length; i++)
        {
            var file = files[i];
            file = file.Replace("\\", "/");
            var rpath = FileUtil.GetProjectRelativePath(file);
            ABTool.SetUnique(rpath);
        }
        UIEditTip.Log("已处理");
    }

    private void ToBin()
    {
        Save(true);
    }

    private void ReSave()
    {
        Save(false);
    }

    private void Save(bool fromJson)
    {
        var cur = Directory.GetCurrentDirectory();
        float length = infos.Count;
        for (int i = 0; i < length; i++)
        {
            var info = infos[i];
            var fn = info.FlowTree;
            ProgressBarUtil.Show("", fn, i / length);

            var path = cur + "/" + AssetDir + "/" + fn;

            if (File.Exists(path))
            {
                var ft = new FlowChart();
                if (fromJson)
                {
                    ft.ReadFromJson(path);
                }
                else
                {
                    ft.ReadFromFile(path);
                }

                ft.Save(path);
            }
            else
            {
                continue;
            }
        }
        ProgressBarUtil.Clear();
        AssetDatabase.Refresh();
    }

    #endregion

    #region 保护方法

    protected override void OnDestroyCustom()
    {
        editorHandler -= EditorTree;
    }

    protected override void ContextClickCustom(GenericMenu menu)
    {
        menu.AddItem("创建", false, Create);
    }
    protected override void SetInfos()
    {
        infos.Clear();
        string fullDir = AssetPathUtil.CurDir + AssetDir;
        if (!Directory.Exists(fullDir))
        {
            Directory.CreateDirectory(fullDir); return;
        }
        string filter = "*" + Suffix.Bytes;
        var files = Directory.GetFiles(fullDir, filter);
        if (files == null || files.Length == 0) return;
        int length = files.Length;
        for (int i = 0; i < length; i++)
        {
            var file = files[i];
            var name = Path.GetFileName(file);
            var info = new SelectTriggerInfo();
            info.FlowTree = name;
            infos.Add(info);
        }
    }

    protected override void Title()
    {
        BegTitle();
        var style = EditorStyles.toolbarButton;
        if (GUILayout.Button("json转bytes后缀", EditorStyles.toolbarButton, GUILayout.Width(200)))
        {
            DialogUtil.Show("", "确定转换将json后缀转为bytes", ToBytes);
        }
        if (TitleBtn("一键重新保存"))
        {
            DialogUtil.Show("", "确定保存", ReSave);
        }
        EndTitle();
    }


    #endregion

    #region 公开方法
    public override void OnCompiled()
    {
        SetInfos();
        editorHandler += EditorTree;
    }

    public override void Initialize()
    {
        base.Initialize();
        editorHandler += EditorTree;
    }

    public string GetPath(string name)
    {
        var path = AssetPathUtil.CurDir + AssetDir + "/" + name + Suffix.Bytes;
        return path;
    }
    #endregion
}