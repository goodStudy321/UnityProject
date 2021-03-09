using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using Loong.Game;

public class SlectCreateUnit : EditorWindow
{
    #region 私有变量
    private Vector2 mScrollPos = Vector2.zero;
    //角色ID列表
    List<string> mRoleIdList = new List<string>();
    //怪物ID列表
    List<string> mMonsterList = new List<string>();
    //宠物ID列表
    List<string> mPetList = new List<string>();
    //法宝ID列表
    List<string> mMWeaponList = new List<string>();
    //NPC ID列表
    List<string> mNPCList = new List<string>();

    string[] mTypeArray = new string[] { "角色", "怪物", "宠物", "法宝" ,"NPC"};
    Dictionary<string, UnitType> mTypeStrDic = new Dictionary<string, UnitType>();
    Dictionary<UnitType, List<string>> mCurDic = new Dictionary<UnitType, List<string>>();

    //当前控制单位类型
    string curCtrlType;
    //当前敌人类型
    string curEnemyType;
    
    //id列表（过滤同一模型）
    List<string> mKeyList = new List<string>();
    //角色Id
    string roleId;
    string roleIdTmp;
    int rSltIndex = 0;//控制单位选择索引
    Vector2 rScrollPos = Vector2.zero;//scrollviewPosition
    //怪物Id
    string enemyId;
    string enemyIdTmp;
    int eSltIndex = 0;//怪物选择索引
    Vector2 eScrollPos = Vector2.zero;//scrollviewPosition
    //技能相关

    /// <summary>
    /// 编辑器输入敌人数量
    /// </summary>
    public static int CreateCount = 1;

    #endregion

    #region 私有方法
    /// <summary>
    /// 设置窗口信息
    /// </summary>
    private void SetWinInfo()
    {
        this.titleContent = new GUIContent("动作技能编辑器");
        this.minSize = new Vector2(776, 710);
    }
    /// <summary>
    /// 初始化类型字典
    /// </summary>
    private void InitTypeStrDic()
    {
        mTypeStrDic.Clear();
        mTypeStrDic.Add(mTypeArray[0], UnitType.Role);
        mTypeStrDic.Add(mTypeArray[1], UnitType.Monster);
        mTypeStrDic.Add(mTypeArray[2], UnitType.Pet);
        mTypeStrDic.Add(mTypeArray[3], UnitType.MagicWeapon);
        mTypeStrDic.Add(mTypeArray[4], UnitType.NPC);
    }
    /// <summary>
    /// 初始化
    /// </summary>
    private void InitList()
    {
        AddRole();
        AddMonster();
        AddPet();
        AddMagicWeapon();
        AddNPC();
    }

    /// <summary>
    /// 初始化类型
    /// </summary>
    private void InitType()
    {
        curCtrlType = curEnemyType = mTypeArray[0];
    }

    /// <summary>
    /// 初始化初始ID
    /// </summary>
    private void InitOriginID()
    {
        UnitType unitType = mTypeStrDic[curCtrlType];
        List<string> strList = mCurDic[unitType];
        if (strList.Count == 0)
            return;
        roleId = enemyId = strList[0];
    }

    /// <summary>
    /// 添加角色
    /// </summary>
    private void AddRole()
    {
        mRoleIdList.Clear();
        List<RoleAtt> roleAttList = RoleAttManager.instance.GetList();
        for (int i = 0; i < roleAttList.Count; i++)
        {
            ushort modelId = roleAttList[i].modelId;
            string key = roleAttList[i].sex.ToString() + roleAttList[i].profession.ToString();
            if (mKeyList.Contains(key))
                continue;
            mKeyList.Add(key);
            RoleBase roleBase = RoleBaseManager.instance.Find(modelId);
            if (roleBase == null)
                continue;
            mRoleIdList.Add(roleBase.roleName + "_" + roleAttList[i].id.ToString());
        }
        mCurDic.Add(UnitType.Role, mRoleIdList);
    }

    /// <summary>
    /// 添加怪物
    /// </summary>
    private void AddMonster()
    {
        mMonsterList.Clear();
        List<MonsterAtt> monsterAttList = MonsterAttManager.instance.GetList();
        for (int i = 0; i < monsterAttList.Count; i++)
        {
            ushort modelId = monsterAttList[i].modelId;
            string key = modelId + monsterAttList[i].monterType.ToString();
            if (mKeyList.Contains(key))
                continue;
            mKeyList.Add(key);
            RoleBase roleBase = RoleBaseManager.instance.Find(modelId);
            if (roleBase == null)
                continue;
            mMonsterList.Add(monsterAttList[i].name + "_" + monsterAttList[i].id.ToString());
        }
        mCurDic.Add(UnitType.Monster, mMonsterList);
    }

