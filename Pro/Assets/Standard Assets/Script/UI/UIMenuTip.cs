using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

//[ExecuteInEditMode]
[AddComponentMenu("NGUI/Interaction/Menu Tip")]

public class UIMenuTip : UIWidgetContainer
{

    public UIAtlas Atlas;

    public int mTypeIndex = 0;

    public int TypeIndex { get { return mTypeIndex; } }

    public bool mIsIndex = false;

    public enum PosType
    {
        Auto = 0,
        Left,
        Right,
        Top,
        Bottom
    }

    public PosType mPType = PosType.Auto;

    public List<string> items = new List<string>();
    public List<string> icons = new List<string>();
    public List<string> custom = new List<string>();
    public List<int> customIndex = new List<int>();
    public List<bool> actions = new List<bool>();


    private Camera UICamera = null;

    private bool mIsActive = true;
    public bool IsActive { set { mIsActive = value; } }

    public bool IsEnabled
    {
        get
        {
            return enabled;
        }
        set
        {
            enabled = value;
            mIsActive = value;
        }
    }

    private Vector3 mClickPos;

    public void AddItem(string value)
    {
        AddItem(value, false);
    }

    public void AddItem(string value, bool status)
    {
        items.Add(value);
        actions.Add(status);
    }

    public void UpdateAction(int index, bool status)
    {
        if (actions.Count <= index) return;
        actions[index] = status;
    }
    

    public void Clear()
    {
        while(items.Count > 0 )
        {
            items.RemoveAt(items.Count - 1);
        }
        while (actions.Count > 0)
        {
            actions.RemoveAt(actions.Count - 1);
        }
    }

    private void Start()
    {
        GameObject go = GameObject.Find("UI Root");
        if (go != null)
        {
            Transform trans = go.transform.Find("Camera");
            if (trans != null)
                UICamera = trans.GetComponent<Camera>();
        }
     }

    /**
    private void OnDisable()
    {
        for(int i = 0; i < actions.Count; i ++)
        {
            actions[i] = false;
        }
    }
    */

    private void OnClick()
    {
        if (!enabled) return;
        if (!mIsActive) return;
        Vector3 pos = GetClickTargetPos();
        //pos = UIMgr.Cam.ScreenToWorldPoint(pos);
        pos = UICamera.ScreenToWorldPoint(pos);
        pos.z = 0;
        mClickPos = pos;
        //UIMgr.Open(UIName.UIMenuTip, OpenUI);
        OpenUI();
    }

    private Vector3 GetClickTargetPos()
    {
        if (Application.platform == RuntimePlatform.WindowsEditor || Application.platform == RuntimePlatform.WindowsPlayer
            || Application.platform == RuntimePlatform.OSXEditor || Application.platform == RuntimePlatform.OSXPlayer)
        {
            return Input.mousePosition;
        }
        return Input.GetTouch(0).position;
    }

    private void OpenUI()
    {
        EventMgr.Trigger("OpenUIToName", "UIMenuTip");
        List<string> menus = new List<string>();
        List<string> pics = new List<string>();
        GetCustom(ref menus, ref pics);
        if (menus.Count == 0)
            EventMgr.Trigger("UpdteaMenuTip", transform, mTypeIndex, mClickPos, items, icons, actions, (int)mPType);
        else
            EventMgr.Trigger("UpdteaMenuTip", transform, mTypeIndex, mClickPos, menus, pics, actions, (int)mPType);
    }

    private void GetCustom(ref List<string> menus, ref List<string> pics)
    {
        if (!mIsIndex)
        {
            for(int i = 0; i < custom.Count; i ++)
            {
                int index = items.IndexOf(custom[i]);
                if(index != -1 )
                {
                    menus.Add(items[i]);
                    pics.Add(icons.Count > index ? icons[index] : string.Empty);
                }
            }
        }
        else
        {
            for(int i = 0; i < customIndex.Count; i ++)
            {
                int index = customIndex[i];
                if(items.Count > index)
                {
                    menus.Add(items[index]);
                    pics.Add(icons.Count > index ? icons[index] : string.Empty);
                }
            }
        }
    }

    private void OnDestroy()
    {
    }
}
