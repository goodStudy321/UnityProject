using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

public class FxAttachPrefab : MonoBehaviour
{

    #region 字段
    public enum AttachEnumType { Active, Destroy }

    //状态：Active,Destroy
    public AttachEnumType AttachType = AttachEnumType.Active;
    //延迟显示的时间
    public float DelayTime = 0f;
    //距离重复创建下一个prefab的时间
    public float RepeatTime = 0;
    //重复创建prefab的数量
    public int RepeatCout = 0;
    //预设prefab
    public GameObject AttachPrefab = null;
    //预设的生命周期
    public float PrefabLifeTime = 0;
    public bool UseWorldSpace = false;

    public Vector3 m_RandomRange = Vector3.zero;
    public Vector3 m_AddStartPos = Vector3.zero;
    public Vector3 m_AccumStartRot = Vector3.zero;


    [HideInInspector]
    //private GameObject mInstanceObject=null;
    private bool isDelayTime = false;
    private bool isRepeatTime = false;

    float repeatTime = 0f;
    private int createAttachCout = 0;
    #endregion

    #region 构造函数



    #endregion

    #region 公开方法



    #endregion

    #region 私有方法
    private void Start()
    {
        if (AttachType == AttachEnumType.Destroy) { Debug.Log("AttachType:"+AttachType);return; }
        if (AttachPrefab == null) { Debug.Log("AttachPrefab==null"); return; }
        if (DelayTime > 0) isDelayTime = true;
        if (RepeatTime > 0) isRepeatTime = true;
        createAttachCout = RepeatCout;
    }

    private void Update()
    {
        if (isDelayTime == true)
        {
            float delayTime = Time.time;
            if (delayTime>DelayTime)
            {
                delayTime = 0f;
                CreateOneAttachPrefab(GetWordSpaceRootTransform(), 0);
                isDelayTime = false;
            }          
        }
        if (createAttachCout > 1 && isDelayTime == false)
        {
            CreateAttachPrefa( ref createAttachCout);
        }
    }
    private void CreateAttachPrefa( ref int attachCount)
    {
        if (attachCount > 1 )
        {
            if (isRepeatTime == true)
            {
                while (attachCount > 1)
                {
                    repeatTime += Time.deltaTime;
                    if (repeatTime > RepeatTime)
                    {
                        repeatTime = 0f;
                        attachCount--;
                        CreateOneAttachPrefab(GetWordSpaceRootTransform(), RepeatCout - attachCount);
                    }
                    else
                        return;             
                }
            }
            else
            {
                while (attachCount > 1)
                {              
                    CreateOneAttachPrefab(GetWordSpaceRootTransform(), RepeatCout - attachCount);
                    attachCount--;
                }
            }
        }
    }

  

    private void CreateOneAttachPrefab(Transform parent, int index)
    {
        GameObject go = GameObject.Instantiate(AttachPrefab);
        AutoLifeTime autoLifeTime = go.GetComponent<AutoLifeTime>();
        if (autoLifeTime == null) go.AddComponent<AutoLifeTime>();
        go.transform.parent = parent;
        go.transform.localScale = Vector3.one;
        go.transform.localPosition = Vector3.zero;
        go.name = AttachPrefab.name + " " + index.ToString();
        CreateOneAttachPosition(go, index+1);
    }

    private void CreateOneAttachPosition(GameObject thisGo, int count)
    {
        // Random pos, AddStartPoss
        Vector3 newPos = thisGo.transform.position;
        thisGo.transform.position = m_AddStartPos + new Vector3(
            UnityEngine.Random.Range(-m_RandomRange.x, m_RandomRange.x),
            UnityEngine.Random.Range(-m_RandomRange.y, m_RandomRange.y),
            UnityEngine.Random.Range(-m_RandomRange.z, m_RandomRange.z)
            );

        // m_AccumStartRot
        thisGo.transform.localRotation *= Quaternion.Euler(
            m_AccumStartRot.x * count,
            m_AccumStartRot.y * count,
            m_AccumStartRot.z * count
            );
    }

    //private IEnumerator CreateRepeatPrefab(Transform parent)
    //{
    //    if (DelayTime != 0) yield return new WaitForSeconds(DelayTime);
    //    for (int i = 0; i < RepeatCout; i++)
    //    {
    //        GameObject go = GameObject.Instantiate(AttachPrefab);
    //        AutoLifeTime autoLifeTime = new AutoLifeTime(go);
    //        if (PrefabLifeTime > 0) StartCoroutine(autoLifeTime.LifeTimeDispose(PrefabLifeTime));
    //        go.transform.parent = parent;
    //        go.transform.localScale = Vector3.one;
    //        go.transform.localPosition = Vector3.zero;
    //        go.name = AttachPrefab.name + " " + i.ToString();

    //        yield return new WaitForSeconds(RepeatTime);
    //    }
    //    yield return new WaitForSeconds(0);
    //}
    private Transform GetWordSpaceRootTransform()
    {
        GameObject instanceObject = null;
        if (UseWorldSpace == true)
        {
            instanceObject = GameObject.Find("_InstanceObject");
            if (instanceObject == null) instanceObject = new GameObject("_InstanceObject");
        }
        else
        {
            instanceObject = this.gameObject;
        }
        return instanceObject.transform;
    }


    #endregion
}
