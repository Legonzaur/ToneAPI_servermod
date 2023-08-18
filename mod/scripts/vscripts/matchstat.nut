global function matchstat_Init

typedef weaponStats table <string, int>

struct {
    table < string, table < string, weaponStats > > weaponsUsed
} file

void function matchstat_Init(){
    WeaponFireCallbacks_AddCallbackOnOwnerClassFired("player", OnWeaponFired)
    AddDamageCallback("player", OnDamage)
    AddCallback_GameStateEnter(eGameState.Postmatch, ToneAPI_CloseMatch)
}

void function OnWeaponFired(entity weapon, WeaponPrimaryAttackParams attackParams, var ammoUsed){
    entity player = weapon.GetOwner()
    string weaponName = weapon.GetWeaponClassName()
    if(!IsValid(player) || !player.IsPlayer()){
        return
    }
    string playerUID = player.GetUID()
    if(!(playerUID in file.weaponsUsed)){
        file.weaponsUsed[playerUID] <- {}
    }
    if(!(weaponName in file.weaponsUsed[playerUID])){
        weaponStats stats = {
            shotsFired = 0,
            shotsHit = 0,
            shotCrit = 0,
            shotHeadshot = 0,
            shotRichochet = 0
        }
        file.weaponsUsed[playerUID][weaponName] <- stats
    }
    file.weaponsUsed[playerUID][weaponName].shotsFired++
}

void function OnDamage( entity victim, var damageInfo){
    entity player = DamageInfo_GetAttacker( damageInfo )

    if(!IsValid(player) || !player.IsPlayer()){
        return
    }
    string playerUID = player.GetUID()
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

    if(!(playerUID in file.weaponsUsed)){
        file.weaponsUsed[playerUID] <- {}
    }
    if(!(weaponName in file.weaponsUsed[playerUID])){
        weaponStats stats = {
            shotsFired = 0,
            shotsHit = 0,
            shotCrit = 0,
            shotHeadshot = 0,
            shotRichochet = 0
        }
        file.weaponsUsed[playerUID][weaponName] <- stats
    }
    file.weaponsUsed[playerUID][weaponName].shotsHit++
    int damageType = DamageInfo_GetCustomDamageType( damageInfo )
    bool crit = bool( damageType & DF_CRITICAL )
    bool headshot = bool( damageType & DF_HEADSHOT )
    if(crit){
        file.weaponsUsed[playerUID][weaponName].shotCrit++
    }
    if(headshot){
        file.weaponsUsed[playerUID][weaponName].shotHeadshot++
    }
    if ( inflictor && inflictor.IsProjectile() ){
        if(inflictor.proj.projectileBounceCount > 1){
            file.weaponsUsed[playerUID][weaponName].shotRichochet++
        }
    }

}

void function ToneAPI_CloseMatch(){
    if(!toneapi_data.matchId){
		ToneAPI_Log("[ERRR] Match is not registered!")
		return
	}

    HttpRequest request
	request.method = HttpRequestMethod.POST
	request.url = toneapi_data.Tone_URI + "/match/" + string(toneapi_data.matchId) + "/close"
	request.body = EncodeJSON(file.weaponsUsed)
    print(request.body)
    foreach(string stuff, weaponStats stuff2 in file.weaponsUsed["1005930844007"]){
        print(stuff)
        print(EncodeJSON(stuff2))
    }
    print("ok")


	Tone_HTTP_Request(
		request,
		void
		function(HttpRequestResponse response) {}
	)
}