    /// <summary>
    /// 添加宠物
    /// </summary>
    private void AddPet()
    {
        mPetList.Clear();
        List<PetInfo> petAttList = PetInfoManager.instance.GetList();
        for(int i = 0; i < petAttList.Count; i++)
        {
            ushort modelId = petAttList[i].modelId;
            string key = petAttList[i].id.ToString();
            if (mKeyList.Contains(key))
                continue;
            mKeyList.Add(key);
            RoleBase roleBase = RoleBaseManager.instance.Find(modelId);
            if (roleBase == null)
                continue;
            mPetList.Add(petAttList[i].name + "_" + (petAttList[i].id*100+1).ToString());
        }
        mCurDic.Add(UnitType.Pet, mPetList);
    }

    /// <summary>
    /// 添加法宝
    /// </summary>
    private void AddMagicWeapon()
    {
        mMWeaponList.Clear();
        List<MagicWeaponInfo> mgAttList = MagicWeaponInfoManager.instance.GetList();
        for(int i = 0; i < mgAttList.Count; i++)
        {
            ushort modelId = mgAttList[i].modelId;
            string key = mgAttList[i].id.ToString();
            if (mKeyList.Contains(key))
                continue;
            mKeyList.Add(key);
            RoleBase roleBase = RoleBaseManager.instance.Find(modelId);
            if (roleBase == null)
                continue;
            uint unitTypeId = mgAttList[i].id * 100 + 1;
            mMWeaponList.Add(mgAttList[i].name + "_" + unitTypeId.ToString());
        }
        mCurDic.Add(UnitType.MagicWeapon, mMWeaponList);
    }

    private void AddNPC()
    {
        mNPCList.Clear();
        List<NPCInfo> npcAttList = NPCInfoManager.instance.GetList();
        for(int i = 0; i < npcAttList.Count; i++)
        {
            ushort modelId = npcAttList[i].modeId;
            string key = npcAttList[i].id.ToString();
            if (mKeyList.Contains(key))
                continue;
            mKeyList.Add(key);
            RoleBase roleBase = RoleBaseManager.instance.Find(modelId);
            if (roleBase == null)
                continue;
            mNPCList.Add(npcAttList[i].name + "_" + npcAttList[i].id.ToString());
        }
        mCurDic.Add(UnitType.NPC, mNPCList);
    }

    /// <summary>
    /// 创建主角
    /// </summary>
    private void CreateRole()
    {
        if (roleIdTmp == roleId)
            return;
        roleId = roleIdTmp;

        Unit unit = InputMgr.instance.mOwner;
        if (unit == null)
            return;
        if (unit.UnitTrans == null)
            return;
        uint unitTypeId = GetUnitId(roleId);
        ushort modelId = GetModelIdFromTable(unitTypeId);
        RoleBase roleBase = RoleBaseManager.instance.Find(modelId);
        if (roleBase == null)
            return;
        string name = roleBase.roleName;
        Vector3 bornPos = new Vector3(27, 10, 36);
        float eulerAngleY = 38;
        Unit curCtrlUnit = InputMgr.instance.mOwner;
        if(curCtrlUnit != null)
        {
            bornPos = curCtrlUnit.Position;
            eulerAngleY = curCtrlUnit.UnitTrans.eulerAngles.y;
        }
        long uid = System.DateTime.Now.Ticks;
        User.instance.MapData.UID = uid;
        Unit owner = UnitMgr.instance.CreateMainPlayer(uid, unitTypeId, name, bornPos, eulerAngleY, CampType.CampType1, (u) =>
              {
                  unit.Destroy();
                  u.TopBar = UnitLifeBar.Create(u, name, TopBarFty.CommenLifeBarStr);
                  CameraMgr.UpdateOperation(CameraType.Player, u.UnitTrans);
                  ShowTip("创建控制单位成功");
              });
        InputMgr.instance.Init(owner);
    }

    /// <summary>
    /// 创建敌人
    /// </summary>
    private void CreateEnemy()
    {
        if (enemyIdTmp == enemyId)
            return;
        enemyId = enemyIdTmp;
        for (int i = 0; i < CreateCount; i++)
        {
            CreateEnemy(i);
        }
    }

