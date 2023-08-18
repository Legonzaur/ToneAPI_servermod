global function matchStat_Init

struct weaponStats {
    int shotsFired
    int shotsHit
    int shotCrit
    int shotHeadshot
}

struct {
    table < entity, table < string, weaponStats > > weaponsUsed
} file

void function matchStat_Init(){
    // AddCallback_OnPlayerRespawned( TrackWeapons )
    AddCallback_OnPlayerGetsNewPilotLoadout( TrackWeaponsOnChange )
    AddCallback_OnPilotBecomesTitan( TrackTitanWeaponOnBecome )
    AddDamageCallback("player", OnDamage)
}

void function TrackWeapons( entity player ) {
    array<entity> weapons = player.GetMainWeapons()
    array<entity> offhand = player.GetOffhandWeapons()
    foreach(entity weapon in weapons){
        WeaponFireCallbacks_AddCallbackOnWeaponFired(weapon, OnWeaponFired)
    }
}

void function OnWeaponFired(entity weapon, WeaponPrimaryAttackParams attackParams, var ammoUsed){
    entity player = weapon.GetOwner()
    string weaponName = weapon.GetWeaponClassName()
    if(!player.IsPlayer()){
        return
    }
    if(!(player in file.weaponsUsed)){
        file.weaponsUsed[player] <- {}
    }
    if(!(weaponName in file.weaponsUsed[player])){
        weaponStats stats = {
            shotsFired = 0,
            shotsHit = 0,
            shotCrit = 0,
            shotHeadshot = 0
        }
        file.weaponsUsed[player][weaponName] <- stats
    }
    file.weaponsUsed[player][weaponName].shotsFired++
}

void function OnDamage( entity victim, var damageInfo){
    // if(!victim.IsPlayer()){
    //     return
    // }
    entity player = DamageInfo_GetAttacker( damageInfo )

    if(!IsValid(player) || !player.IsPlayer()){
        return
    }
    entity weapon = DamageInfo_GetWeapon( damageInfo )
    string weaponName = weapon.GetWeaponClassName()

    if(!(player in file.weaponsUsed)){
        file.weaponsUsed[player] <- {}
    }
    if(!(weaponName in file.weaponsUsed[player])){
        weaponStats stats = {
            shotsFired = 0,
            shotsHit = 0,
            shotCrit = 0,
            shotHeadshot = 0
        }
        file.weaponsUsed[player][weaponName] <- stats
    }
    file.weaponsUsed[player][weaponName].shotsHit++
    int damageType = DamageInfo_GetCustomDamageType( damageInfo )
    bool crit = bool( damageType & DF_CRITICAL )
    bool headshot = bool( damageType & DF_HEADSHOT )
    if(crit){
        file.weaponsUsed[player][weaponName].shotCrit++
    }
    if(headshot){
        file.weaponsUsed[player][weaponName].shotHeadshot++
    }

    print("crit " + string(file.weaponsUsed[player][weaponName].shotCrit))
    print("headshot " + string(file.weaponsUsed[player][weaponName].shotHeadshot))
}

void function TrackTitanWeapons( entity player ){
    TrackWeapons( player )
}

void function TrackWeaponsOnChange( entity player, PilotLoadoutDef loadout ) {
    TrackWeapons( player )
}

void function TrackTitanWeaponOnBecome( entity player, entity titan ){
    TrackTitanWeapons( player )
}