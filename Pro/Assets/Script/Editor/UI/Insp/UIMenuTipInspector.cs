using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(UIMenuTip), true)]
public class UIMenuTipInspector : UIWidgetContainerEditor
{
    enum IconType
    {
        Add,
        Remove,
        Draw
    }


    UIMenuTip mMenu;

    void OnEnable()
    {
        mMenu = target as UIMenuTip;
        BoxCollider coll = mMenu.gameObject.GetComponent<BoxCollider>();
        if (coll == null) mMenu.gameObject.AddComponent<BoxCollider>();
        int itemLen = mMenu.items.Count;
        int iconLen = mMenu.icons.Count;
        if (itemLen > iconLen)
        {
            for (int i = mMenu.icons.Count; i < mMenu.items.Count; i++) mMenu.icons.Add(string.Empty);
        }
        else if(itemLen < iconLen)
        {
            for (int i = iconLen - 1; i >= itemLen; i--) mMenu.icons.RemoveAt(i);
        }
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();
        NGUIEditorTools.SetLabelWidth(80f);
        DrawAtlas();
        DrawMenu();
        DrawIsIndex();
        DrawPosType();
        DrawTargetType();
        GUILayout.Space(6f);
        // DrawIconText();
    }

    private void DrawPosType()
    {
        UIMenuTip.PosType ht = mMenu.mPType;
        UIMenuTip.PosType type = (UIMenuTip.PosType)EditorGUILayout.EnumPopup("Pos Type:", ht);
        if (type != ht) mMenu.mPType = type;
    }

    private void DrawTargetType()
    {
        GUI.changed = false;
        int val = EditorGUILayout.IntField("TargetType:", mMenu.mTypeIndex, GUILayout.MinWidth(100f));

        if (GUI.changed)
        {
            mMenu.mTypeIndex = val;
        }
    }

    private  void DrawIsIndex()
    {
        bool isIndex = mMenu.mIsIndex;
        bool index = EditorGUILayout.Toggle("Input Index", isIndex);
        if (index != isIndex) mMenu.mIsIndex = index;
        if (isIndex)
        {
            DrawCurInput<int>(mMenu.customIndex);
        }
        else
        {
            DrawCurInput<string>(mMenu.custom);
        }
    }

    private void DrawCurInput<T>(List<T> list)
    {
        EditorGUI.BeginDisabledGroup(list.Count == 0);
        if (NGUIEditorTools.DrawHeader("Cur Input:", false))
        {
            string s = string.Empty;
            for (int i = 0; i < list.Count; i++)
            {
                s += list[i].ToString();
                if (i < list.Count - 1)
                    s += ", ";
            }
            GUILayout.Label(s);
        }
        EditorGUI.EndDisabledGroup();
    }

    #region Atlas
    private void DrawAtlas()
    {
        GUILayout.BeginHorizontal();
        if (NGUIEditorTools.DrawPrefixButton("Atlas")) ComponentSelector.Show<UIAtlas>(OnSelectAtlas);
        SerializedProperty atlas = NGUIEditorTools.DrawProperty("", serializedObject, "Atlas", GUILayout.MinWidth(20f));
        if (GUILayout.Button("Edit", GUILayout.Width(40f)))
        {
            if (atlas != null)
            {
                UIAtlas atl = atlas.objectReferenceValue as UIAtlas;
                NGUISettings.atlas = atl;
                if (atl != null) NGUIEditorTools.Select(atl.gameObject);
            }
        }
        GUILayout.EndHorizontal();
    }

    private void OnSelectAtlas(Object obj)
    {
        serializedObject.Update();
        SerializedProperty sp = serializedObject.FindProperty("Atlas");
        sp.objectReferenceValue = obj;
        serializedObject.ApplyModifiedProperties();
        NGUITools.SetDirty(serializedObject.targetObject);
        NGUISettings.atlas = obj as UIAtlas;
    }
    #endregion

    private void DrawMenu()
    {
        GUILayout.BeginVertical();
        string key = "Menus";
        if (!NGUIEditorTools.DrawHeader(key, key, false, false)) return;

        NGUIEditorTools.BeginContents(false);
        GUILayout.Space(2f);
        for (int i = 0; i < mMenu.items.Count; i ++)
        {
            string k = string.Format("Menu {0}", i);
            if (NGUIEditorTools.DrawHeader(k, k, false, true))
            {
                GUILayout.BeginVertical();
                NGUIEditorTools.BeginContents(false);
                string item = mMenu.items[i];
                string icon = mMenu.icons[i];
                GUILayout.BeginHorizontal();
                GUILayout.Label("Title:", GUILayout.Width(100));
                string title = EditorGUILayout.DelayedTextField(item);
                GUILayout.EndHorizontal();
                GUILayout.BeginHorizontal();
                GUILayout.Label("Icon:", GUILayout.Width(100));
                DrawIconSprite(IconType.Draw, i);
                if (GUILayout.Button("", "ToggleMixed", GUILayout.Width(20f))) mMenu.icons[i] = string.Empty;
                GUILayout.EndHorizontal();
                if (GUILayout.Button("-", GUILayout.Height(18)))
                {
                    mMenu.items.RemoveAt(i);
                    DrawIconSprite(IconType.Remove, i);
                    break;
                }
                if (!mMenu.items[i].Contains(title)) mMenu.items[i] = title;
                NGUIEditorTools.EndContents();
                GUILayout.EndVertical();
            }
        }
        GUILayout.Space(2);
        GUILayout.Space(2);
        if (GUILayout.Button("+"))
        {
            mMenu.items.Add(string.Empty);
            DrawIconSprite(IconType.Add);
        }

        NGUIEditorTools.EndContents();
        GUILayout.EndVertical();
    }
    #region select sprite
    private void DrawIconSprite(IconType type, int index = -1)
    {
        if (type == IconType.Draw)
        {
            string curSpriteName = mMenu.icons[index];
            if (GUILayout.Button(curSpriteName, "MiniPullDown"))
            {
               // SpriteSelector comp = ScriptableWizard.DisplayWizard<SpriteSelector>("Select a Sprite");
                NGUISettings.atlas = serializedObject.FindProperty("Atlas").objectReferenceValue as UIAtlas;

                SpriteSelector.Show((str) =>
                {
                    mMenu.icons[index] = str;
                });
                // NGUISettings.selectedSprite = curSpriteName;
            }

        }
        else if (type == IconType.Add)
        {
            mMenu.icons.Add(string.Empty);
        }
        else if (type == IconType.Remove)
        {
            mMenu.icons.RemoveAt(index);
        }
    }
    #endregion

}
