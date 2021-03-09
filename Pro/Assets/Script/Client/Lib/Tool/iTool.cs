using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using System.IO;
using System;

using Object = UnityEngine.Object;


namespace Hello.Game
{
    public static partial class iTool
    {
        public static void Destroy(Object obj)
        {
            if (obj == null) return;
            if (Application.isPlaying) Object.Destroy(obj);
            else Object.DestroyImmediate(obj);
        }

        public static float GetAngle(Transform origin, Transform target)
        {
            float angle = 0;
            float offset = origin.eulerAngles.y;
            Vector3 pos = origin.InverseTransformPoint(target.position);
            angle = Vector3.Angle(Vector3.back, pos);
            float dir = (Vector3.Dot(Vector3.up, Vector3.Cross(Vector3.back, pos)) < 0 ? 1 : -1);
            angle *= dir;
            angle -= offset + 180.0f;
            return -angle;
        }
    }
}