    /// <summary>
    /// 创建怪物
    /// </summary>
    private void CreateEnemy(int index)
    {
        Unit unit = InputMgr.instance.mOwner;
        if (unit == null)
            return;
        if (unit.UnitTrans == null)
            return;
        uint unitId = GetUnitId(enemyId);
        ushort modelId = GetModelIdFromTable(unitId);
        RoleBase roleBase = RoleBaseManager.instance.Find(modelId);
        if (roleBase == null)
            return;
        string name = roleBase.roleName;
        Vector3 bornPos = unit.Position + unit.UnitTrans.forward * 3 + Vector3.forward * index;
        UnitMgr.instance.CreateUnit(System.DateTime.Now.Ticks, unitId, name, bornPos, -unit.UnitTrans.localEulerAngles.y, CampType.CampType2, (u) =>
         {
             ShowTip("创建敌人单位成功");
             if (u.mUnitAttInfo.UnitType == UnitType.Boss)
                 TopBarFty.Create(u, name);
             else
                 u.TopBar = UnitLifeBar.Create(u, name, TopBarFty.CommenLifeBarStr);
         });
    }

    /// <summary>
    /// 从表中获取模型Id
    /// </summary>
    /// <param name="unitId"></param>
    /// <returns></returns>
    private ushort GetModelIdFromTable(uint unitTypeId)
    {
        UnitType actorType = UnitHelper.instance.GetUnitType(unitTypeId);
        if (actorType == UnitType.Monster)
        {
            MonsterAtt monsterAtt = MonsterAttManager.instance.Find(unitTypeId);
            if (monsterAtt == null)
                return 0;
            return monsterAtt.modelId;
        }
        else if (actorType == UnitType.Role)
        {
            RoleAtt roleAtt = RoleAttManager.instance.Find(unitTypeId);
            if (roleAtt == null)
                return 0;
            return roleAtt.modelId;
        }
        else if(actorType == UnitType.Pet)
        {
            PetInfo petInfo = PetInfoManager.instance.Find(unitTypeId / 100);
            if (petInfo == null)
                return 0;
            return petInfo.modelId;
        }
        else if(actorType == UnitType.MagicWeapon)
        {
            uint baseId = unitTypeId / 100;
            MagicWeaponInfo mwInfo = MagicWeaponInfoManager.instance.Find(baseId);
            if (mwInfo == null)
                return 0;
            return mwInfo.modelId;
        }
        else if (actorType == UnitType.NPC)
        {
            NPCInfo info = NPCInfoManager.instance.Find(unitTypeId);
            if (info == null)
                return 0;
            return info.modeId;
        }
        return 0;
    }

    /// <summary>
    /// 获取单位Id
    /// </summary>
    /// <param name="unitId"></param>
    /// <returns></returns>
    private uint GetUnitId(string unitId)
    {
        if (string.IsNullOrEmpty(unitId))
            return 0;
        string[] ids = unitId.Split('_');
        if (ids.Length < 2)
            return 0;
        return uint.Parse(ids[1]);
    }

    /// <summary>
    /// 显示提示
    /// </summary>
    /// <param name="msg"></param>
    private void ShowTip(string msg)
    {
        if (string.IsNullOrEmpty(msg))
            return;
        EditorWindow tipWin = EditorWindow.mouseOverWindow;
        if (tipWin == null)
            return;
        tipWin.ShowNotification(new GUIContent(msg));
    }
    
    /// <summary>
    /// 创建单位
    /// </summary>
    private void CreateUnit()
    {
        if (NGUIEditorTools.DrawHeader("单位创建"))
        {
            EditorGUILayout.BeginVertical("groupBox");
            EditorGUILayout.BeginVertical("box");
            if (NGUIEditorTools.DrawHeader("创建选择角色"))
            {
                NGUIEditorTools.BeginContents();
                SetSltUnitArea(ref curCtrlType, ref roleIdTmp, ref rSltIndex, ref rScrollPos);
                CreateRole();
                NGUIEditorTools.EndContents();
            }
            EditorGUILayout.EndVertical();

            GUILayout.Space(10);

            EditorGUILayout.BeginVertical("box");
            if (NGUIEditorTools.DrawHeader("修改创建敌人"))
            {
                NGUIEditorTools.BeginContents();
                SetSltUnitArea(ref curEnemyType, ref enemyIdTmp, ref eSltIndex, ref eScrollPos);
                CreateCount = EditorGUILayout.IntField("创建敌人数量", CreateCount);
                CreateEnemy();
                NGUIEditorTools.EndContents();
            }
            EditorGUILayout.EndVertical();
            EditorGUILayout.EndVertical();
        }
    }
    
