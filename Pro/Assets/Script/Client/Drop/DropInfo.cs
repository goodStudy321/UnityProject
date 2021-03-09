using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;
using System;

public class DropInfo
{
    private GameObject mGo = null;
    private const float waitTime = 30f;
    private List<Vector3> posList = new List<Vector3>();
    public DropData data = null;
    private NameBarBase nameBar = null;
    public  ItemData item = null;
    private GameObject moveEff = null;
    private List<GameObject> effList = new List<GameObject>();

    public bool isLock = false;
    public bool isBegan = false;
    public float countTime = 1f;
    private bool isRemove = false;
    public bool isEnd = false;
    #region 属性
    /// <summary>
    /// 掉落物位置
    /// </summary>
    public Vector3 Position
    {
        get
        {
            return mGo.transform.position;
        }
    }
    #endregion


    public void InitData(GameObject go, DropData data)
    {
        this.mGo = go;
        SetPos(data);


        UInt64 id = data.type_id;
        if (id > 70000 && id < 90000)
        {
            ItemCreate create = ItemCreateManager.instance.Find(id);
            if (create != null)
            {
                int cate = User.instance.MapData.Category;
                if (cate == 1)
                    id = create.w1;
                else
                    id = create.w2;
            }
        }
        item = ItemDataManager.instance.Find((UInt32)id);
        if (item == null)
        {
            iTrace.eLog("xiaoyu", string.Format("道具为空，表id为{0}", data.type_id));
            return;
        }
        if (item != null)
        {
            nameBar = CommenNameBar.Create(mGo.transform, "", item.name, TopBarFty.DropStr);
            string color = "[FFFFFF]";
            if (item.quality == 1) //白蓝紫橙红粉
                color = "[FFFFFF]";
            else if (item.quality == 2)
                color = "[008ffc]";
            else if (item.quality == 3)
                color = "[b03df2]";
            else if (item.quality == 4)
                color = "[f39800]";
            else if (item.quality == 5)
                color = "[f21919]";
            else if (item.quality == 6)
                color = "[ff66fc]";
            nameBar.NameLab.width = 600;
            nameBar.Name = string.Format("[size=40]{0}{1}X{2}", color, item.name, data.num);
        }
    }

    //掉落特效
    public void DropEff()
    {
        if (mGo == null) return;
        if (item.quality == 3) //紫色
        {
            AssetMgr.LoadPrefab("FX_Drop_perple", LoadEff);
        }
        else if (item.quality == 4) //橙色
        {
            AssetMgr.LoadPrefab("FX_Drop_gold", LoadEff);
            AssetMgr.LoadPrefab("FX_Drop_Light_gold", LoadEff);
        }
        else if (item.quality == 5) //红色
        {
            AssetMgr.LoadPrefab("FX_Drop_red", LoadEff);
            AssetMgr.LoadPrefab("FX_Drop_Light_red", LoadEff);
        }
    }

    public void LoadEff(GameObject go)
    {
        go.transform.parent = mGo.transform;
        go.SetActive(true);
        go.transform.localScale = Vector3.one;
        go.transform.localPosition = Vector3.zero;
        effList.Add(go);
    }

    public void CreateMoveEff()
    {
        AssetMgr.LoadPrefab("FX_Scene_GoldlTrail", LoadMoveEff);
    }

    private void LoadMoveEff(GameObject go)
    {
        go.transform.parent = DropMgr.MRoot;
        go.transform.localScale = Vector3.one;
        go.transform.localPosition = mGo.transform.localPosition + new Vector3(0, 0.19f, 0);
        moveEff = go;
    }


    public void UpdateBar()
    {
        if (nameBar != null) nameBar.Update();
    }

