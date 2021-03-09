//using System.Collections;
//using System.Collections.Generic;
//using UnityEngine;

//public class TestScene : MonoBehaviour
//{
//    bool doorOpen = false;

//	// Use this for initialization
//	void Start () {
//        //MapPathMgr.instance.MainMono = this;
//        MapPathMgr.instance.LoadMapData(90009);
//        PathTool.PathMoveMgr.instance.LoadData();
//    }
	
//	// Update is called once per frame
//	void Update () {
//        MapPathMgr.instance.Update(Time.deltaTime);
//        PathTool.PathMoveMgr.instance.Update(Time.deltaTime);

//        if (Input.GetKeyDown(KeyCode.O))
//        {
//            doorOpen = !doorOpen;
//            MapPathMgr.instance.ChangeDoorBlockState(101, doorOpen);
//        }

//        if (Input.GetKeyDown(KeyCode.P))
//        {
//            CutscenePlayMgr.instance.PlayCutscene("80001", TestCallBack);
//        }
//    }

//    public void TestCallBack(CutscenePlayer.StopType sType)
//    {
//        Debug.Log("         " + sType);
//    }
//}
