using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MoveAroundPoint : MonoBehaviour {

    public Camera uiCamera = null;
    public UIScrollView uiSV = null;

    /// <summary>
    /// 使用平均算法
    /// </summary>
    [SerializeField]
    public bool useAvg = false;

    /// <summary>
    /// 圆心位置
    /// </summary>
    [SerializeField]
    public Vector2 circleCenter = Vector2.zero;
    /// <summary>
    /// 半径
    /// </summary>
    [SerializeField]
    public float circleRadius = 0f;
    /// <summary>
    /// 计算X or 计算Y
    /// </summary>
    [SerializeField]
    public bool calculateX = true;


    public List<GameObject> moveObjs = new List<GameObject>();
    public List<GameObject> moveParentObjs = new List<GameObject>();


    //private float sWidth = 0f;
    //private float sHeight = 0f;

    private float minVal = 0f;
    private float maxVal = 0f;
    private float valNum = 0f;

    private float minArc = 0f;
    private float maxArc = 0f;
    private float arcNum = 0f;


    private void Awake()
    {
        Init();
    }

    // Use this for initialization
    void Start ()
    {
        
    }
	
	// Update is called once per frame
	void Update ()
    {
        if (moveObjs == null || moveObjs.Count <= 0)
            return;

        for(int a = 0; a < moveObjs.Count; a++)
        {
            if (useAvg == true)
            {
                ChangeObjPosAvg(moveParentObjs[a], moveObjs[a]);
            }
            else
            {
                ChangeObjPos(moveObjs[a]);
            }
        }
    }


    private void Init()
    {
        //sWidth = Screen.width;
        //sHeight = Screen.height;

        moveParentObjs.Clear();
        if (moveObjs != null)
        {
            for(int a = 0; a < moveObjs.Count; a++)
            {
                if (moveObjs[a].transform.parent != null)
                {
                    moveParentObjs.Add(moveObjs[a].transform.parent.gameObject);
                }
            }
        }

        if (uiCamera == null)
        {
            Debug.LogError("UI camera missing !!! ");
            return;
        }

        if (uiSV != null)
        {
            Vector3 svPos = uiCamera.WorldToScreenPoint(uiSV.transform.position);
            svPos.z = 0;
            UIPanel svPanel = uiSV.GetComponent<UIPanel>();
            if(svPanel != null)
            {
                svPos.x = svPos.x + svPanel.finalClipRegion.x;
                svPos.y = svPos.y + svPanel.finalClipRegion.y;

                if(calculateX == true)
                {
                    float r = svPanel.GetViewSize().y / 2f;
                    if(r > circleRadius)
                    {
                        r = circleRadius;
                    }
                    minVal = svPos.y - r / 2f;
                    maxVal = svPos.y + r / 2f;
                    valNum = maxVal - minVal;

                    bool isN = false;
                    if(svPos.x < circleCenter.x)
                    {
                        isN = true;
                    }
                    maxArc = GetArcByY(minVal, isN);
                    minArc = GetArcByY(maxVal, isN);
                    arcNum = maxArc - minArc;

                    Debug.Log("     max   " + maxArc * 180 / Mathf.PI);
                    Debug.Log("     min   " + minArc * 180 / Mathf.PI);
                }
                else
                {
                    float r = svPanel.GetViewSize().x / 2f;
                    if (r > circleRadius)
                    {
                        r = circleRadius;
                    }
                    minVal = svPos.x - r / 2f;
                    maxVal = svPos.x + r / 2f;
                    valNum = maxVal - minVal;

                    bool isN = false;
                    if (svPos.y < circleCenter.y)
                    {
                        isN = true;
                    }
                    maxArc = GetArcByX(minVal, isN);
                    minArc = GetArcByX(maxVal, isN);
                    arcNum = maxArc - minArc;
                }
            }
        }
    }

    public void AddMoveObj(GameObject obj)
    {
        if (moveObjs.Contains(obj) == false)
        {
            moveObjs.Add(obj);
            if (obj.transform.parent != null)
            {
                if (moveParentObjs != null && moveParentObjs.Contains(obj.transform.parent.gameObject) == false)
                {
                    moveParentObjs.Add(obj.transform.parent.gameObject);
                }
            }
        }
    }

    public void RemoveMoveObj(GameObject obj)
    {
        if(moveObjs.Contains(obj) == true)
        {
            moveObjs.Remove(obj);
            if (obj.transform.parent != null)
            {
                if (moveParentObjs != null && moveParentObjs.Contains(obj.transform.parent.gameObject))
                {
                    moveParentObjs.Remove(obj.transform.parent.gameObject);
                }
            }
        }
    }

    public void ClearMoveObj()
    {
        if(moveObjs != null)
        {
            moveObjs.Clear();
        }
        if(moveParentObjs != null)
        {
            moveParentObjs.Clear();
        }
    }


    private void ChangeObjPos(GameObject obj)
    {
        if(uiCamera == null)
        {
            Debug.LogError("UI camera missing !!! ");
            return;
        }

        if (circleRadius == 0)
            return;

        Vector3 scrPos = uiCamera.WorldToScreenPoint(obj.transform.position);
        scrPos.z = 0;

        if(calculateX == true)
        {
            if (Mathf.Abs(scrPos.y - circleCenter.y) > circleRadius)
            {
                if(obj.activeSelf == true)
                {
                    obj.SetActive(false);
                }
            }
            else
            {
                if(obj.activeSelf == false)
                {
                    obj.SetActive(true);
                }

                bool isN = false;
                if(scrPos.x < circleCenter.x)
                {
                    isN = true;
                }

                Vector3 newScrPos = CalCirclePos(scrPos, isN, true);
                Vector3 worldPos = uiCamera.ScreenToWorldPoint(newScrPos);
                worldPos.z = 0;
                obj.transform.position = worldPos;
            }
        }
        else
        {
            if (Mathf.Abs(scrPos.x - circleCenter.x) > circleRadius)
            {
                if (obj.activeSelf == true)
                {
                    obj.SetActive(false);
                }
            }
            else
            {
                if (obj.activeSelf == false)
                {
                    obj.SetActive(true);
                }

                bool isN = false;
                if (scrPos.y < circleCenter.y)
                {
                    isN = true;
                }

                Vector3 newScrPos = CalCirclePos(scrPos, isN, false);
                Vector3 worldPos = uiCamera.ScreenToWorldPoint(newScrPos);
                worldPos.z = 0;
                obj.transform.position = worldPos;
            }
        }
    }

    private Vector3 CalCirclePos(Vector3 oriPos, bool negative, bool getX)
    {
        if(getX == true)
        {
            float newX = GetX(oriPos.y, negative);
            return new Vector3(newX, oriPos.y, 0);
        }
        else
        {
            float newY = GetY(oriPos.x, negative);
            return new Vector3(oriPos.x, newY, 0);
        }
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="x"></param>
    /// <returns></returns>
    private float GetX(float y, bool negative)
    {
        if (circleRadius <= 0)
            return 0;
        
        float angle = Mathf.Asin((y - circleCenter.y) / circleRadius);
        if (negative)
        {
            return circleCenter.x - circleRadius * Mathf.Cos(angle);
        }
        else
        {
            return circleCenter.x + circleRadius * Mathf.Cos(angle);
        }
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="x"></param>
    /// <returns></returns>
    private float GetY(float x, bool negative)
    {
        if (circleRadius <= 0)
            return 0;

        float angle = Mathf.Acos((x - circleCenter.x) / circleRadius);
        if (negative)
        {
            return circleCenter.y - circleRadius * Mathf.Sin(angle);
        }
        else
        {
            return circleCenter.y + circleRadius * Mathf.Sin(angle);
        }
    }

    private float GetArcByY(float y, bool negative)
    {
        if (circleRadius <= 0)
            return 0;

        float arc = Mathf.Asin((y - circleCenter.y) / circleRadius);
        if(negative)
        {
            arc = Mathf.PI - arc;
        }

        return arc;
    }

    private float GetArcByX(float x, bool negative)
    {
        if (circleRadius <= 0)
            return 0;

        float arc = Mathf.Acos((x - circleCenter.x) / circleRadius);
        if (negative)
        {
            arc = Mathf.PI - arc;
        }

        return arc;
    }


    //x1 = x0 + r* cos(angle* PI / 180)
    //y1 = y0 + r* sin(angle* PI /180)

    ////////////////////////////////////   平均取值   ////////////////////////////////////

    private void ChangeObjPosAvg(GameObject parentObj, GameObject moveObj)
    {
        if (uiCamera == null)
        {
            Debug.LogError("UI camera missing !!! ");
            return;
        }

        if (circleRadius == 0)
            return;

        Vector3 scrPos = uiCamera.WorldToScreenPoint(parentObj.transform.position);
        scrPos.z = 0;

        if (calculateX == true)
        {
            if (Mathf.Abs(scrPos.y - circleCenter.y) > circleRadius)
            {
                if (moveObj.activeSelf == true)
                {
                    moveObj.SetActive(false);
                }
            }
            else
            {
                if (moveObj.activeSelf == false)
                {
                    moveObj.SetActive(true);
                }


                Vector3 newScrPos = GetScrPosByArc(GetChangeArcByY(scrPos));
                Vector3 worldPos = uiCamera.ScreenToWorldPoint(newScrPos);
                worldPos.z = 0;
                moveObj.transform.position = worldPos;
            }
        }
        else
        {
            if (Mathf.Abs(scrPos.x - circleCenter.x) > circleRadius)
            {
                if (moveObj.activeSelf == true)
                {
                    moveObj.SetActive(false);
                }
            }
            else
            {
                if (moveObj.activeSelf == false)
                {
                    moveObj.SetActive(true);
                }

                Vector3 newScrPos = GetScrPosByArc(GetChangeArcByX(scrPos));
                Vector3 worldPos = uiCamera.ScreenToWorldPoint(newScrPos);
                worldPos.z = 0;
                moveObj.transform.position = worldPos;
            }
        }
    }

    private float GetChangeArcByX(Vector3 scrPos)
    {
        return GetChangeArc(scrPos.x);
    }

    private float GetChangeArcByY(Vector3 scrPos)
    {
        return GetChangeArc(scrPos.y);
    }

    private float GetChangeArc(float curVal)
    {
        float weight = (curVal - minVal) / valNum;
        //float arc = weight * arcNum + minArc;
        float arc = maxArc - weight * arcNum;
        //Debug.Log("     arc   " + arc * 180 / Mathf.PI);
        return arc;
    }

    private Vector3 GetScrPosByArc(float arc)
    {
        float x = circleCenter.x + circleRadius * Mathf.Cos(arc);
        float y = circleCenter.y + circleRadius * Mathf.Sin(arc);

        return new Vector3(x, y, 0);
    }
}
