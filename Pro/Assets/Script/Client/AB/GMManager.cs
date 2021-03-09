using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;
using Phantom.Protocal;
using System;

public class GMManager
{
    public bool isGm = false;
    public static readonly GMManager instance = new GMManager();
    private GMManager()
    {
        EventMgr.Add("IsOpenGM", change);
    }
    public void change(params object[] args)
    {
        isGm = Convert.ToBoolean(args[0]);
    }
    public bool IsGm { set { isGm = value; } get { return isGm; } }
    public void OnSubmit(UIInput mInput)
    {
        string text = NGUIText.StripSymbols(mInput.value);
        OnSubmitText(text);
        mInput.value = "";
        mInput.isSelected = false;
    }

    public void OnSubmitText(string text)
    {
        if (!string.IsNullOrEmpty(text))
        {
            string[] contents = text.Split(',');
            if (contents.Length == 0)
            {
                UITip.Error("命令错误输出，正确格式为：type,args(多个参数以;隔开)");
                return;
            }
            if (contents.Length == 1)
            {
                //发送协议
                SendReqMes(contents[0], null);
            }
            else
            {
                //发送协议
                SendReqMes(contents[0], contents[1]);
            }
        }
    }

    /// <summary>
    /// GM命令
    /// </summary>
    /// <param name="type">类型</param>
    /// <param name="args">参数</param>
    public void SendReqMes(string type, string args)
    {
        UITip.Log("GM命令添加");
        m_role_gm_tos data = ObjPool.Instance.Get<m_role_gm_tos>();
        if (!string.IsNullOrEmpty(args)) type = type.Replace("\t", string.Empty);
        if (!string.IsNullOrEmpty(args)) args = args.Replace("\n", string.Empty);
        data.type = type;
        data.args = args;
        NetworkClient.Send<m_role_gm_tos>(data);
    }

    /// <summary>
    /// 断开连接
    /// </summary>
    public void Disconnect()
    {
        NetworkClient.Disconnect();
    }
}
