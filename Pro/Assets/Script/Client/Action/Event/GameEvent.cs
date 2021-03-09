using System;
using UnityEngine;
using System.Collections.Generic;

public abstract class GameEvent
{
    public bool CanIgnore = false;
    public abstract void Execute();
}