#if SDK_ANDROID_HG || SDK_ONESTORE_HG || SDK_SAMSUNG_HG
using Loong.Game;
using LuaInterface;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SdkPanel:MonoBehaviour
{
    private string des = "SdkPanel";
    private GameObject root = null;
    private GameObject permissionPanel = null;
    private GameObject termsPanel = null;

    private GameObject btnPermission = null;
    private GameObject btnTermsCheck = null;
    private GameObject btnPrivacyCheck = null;
    private GameObject btnMarketPrivacyCheck = null;
    private GameObject btnTermsSure = null;

    private GameObject termsCheck = null;
    private GameObject privacyCheck = null;
    private GameObject marketPrivacyCheck = null;

    private string permissionPanelPath = "permissionPanel";
    private string termsPanelPath = "termsPanel";

    private string btnPermissionPath = "permissionPanel/btn";
    private string btnTermsCheckPath = "termsPanel/v1/checkBg";
    private string btnPrivacyCheckPath = "termsPanel/v2/checkBg";
    private string btnMarketPrivacyCheckPath = "termsPanel/v3/checkBg";
    private string btnTermsSurePath = "termsPanel/sureBtn";

    private string termsCheckPath = "termsPanel/v1/checkBg/check";
    private string privacyCheckPath = "termsPanel/v2/checkBg/check";
    private string marktPrivacyCheckPath = "termsPanel/v3/checkBg/check";

    private bool isTermsCheck = false;
    private bool isPrivacyCheck = false;
    private bool isMarketPrivacyCheck = false;

    //1：未同意条款    2：同意条款
    private int termIndex = 1;


    private void Awake()
    {
        termIndex = PlayerPrefs.GetInt("TermIndex");
        if (termIndex <= 1)
        {
            Sdk.Instance.SetPermissionResult(2);
        }
        root = this.gameObject;

        permissionPanel = TransTool.Find(root, permissionPanelPath, des);
        termsPanel = TransTool.Find(root, termsPanelPath, des);

        btnPermission = TransTool.Find(root, btnPermissionPath, des);
        btnTermsCheck = TransTool.Find(root, btnTermsCheckPath, des);
        btnPrivacyCheck = TransTool.Find(root, btnPrivacyCheckPath, des);
        btnMarketPrivacyCheck = TransTool.Find(root, btnMarketPrivacyCheckPath, des);
        btnTermsSure = TransTool.Find(root, btnTermsSurePath, des);

        termsCheck = TransTool.Find(root, termsCheckPath, des);
        privacyCheck = TransTool.Find(root, privacyCheckPath, des);
        marketPrivacyCheck = TransTool.Find(root, marktPrivacyCheckPath, des);

        EventMgr.Add("SdkPermissionSuc", ShowTermsPanel);
        EventMgr.Add("SdkPermissionFail", ShowPerPanel);
    }

    private void Start()
    {
        termIndex = PlayerPrefs.GetInt("TermIndex");
        UITool.SetLsnrClick(root, btnPermissionPath, des, OnClickBtnPermission);
        UITool.SetLsnrClick(root, btnTermsCheckPath, des, OnClickBtnTermsCheck);
        UITool.SetLsnrClick(root, btnPrivacyCheckPath, des, OnClickBtnPrivacyCheck);
        UITool.SetLsnrClick(root, btnMarketPrivacyCheckPath, des, OnClickBtnMarketPrivacyCheck);
        UITool.SetLsnrClick(root, btnTermsSurePath, des, OnClickBtnTermsSure);
        IsShowTermsSureBtn(false, false,false);
        termsCheck.SetActive(false);
        privacyCheck.SetActive(false);
        marketPrivacyCheck.SetActive(false);
        int sdkInitState = Sdk.Instance.GetPermissionResult();
        Debug.Log("Unity sdk permissionResult: " + sdkInitState + "   termIndex: " + termIndex);
        if (sdkInitState == 0)
        {
            SetPanleState(true);
            SetPermissionPanelState(true);
        }
        else if (sdkInitState == 1 && termIndex == 2)
        {
            OnClickBtnTermsSure(root);
        }
        else if (termIndex <= 1)
        {
            SetPanleState(true);
            SetPermissionPanelState(false);
        }
    }

    private void ShowTermsPanel(params object[] args)
    {
        Debug.Log("unity 收到 成功获取全部权限");
        SetPermissionPanelState(false);
    }

    private void ShowPerPanel(params object[] args)
    {
        SetPermissionPanelState(true);
    }

    private void OnClickBtnPermission(GameObject go)
    {
        Sdk.Instance.OpenPermissionDialog();
        //测试用
        //EventMgr.Trigger("SdkPermissionSuc");
    }

    private void OnClickBtnTermsCheck(GameObject go)
    {
        
        isTermsCheck = !isTermsCheck;
        termsCheck.SetActive(isTermsCheck);
        IsShowTermsSureBtn(isTermsCheck, isPrivacyCheck,isMarketPrivacyCheck);
    }

    private void OnClickBtnPrivacyCheck(GameObject go)
    {
        isPrivacyCheck = !isPrivacyCheck;
        privacyCheck.SetActive(isPrivacyCheck);
        IsShowTermsSureBtn(isTermsCheck, isPrivacyCheck, isMarketPrivacyCheck);
    }

    private void OnClickBtnMarketPrivacyCheck(GameObject go)
    {
        isMarketPrivacyCheck = !isMarketPrivacyCheck;
        marketPrivacyCheck.SetActive(isMarketPrivacyCheck);
        IsShowTermsSureBtn(isTermsCheck, isPrivacyCheck, isMarketPrivacyCheck);
    }

    private void OnClickBtnTermsSure(GameObject go)
    {
        Sdk.Instance.SetPermissionResult(1);
        PlayerPrefs.SetInt("TermIndex", 2);
        EventMgr.Remove("SdkPermissionSuc", ShowTermsPanel);
        EventMgr.Remove("SdkPermissionFail", ShowPerPanel);
        Sdk.Instance.OnInitSdk();
        SetPanleState(false);
    }

    private void IsShowTermsSureBtn(bool isTCheck,bool isPCheck,bool isMarketPrivacyCheck)
    {
        bool ac = false;
        if (isTCheck && isPCheck)// && isMarketPrivacyCheck)
        {
            ac = true;
        }
        btnTermsSure.SetActive(ac);
    }

    private void SetPermissionPanelState(bool isActive)
    {
        permissionPanel.SetActive(isActive);
        termsPanel.SetActive(!isActive);
    }

    public void SetPanleState(bool isActive)
    {
        root.SetActive(isActive);
    }
}
#endif
