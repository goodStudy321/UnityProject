#define FILE_LOG

using UnityEngine;
using System.Collections;
using System.IO;

public class FileLogMgr
{

    public static readonly FileLogMgr instance = new FileLogMgr();

    private FileLogMgr()
    {

    }
    FileStream mFileStream = null;
    StreamWriter mSW = null;

    string FileName
    {
        get
        {
#if UNITY_EDITOR
            string file = Application.dataPath + "/" + "slg.log";
#else
    string file = Application.persistentDataPath + "/sav_" + "slg.log";
#endif

            return file;
        }
    }

#if FILE_LOG


    void InitFileStream()
    {
#if UNITY_EDITOR
        mFileStream = new FileStream(FileName, FileMode.Create, FileAccess.Write, FileShare.ReadWrite);
#else
        mFileStream = new FileStream(FileName, FileMode.Create, FileAccess.Write, FileShare.None);
#endif
        mSW = new StreamWriter(mFileStream, System.Text.Encoding.Default);
    }

    public string GetFilePath()
    {
        return FileName;
    }

    public void Log(string format, params object[] args)
    {
        if (mFileStream == null)
            InitFileStream();

        mSW.WriteLine(format, args);
        mSW.Flush();
    }

    public void Log(string str)
    {
        if (mFileStream == null)
            InitFileStream();


        mSW.WriteLine(str);
        mSW.Flush();
    }

    public void Dispose()
    {
        mSW.Dispose();
        mFileStream.Dispose();
    }

#else
    public FileLogMgr()
    {

    }

    public void Log(string format, params object[] args)
    {
    }

    public void Log(string str)
    {

    }
#endif
}