    /// <summary>
    /// 设置选择单位区域
    /// </summary>
    private void SetSltUnitArea(ref string curType, ref string TmpUnitId, ref int sltIndex, ref Vector2 scrollPos)
    {
        curType = NGUIEditorTools.DrawList("单位类型", mTypeArray, curType);
        if (!mTypeStrDic.ContainsKey(curCtrlType))
            return;
        UnitType unitType = mTypeStrDic[curType];
        List<string> strList = mCurDic[unitType];
        int count = strList.Count;
        if (count == 0)
            return;
        if (sltIndex >= count)
            sltIndex = 0;
        TmpUnitId = strList[sltIndex];
        EditorGUILayout.LabelField("当前选择单位：", TmpUnitId);

        EditorGUILayout.BeginVertical("box");
        GUILayoutOption option = GUILayout.MinHeight(200);
        scrollPos = EditorGUILayout.BeginScrollView(scrollPos, option);
        sltIndex = GUILayout.SelectionGrid(sltIndex, strList.ToArray(), 5);
        EditorGUILayout.EndScrollView();
        EditorGUILayout.EndVertical();
    }

    /// <summary>
    /// 技能选项
    /// </summary>
    private void SkillOption()
    {
        if (NGUIEditorTools.DrawHeader("技能选项"))
        {
            EditorGUILayout.BeginVertical("groupBox");
            NGUIEditorTools.BeginContents();
            EditorGUILayout.BeginVertical();

            HitAction.ShowAttackFrame = EditorGUILayout.Toggle("是否显示攻击框", HitAction.ShowAttackFrame);
            HitAction.DestroyShowAttackFrame = EditorGUILayout.Toggle("是否销毁显示攻击框", HitAction.DestroyShowAttackFrame);
            if (HitAction.DestroyShowAttackFrame)
            {
                if (!HitAction.ShowAttackFrame)
                {
                    NGUIEditorTools.BeginContents();
                    EditorGUILayout.HelpBox("销毁攻击框的前提是选择显示攻击框才会有效", MessageType.Error);
                    NGUIEditorTools.EndContents();
                }
            }

            GUILayout.Space(10);

            if (GUILayout.Button("清除所有攻击框"))
            {
                GameObject go = GameObject.Find("AttackFrameRoot");
                if (go != null)
                    go.transform.DestroyChildren();
            }

            GUILayout.Space(10);

            if (GUILayout.Button("清除所有怪物"))
            {
                UnitMgr.instance.Dispose();
            }

            EditorGUILayout.EndVertical();
            NGUIEditorTools.EndContents();

            GUILayout.Space(10);

            NGUIEditorTools.BeginContents();
            DamageInfo.EditorInputDamage = EditorGUILayout.IntField("修改技能伤害值", DamageInfo.EditorInputDamage);
            NGUIEditorTools.EndContents();

            GUILayout.Space(10);

            NGUIEditorTools.BeginContents();
            float time = HangupMgr.instance.AutoHangupTime;
            float saveTime = EditorPrefs.GetFloat("HangupTime");
            if (saveTime > 0)
                time = saveTime;
            HangupMgr.instance.AutoHangupTime = EditorGUILayout.FloatField("修改自动挂机时间", time);
            EditorPrefs.SetFloat("HangupTime", HangupMgr.instance.AutoHangupTime);
            NGUIEditorTools.EndContents();

            EditorGUILayout.EndVertical();
        }
    }

    /// <summary>
    /// 动作编辑器相关
    /// </summary>
    private void ActionEditor()
    {
        if (NGUIEditorTools.DrawHeader("动作编辑器相关"))
        {
            NGUIEditorTools.BeginContents();
            EditorGUILayout.BeginVertical();
            if (GUILayout.Button("打开动作编辑器文件所在文件夹"))
            {
                TestRoleAction.OpenActionEditorToolFolder();
            }

            GUILayout.Space(10);

            if (GUILayout.Button("打开动作编辑器"))
            {
                TestRoleAction.OpenActionEditorTool();
            }
            EditorGUILayout.EndVertical();
            NGUIEditorTools.EndContents();
        }
    }
    #endregion

    #region 共有变量
    public void Init()
    {
        SetWinInfo();
        mCurDic.Clear();
        mKeyList.Clear();
        InitList();
        InitTypeStrDic();
        InitType();
        InitOriginID();
    }

    public void OnGUI()
    {
        mScrollPos = EditorGUILayout.BeginScrollView(mScrollPos);
        CreateUnit();
        SkillOption();
        ActionEditor();
        EditorGUILayout.EndScrollView();
    }
    #endregion
}
