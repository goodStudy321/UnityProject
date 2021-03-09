using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class EmoMgr
{
    private static List<Vector3> posList = new List<Vector3>();
    private static List<string> emoList = new List<string>();
   // private static Dictionary<Vector3, string> emoPos = new Dictionary<Vector3, string>();
    //private static Dictionary<Vector3, string> emo = new Dictionary<Vector3, string>();
    private static List<Vector3> verts = new List<Vector3>();
    private static List<int> indices = new List<int>();
    private static UILabel mLab = null;
    private static string mText = null;
    private static string mSpace = null;

    public static List<string> AtlasDic = new List<string>();

    public static List<Vector3> PosList
    {
        get
        {
            return posList;
        }
    }

    public static List<string> EmoList
    {
        get
        {
            return emoList;
        }
    }

    public static void SetEmo(UILabel lab,string text,string space)
    {
        posList.Clear();
        emoList.Clear();
        verts.Clear();
        indices.Clear();

        mLab = lab;
        mText = text;
        mSpace = space;

        SetEmo(mText);
        UpdateCharacterPosition();
        
    }

    public static void SetEmo(string text)
    {

        if (string.IsNullOrEmpty(text)) return;
        int pos = text.IndexOf("#");
       
        if (pos != -1)
        {
            string endS = text.Substring(pos);
            if (endS.Length >= 3)
            {
                string emo = text.Substring(pos, 3);
                if (AtlasDic.Contains(emo)) //是表情
                {
                   
                    string nextStr = text.Substring(pos+3);
                    int lastY = 0;
                    if(posList.Count>0)
                    {
                        lastY = (int)posList[posList.Count - 1].y;
                    }
                    posList.Add(new Vector3(pos+ lastY, pos + lastY + mSpace.Length, 0));
                    emoList.Add(emo);
                    SetEmo(nextStr);
                }
            }
        }
        return;
    }

    //计算显示文字的实际显示范围
    //这个方法可以计算出整个文本的大小，NGUIText.CalculatePrintedSize的计算结果会有问题
    public static void UpdateCharacterPosition()
    {
        for (int i = 0; i < emoList.Count; i++)
        {
            mText = mText.Replace(emoList[i], mSpace);
        }

        //计算当前所有字符的位置  
        mLab.text = mText;
        string name = mLab.transform.parent.name;
        if (mLab.height>30) //多行
        {
            mLab.alignment = NGUIText.Alignment.Left;
        }
        else //单行
        {
            if (name == "MyLab")
                mLab.alignment = NGUIText.Alignment.Right;
            else
                mLab.alignment = NGUIText.Alignment.Left;
        }
        mLab.UpdateNGUIText();

        NGUIText.PrintExactCharacterPositions(mText, verts, indices);

        for (int i = 0; i < verts.Count; i++)
        {
            switch (mLab.pivot)
            {
                case UIWidget.Pivot.TopLeft:
                    {
                        verts[i] += new Vector3(0, 0, 0);
                        break;
                    }
                case UIWidget.Pivot.Top:
                    {
                        verts[i] += new Vector3(-mLab.width * 0.5f, 0, 0);
                        break;
                    }
                case UIWidget.Pivot.TopRight:
                    {
                        verts[i] += new Vector3(-mLab.width, 0, 0);
                        break;
                    }
                case UIWidget.Pivot.Left:
                    {
                        verts[i] += new Vector3(0, mLab.height * 0.5f, 0);
                        break;
                    }
                case UIWidget.Pivot.Center:
                    {
                        verts[i] += new Vector3(-mLab.width * 0.5f, mLab.height * 0.5f, 0);
                        break;
                    }
                case UIWidget.Pivot.Right:
                    {
                        verts[i] += new Vector3(-mLab.width, mLab.height * 0.5f, 0);
                        break;
                    }
                case UIWidget.Pivot.BottomLeft:
                    {
                        verts[i] += new Vector3(0, mLab.height, 0);
                        break;
                    }
                case UIWidget.Pivot.Bottom:
                    {
                        verts[i] += new Vector3(-mLab.width * 0.5f, mLab.height, 0);
                        break;
                    }
                case UIWidget.Pivot.BottomRight:
                    {
                        verts[i] += new Vector3(-mLab.width, mLab.height, 0);
                        break;
                    }
            }
        }

        for (int i = 0; i < posList.Count; i++)
        {
            Vector3 xy = posList[i];
            int x = (int)xy.x;
            int len = indices.Count;
            for (int i1=0;i1< len; i1++)
            {
                if(indices[i1]==x)
                {
                    posList[i] = verts[i1 * 2];
                    break;
                }
            }         
        }
    }

}
