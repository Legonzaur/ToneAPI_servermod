global function matchStat_Init

void function matchStat_Init(){
    // AddCallback_OnPlayerRespawned( TrackWeapons )
    AddCallback_OnPlayerGetsNewPilotLoadout( TrackWeaponsOnChange )
    AddCallback_OnPilotBecomesTitan( TrackTitanWeaponOnBecome )
}

void function TrackWeapons( entity player ) {
    array<entity> weapons = player.GetMainWeapons()
    array<entity> offhand = player.GetOffhandWeapons()
    foreach(entity weapon in weapons){
        AddCallback_OnWeaponFired(weapon, void function(WeaponPrimaryAttackParams attackParams) : (weapon, player){
            print("weapon fired")
        } )
    }
}

void function TrackTitanWeapons( entity player ){

}

var function UseWeaponCallback(var weapon, var player){
    print("weapon used")
}


void function TrackWeaponsOnChange( entity player, PilotLoadoutDef loadout ) {
    TrackWeapons( player )
}

void function TrackTitanWeaponOnBecome( entity player, entity titan ){
    TrackTitanWeapons( player )
}