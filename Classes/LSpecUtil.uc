// ============================================================================
// LSpecUtil for DuelSpecOverlay
//
// Based on UTComp's Util class
// ============================================================================
class LSpecUtil extends xUtil;

simulated static function LinkedSpecInfo GetSpecPRI(PlayerReplicationInfo PRI)
{
    local LinkedReplicationInfo lPRI;

    if (PRI == None)
        return None;

    if(PRI.CustomReplicationInfo==None)
        return None;  //shouldn't happen

    if(LinkedSpecInfo(PRI.CustomReplicationInfo)!=None)
    {
        return LinkedSpecInfo(PRI.CustomReplicationInfo);
    }

    for(lPRI=PRI.CustomReplicationInfo.NextReplicationInfo; lPRI!=None; lPRI=lPRI.NextReplicationInfo)
    {
        if(LinkedSpecInfo(lPRI)!=None)
            return LinkedSpecInfo(lPRI);
    }
    return none;
}

DefaultProperties
{
}
