using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public interface FightModBase
{
    bool StfCdt(Unit attacker, Unit target);
    Unit GetTarget(Unit attacker, float dis);
}
