using UnityEngine;
using System.Text;
using System.IO;
using System;
using System.Collections;
using System.Collections.Generic;


//[Serializable]
//public class BezierSavePoint
//{
//    [SerializeField]
//    public Vector3 mPosition;
//    [SerializeField]
//    public Vector3 mHandle1;
//    [SerializeField]
//    public Vector3 mHandle2;
//    [SerializeField]
//    public int mHandleStyle;

//    public BezierSavePoint()
//    {

//    }

//    public BezierSavePoint(BinaryBezierSavePoint binaryPoint)
//    {
//        mPosition = binaryPoint.mPosition.GetVector3();
//        mHandle1 = binaryPoint.mHandle1.GetVector3();
//        mHandle2 = binaryPoint.mHandle2.GetVector3();
//        mHandleStyle = binaryPoint.mHandleStyle;
//    }
//}

[Serializable]
public class BinaryBezierSavePoint
{
    public SVector3 mPosition;
    public SVector3 mHandle1;
    public SVector3 mHandle2;
    public int mHandleStyle;

    public BinaryBezierSavePoint()
    {
        mPosition = new SVector3();
        mHandle1 = new SVector3();
        mHandle2 = new SVector3();
    }

    //public BinaryBezierSavePoint(BezierSavePoint savePoint)
    //{
    //    mPosition = new SVector3(savePoint.mPosition);
    //    mHandle1 = new SVector3(savePoint.mHandle1);
    //    mHandle2 = new SVector3(savePoint.mHandle2);
    //    mHandleStyle = savePoint.mHandleStyle;
    //}



    public void Read(BinaryReader reader)
    {
        mPosition.Read(reader);
        mHandle1.Read(reader);
        mHandle2.Read(reader);
    }

    public void Save(BinaryWriter write)
    {
        mPosition.Save(write);
        mHandle1.Save(write);
        mHandle2.Save(write);
    }
}

/// <summary>
/// 贝塞尔曲线保存结构
/// </summary>
//[Serializable]
//public class BezierRecord
//{
//    /// <summary>
//    /// 曲线Id
//    /// </summary>
//    [SerializeField]
//    public uint mId;
//    /// <summary>
//    /// 平滑度
//    /// </summary>
//    [SerializeField]
//    public int mResolution;
//    /// <summary>
//    /// 颜色
//    /// </summary>
//    [SerializeField]
//    public Color mColor;
//    /// <summary>
//    /// 曲线位置
//    /// </summary>
//    [SerializeField]
//    public Vector3 mPathPos;
//    /// <summary>
//    /// 曲线点列表
//    /// </summary>
//    [SerializeField]
//    public List<BezierSavePoint> mBezierPoints;
//    /// <summary>
//    /// 取样点列表
//    /// </summary>
//    [SerializeField]
//    public List<Vector3> mSampledPoint;

//    public BezierRecord()
//    {

//    }

//    public BezierRecord(BinaryBezierRecord binaryRecord)
//    {
//        mId = binaryRecord.mId;
//        mResolution = binaryRecord.mResolution;
//        mColor = binaryRecord.mColor.GetColor();
//        mPathPos = binaryRecord.mPathPos.GetVector3();

//        mBezierPoints = new List<BezierSavePoint>();
//        for (int a = 0; a < binaryRecord.mBezierPoints.Count; a++)
//        {
//            mBezierPoints.Add(new BezierSavePoint(binaryRecord.mBezierPoints[a]));
//        }
//        mSampledPoint = new List<Vector3>();
//        for (int a = 0; a < binaryRecord.mSampledPoint.Count; a++)
//        {
//            mSampledPoint.Add(binaryRecord.mSampledPoint[a].GetVector3());
//        }
//    }

//    public BezierRecord Clone()
//    {
//        BezierRecord ret = new BezierRecord();
//        ret.mId = mId;
//        ret.mResolution = mResolution;
//        ret.mColor = mColor;
//        ret.mPathPos = mPathPos;
//        ret.mBezierPoints = new List<BezierSavePoint>(mBezierPoints);
//        ret.mSampledPoint = new List<Vector3>(mSampledPoint);

//        return ret;
//    }
//}

[Serializable]
public class BinaryBezierRecord
{
    /// <summary>
    /// 曲线Id
    /// </summary>
    public uint mId;
    /// <summary>
    /// 平滑度
    /// </summary>
    public int mResolution;
    /// <summary>
    /// 颜色
    /// </summary>
    public SVector4 mColor;
    /// <summary>
    /// 曲线位置
    /// </summary>
    public SVector3 mPathPos;
    /// <summary>
    /// 曲线点列表
    /// </summary>
    [SerializeField]
    public List<BinaryBezierSavePoint> mBezierPoints;
    /// <summary>
    /// 取样点列表
    /// </summary>
    [SerializeField]
    public List<SVector3> mSampledPoint;


