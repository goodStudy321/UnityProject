using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class UnitHeadBar : NameBarBase
{
    public UnitHeadBar() { }
    #region �ֶ�
    private Unit mUnit = null;
    /// <summary>
    /// ������
    /// </summary>
    private UISlider mSlider = null;
    /// <summary>
    /// ͷ����
    /// </summary>
    private UITexture mHeadSpr = null;
    /// <summary>
    /// �ȼ�
    /// </summary>
    private UILabel mLevel = null;

    private GameObject star = null;
    /// <summary>
    /// ս����
    /// </summary>
    private UILabel mFightVal = null;
    /// <summary>
    /// Ѫ����
    /// </summary>
    private UILabel mHpRadio = null;

    private UILabel mDesLab = null;

    private string headName = "xxx";
    #endregion

    #region ����
    /// <summary>
    /// ӵ����
    /// </summary>
    public Unit Owner
    {
        get { return mUnit; }
        set { mUnit = value; }
    }
    #endregion

    #region ˽�з���
    /// <summary>
    /// ��ʼ��Ѫ��
    /// </summary>
    private void InitSlider()
    {
        string msg = "��λͷ��Ѫ��UI";
        mSlider = ComTool.Get<UISlider>(transform, "HPSlider", msg);
        float curHp = mUnit.HP / ((mUnit.MaxHP) * 1f);
        if (mUnit.HP <= 0)
            mSlider.value = 1;
        else
            mSlider.value = curHp;
    }
    /// <summary>
    /// ���û��
    /// </summary>
    private void SetSlider()
    {
        if (mUnit.MaxHP == 0) return;
        float radio = mUnit.HP / ((mUnit.MaxHP) * 1f);
        mHpRadio.text = string.Format("{0}/{1}", mUnit.HP, mUnit.MaxHP);
        if (radio < 0)
            radio = 0;
        mSlider.value = Mathf.Lerp(mSlider.value, radio, Time.deltaTime * 10);
    }
    /// <summary>
    /// ����ͷ��
    /// </summary>
    private void SetHeadIcon()
    {
       if (mHeadSpr == null)   return;
       if (!User.instance.OtherRoleDic.ContainsKey(mUnit.UnitUID)) return;
       ActorData data = User.instance.OtherRoleDic[mUnit.UnitUID];
       if (data == null) return;
       headName = string.Format("head" + data.Category );
       AssetMgr.Instance.Load(headName, Suffix.Png, iconBack);
    }

    protected  void iconBack(Object go)
    {
        mHeadSpr.mainTexture = go as Texture2D;
    }
    /// <summary>
    /// ���õȼ�
    /// </summary>
    private void SetLevel()
    {
        if (mLevel == null)
            return;
        ActorData data = User.instance.OtherRoleDic[mUnit.UnitUID];
        if (data == null)
            return;
        GlobalData lvData = GlobalDataManager.instance.Find(90);
        int rolelv = int.Parse(lvData.num3);
        bool b = false;
        if (data.Level > rolelv)
        {
            rolelv = data.Level - rolelv;
            b = true;
        }
        else
        {
            rolelv = data.Level;
        }
      mLevel.text = rolelv.ToString();
        star.SetActive(b);
    }

    /// <summary>
    /// ����ս����
    /// </summary>
    private void SetFightVal()
    {
        if (mFightVal == null)
            return;
        int fgt = Mathf.CeilToInt(mUnit.FightVal);
        mFightVal.text = fgt.ToString();
    }
    /// <summary>
    /// ���ر�Ѫ��
    /// </summary>
    private void CheckClose()
    {
        if (mSlider.value > 0.0001f)
            return;
        mSlider.value = 0;
        this.Close();
        LockTarMgr.instance.DisTopBar(mUnit);
    }
    #endregion

    #region ��������
    protected override void LoadCallback(GameObject go)
    {
        base.LoadCallback(go);
        InitSlider();
        SetHeadIcon();
        SetLevel();
        SetFightVal();
        Update();
    }

    protected override void SetProperty()
    {
        TransTool.AddChild(UIMgr.Root, transform);
        string name = "ͷ����Ϣ";
        nameLbl = ComTool.Get<UILabel>(transform, "Name", name);
        mHeadSpr = ComTool.Get<UITexture>(transform, "Icon", name);
        mLevel = ComTool.Get<UILabel>(transform, "Level", name);
        mFightVal = ComTool.Get<UILabel>(transform, "Fighting", name);
        mHpRadio = ComTool.Get<UILabel>(transform, "HPSlider/HpRateLab", name);
        mDesLab = ComTool.Get<UILabel>(transform, "Fighting/Label",name);
        star = TransTool.Find(transform, "star", name);
        mDesLab.text = Phantom.Localization.Instance.GetDes(690036);
    }

    protected override bool Check()
    {
        if (transform == null) return false;
        if (mUnit == null) return false;
        if (mUnit.UnitTrans == null) return false;
        if (mSlider == null) return false;
        return true;
    }

    protected override void UpdateCustom()
    {
        SetSlider();
        CheckClose();
    }
    #endregion

    #region ���з���
    public override void Dispose()
    {
        base.Dispose();
        mUnit = null;
        mSlider = null;
        mHeadSpr = null;
        mLevel = null;
        mFightVal = null;
        mHpRadio = null;
        AssetMgr.Instance.Unload( headName,".png" , false);
    }

    /// <summary>
    /// �������ﵥλ��Ϣ��
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="name"></param>
    /// <returns></returns>
    public static UnitHeadBar Create(Unit unit, string name)
    {
        if (unit == null) return null;
        if (unit.Dead) return null;
        if (unit.UnitTrans == null) return null;
        UnitHeadBar bar = ObjPool.Instance.Get<UnitHeadBar>();
        bar.BarName = TopBarFty.UnitHeadBar;
        bar.Owner = unit;
        bar.Name = name;
        bar.Initialize();
        unit.HeadBar = bar;
        return bar;
    }
    #endregion
}
