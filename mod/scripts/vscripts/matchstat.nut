global function matchstat_Init

struct weaponStats {
    int shotsFired
    int shotsHit
    int shotCrit
    int shotHeadshot
    int shotRichochet
}

struct {
    table < entity, table < string, weaponStats > > weaponsUsed
} file

void function matchstat_Init(){
    // AddCallback_OnPlayerRespawned( TrackWeapons )
    WeaponFireCallbacks_AddCallbackOnOwnerClassFired("player", OnWeaponFired)
    AddDamageCallback("player", OnDamage)
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
            shotHeadshot = 0,
            shotRichochet = 0
        }
        file.weaponsUsed[player][weaponName] <- stats
    }
    file.weaponsUsed[player][weaponName].shotsFired++
}

void function OnDamage( entity victim, var damageInfo){
    entity player = DamageInfo_GetAttacker( damageInfo )

    if(!IsValid(player) || !player.IsPlayer()){
        return
    }
    entity weapon = DamageInfo_GetWeapon( damageInfo )
    entity inflictor = DamageInfo_GetInflictor( damageInfo )
    string weaponName
    if(weapon){
        weaponName = weapon.GetWeaponClassName()
    }
    else{
        if ( inflictor && inflictor instanceof CProjectile && inflictor.IsProjectile() ){
            weaponName = inflictor.ProjectileGetWeaponClassName()
        }else{
            ToneAPI_Log("[ERRR] Couldn't get weapon information")
            return
        }
    }

    if(!(player in file.weaponsUsed)){
        file.weaponsUsed[player] <- {}
    }
    if(!(weaponName in file.weaponsUsed[player])){
        weaponStats stats = {
            shotsFired = 0,
            shotsHit = 0,
            shotCrit = 0,
            shotHeadshot = 0,
            shotRichochet = 0
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
    if ( inflictor && inflictor instanceof CProjectile && inflictor.IsProjectile() ){
        if(inflictor.proj.projectileBounceCount > 1){
            file.weaponsUsed[player][weaponName].shotRichochet++
        }
    }

}