    public BinaryBezierRecord()
    {
        mColor = new SVector4();
        mPathPos = new SVector3();
        mBezierPoints = new List<BinaryBezierSavePoint>();
        mSampledPoint = new List<SVector3>();

    }

    //public BinaryBezierRecord(BezierRecord saveRecord)
    //{
    //    mId = saveRecord.mId;
    //    mResolution = saveRecord.mResolution;
    //    mColor = new SVector4(saveRecord.mColor);
    //    mPathPos = new SVector3(saveRecord.mPathPos);

    //    mBezierPoints = new List<BinaryBezierSavePoint>();
    //    for (int a = 0; a < saveRecord.mBezierPoints.Count; a++)
    //    {
    //        mBezierPoints.Add(new BinaryBezierSavePoint(saveRecord.mBezierPoints[a]));
    //    }
    //    mSampledPoint = new List<SVector3>();
    //    for (int a = 0; a < saveRecord.mSampledPoint.Count; a++)
    //    {
    //        mSampledPoint.Add(new SVector3(saveRecord.mSampledPoint[a]));
    //    }
    //}

    public void Read(BinaryReader reader)
    {
        mId = reader.ReadUInt32();
        mResolution = reader.ReadInt32();
        mColor.Read(reader);
        mPathPos.Read(reader);
        int bpLen = reader.ReadInt32();
        for (int i = 0; i < bpLen; i++)
        {
            var bp = new BinaryBezierSavePoint();
            bp.Read(reader);
            mBezierPoints.Add(bp);
        }

        int spLen = reader.ReadInt32();
        for (int i = 0; i < spLen; i++)
        {
            var sp = new SVector3();
            sp.Read(reader);
            mSampledPoint.Add(sp);
        }
    }

    public void Save(BinaryWriter write)
    {
        write.Write(mId);
        write.Write(mResolution);
        mColor.Save(write);
        mPathPos.Save(write);
        int bpLen = mBezierPoints.Count;
        write.Write(bpLen);
        for (int i = 0; i < bpLen; i++)
        {
            var bp = mBezierPoints[i];
            bp.Save(write);
        }

        int spLen = mSampledPoint.Count;
        write.Write(spLen);
        for (int i = 0; i < spLen; i++)
        {
            var sp = mSampledPoint[i];
            sp.Save(write);
        }
    }

    public BinaryBezierRecord Clone()
    {
        BinaryBezierRecord ret = new BinaryBezierRecord();
        ret.mId = mId;
        ret.mResolution = mResolution;
        ret.mColor = mColor;
        ret.mPathPos = mPathPos;
        ret.mBezierPoints = new List<BinaryBezierSavePoint>(mBezierPoints);
        ret.mSampledPoint = new List<SVector3>(mSampledPoint);

        return ret;
    }
}

/// <summary>
/// 贝塞尔曲线保存数据
/// </summary>
[Serializable]
public class BezierPathBinaryData
{
    /// <summary>
    /// 曲线数据
    /// </summary>
    [SerializeField]
    public List<BinaryBezierRecord> mPathDataList = new List<BinaryBezierRecord>();

    public BezierPathBinaryData()
    {

    }

    public void Read(string path)
    {
        using (var fs = new FileStream(path,FileMode.Open))
        {
            var bytes = new byte[fs.Length];
            fs.Read(bytes, 0, (int)fs.Length);
            Read(bytes);
        }
    }


    public void Read(byte[] bytes)
    {
        using (var ms = new MemoryStream(bytes))
        {
            using (var reader = new BinaryReader(ms, Encoding.UTF8))
            {
                int length = reader.ReadInt32();
                for (int i = 0; i < length; i++)
                {
                    var data = new BinaryBezierRecord();
                    data.Read(reader);
                    mPathDataList.Add(data);
                }
            }
        }
    }


    public void Write(string path)
    {
        using (var fs = new FileStream(path, FileMode.OpenOrCreate))
        {
            using (var write = new BinaryWriter(fs, Encoding.UTF8))
            {
                int length = mPathDataList.Count;
                write.Write(length);
                for (int i = 0; i < length; i++)
                {
                    var data = mPathDataList[i];
                    data.Save(write);
                }
            }
        }
    }
}