    public void Update()
    {
        if (isRemove == false)
        {
            if (countTime > 0f)
                countTime -= Time.deltaTime;
            else
            {
                isRemove = true;
                CreateMoveEff();
                mGo.SetActive(false);
                nameBar.Close();
            }
        }
        else
        {
            if (moveEff != null)
            {
                Vector3 startPos = moveEff.transform.position;
                Vector3 endPos = User.instance.Pos + new Vector3(0, 1.3f, 0);
                float lerp = Vector3.Distance(startPos, endPos);
                if (lerp > 0.1f)
                {
                    Vector3 dir = (endPos - startPos).normalized;
                    moveEff.transform.Translate(dir * Time.deltaTime * 8f, Space.World);
                }
                else
                {
                    CreateEndEff();
                    isEnd = true;
                }
            }
        }
    }

    public static void CreateEndEff()
    {
        AssetMgr.LoadPrefab("FX_Scene_GoldlTrailEnd", LoadEndEff);
    }

    private static void LoadEndEff(GameObject go)
    {
        go.transform.parent = DropMgr.MRoot;
        go.transform.localScale = Vector3.one;
        go.transform.localPosition = User.instance.Pos + new Vector3(0, 1.3f, 0);
    }

    private void SetPos(DropData data)
    {
        //SK_BaoXiangGuai01
        mGo.transform.parent = DropMgr.MRoot;
        mGo.SetActive(false);
        mGo.SetActive(true);
        mGo.transform.localScale = Vector3.one;
        mGo.transform.localPosition = data.startDropPos;

        this.data = data;
    }

    /// <summary>
    /// Update检测是否在拾取范围内
    /// </summary>
    public void UpdateDistance()
    {
        //检测是否穿戴了小精灵，是的话自动拾取
        if (!IsInPickDis())
            return;
        //拾取掉落物
        isLock = true;
        EventMgr.Trigger("m_pick_drop_tos", data.dropId);
    }

    /// <summary>
    /// 是否在拾取范围内
    /// </summary>
    /// <returns></returns>
    public bool IsInPickDis()
    {
        if (data == null) return false;
        UInt32 mId = data.monster_type_id;
        if (mId == 0) mId = 200101;  //TODO:GM命令测试
        MonsterAtt mons = MonsterAttManager.instance.Find(mId);
        if (mons == null)
        {
            Debug.LogError("掉落物怪物配置表为空 id:" + mId);
            return false;
        }
        float dis = Vector3.Distance(InputVectorMove.instance.MoveUnit.Position, mGo.transform.position);

        //1.拾取范围变大为道具表范围======穿戴小精灵并且可快捷拾取
        if (DropMgr.spriteId != 0 && mons.canQuickPick == 1)
        {
            ItemData item = ItemDataManager.instance.Find(DropMgr.spriteId);
            if (item == null) return false;
            float range = Convert.ToInt16(item.useEffectArg1);
            if (dis > (float)range / 10) return false;
        }
        //2.拾取范围不变为怪物配置表范围
        else
        {
            if (dis > (float)mons.pickRange / 10)
                return false;
        }
        return true;
    }

    /// <summary>
    /// 能否快速拾取（可快速拾取并且穿戴了小精灵）
    /// </summary>
    /// <returns></returns>
    public bool CanQuickPick()
    {
        if (data == null)
        {
            iTrace.eError("DropInfo", "data == null");
            return false;
        }
        MonsterAtt mons = MonsterAttManager.instance.Find(data.monster_type_id);
        if (mons == null) return false;
        if (DropMgr.spriteId != 0 && mons.canQuickPick == 1) return true;
        else return false;
    }

    public void CleanData()
    {
        isLock = false;
        isBegan = false;
        countTime = 1f;
        isRemove = false;
        isEnd = false;
    }


    public void Dispose()
    {
        CleanData();
        while (effList.Count > 0)
        {
            GameObject go = effList[effList.Count - 1];
            go.transform.parent = null;
            GbjPool.Instance.Add(go);
            effList.Remove(go);
        }
        data = null;
        posList.Clear();

        if (nameBar != null)
        {
            nameBar.Dispose();
            nameBar = null;
        }
        if (mGo != null)
        {
            GbjPool.Instance.Add(mGo);
            mGo = null;
        }
       

        if (moveEff != null)
        {
            GbjPool.Instance.Add(moveEff);
            moveEff = null;
        }
        ObjPool.Instance.Add(this);
    }

}
