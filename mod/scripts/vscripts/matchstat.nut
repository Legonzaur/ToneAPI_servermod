global function matchstat_Init

typedef weaponStats table <string, var>
// typedef playerWeaponStats table < string, weaponStats >
typedef playerSpecificStats table < string, var >
typedef playerStats table < string, playerSpecificStats >
typedef players table < string, playerStats >
struct {
    table < string, players > weaponsUsed
} file

void function matchstat_Init(){
    WeaponFireCallbacks_AddCallbackOnOwnerClassFired("player", OnWeaponFired)
    AddDamageCallback("player", OnDamage)
    AddCallback_OnPlayerRespawned( TrackPlayer )
    // AddCallback_GameStateEnter(eGameState.WinnerDetermined, StopTrackPlayer)
    // FlagInit( "" )
    AddCallback_GameStateEnter(eGameState.Postmatch, ToneAPI_CloseMatch)
    
}

var function incrementVar(var value){
    return expect int(value) + 1
}

void function CreatePlayer(string playerUID){
    if(!(playerUID in file.weaponsUsed)){
        file.weaponsUsed[playerUID] <- {}
        file.weaponsUsed[playerUID].weapons <- {}
        file.weaponsUsed[playerUID].stats <- {}
        file.weaponsUsed[playerUID].stats.distance <- {
            ground = 0.0,
            wall = 0.0,
            air = 0.0
        }
        file.weaponsUsed[playerUID].stats.time <- {
            ground = 0.0,
            wall = 0.0,
            air = 0.0
        }
    }
}

void function CreateWeaponStats(string weaponName, string playerUID){
    CreatePlayer(playerUID)
    if(!(weaponName in file.weaponsUsed[playerUID].weapons)){
        weaponStats stats = {
            shotsFired = 0,
            shotsHit = 0,
            shotsCrit = 0,
            shotsHeadshot = 0,
            shotsRichochet = 0
        }
        file.weaponsUsed[playerUID].weapons[weaponName] <- stats
    }
}

void function OnWeaponFired(entity weapon, WeaponPrimaryAttackParams attackParams, var ammoUsed){
    entity player = weapon.GetOwner()
    string weaponName = weapon.GetWeaponClassName()
    if(!IsValid(player) || !player.IsPlayer()){
        return
    }
    string playerUID = player.GetUID()
    CreateWeaponStats(weaponName, playerUID)
    file.weaponsUsed[playerUID].weapons[weaponName].shotsFired = incrementVar(file.weaponsUsed[playerUID].weapons[weaponName].shotsFired)
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

    CreateWeaponStats(weaponName, playerUID)
    file.weaponsUsed[playerUID].weapons[weaponName].shotsHit = incrementVar(file.weaponsUsed[playerUID].weapons[weaponName].shotsHit)
    int damageType = DamageInfo_GetCustomDamageType( damageInfo )
    bool crit = bool( damageType & DF_CRITICAL )
    bool headshot = bool( damageType & DF_HEADSHOT )
    if(crit){
        file.weaponsUsed[playerUID].weapons[weaponName].shotsCrit = incrementVar(file.weaponsUsed[playerUID].weapons[weaponName].shotsCrit)
    }
    if(headshot){
        file.weaponsUsed[playerUID].weapons[weaponName].shotsHeadshot = incrementVar(file.weaponsUsed[playerUID].weapons[weaponName].shotsCrit)
    }
    if ( inflictor && inflictor.IsProjectile() ){
        if(inflictor.proj.projectileBounceCount > 1){
            file.weaponsUsed[playerUID].weapons[weaponName].shotsRichochet = incrementVar(file.weaponsUsed[playerUID].weapons[weaponName].shotsCrit)
        }
    }

}


void function TrackPlayer(entity player) {
    string playerUID = player.GetUID()
    CreatePlayer(playerUID)
    thread TrackPlayer_Threaded(player)
}

// void function StopTrackPlayer() {

// }

void function TrackPlayer_Threaded(entity player){
    player.EndSignal( "OnDestroy" )
	player.EndSignal( "OnDeath" )
    vector position = player.GetOrigin()
    string playerUID = player.GetUID()
    while(true){
        wait 0.2
        // Hmm
        Assert( IsValid( player ) )
        if(!IsValid(player)) return

        if( player.IsTitan() || !player.IsPlayer()) continue
        // Ugly, should probably use flags
        if(GetGameState() == eGameState.WinnerDetermined) return

        // Could be a little inaccurate but should work fine if interval is small enough
        vector diff = position - player.GetOrigin()
        if(player.IsWallRunning()){
            file.weaponsUsed[playerUID].stats.time.wall = expect float(file.weaponsUsed[playerUID].stats.time.wall) + 0.2
            file.weaponsUsed[playerUID].stats.distance.wall = expect float(file.weaponsUsed[playerUID].stats.distance.wall) + Length(diff)
        }
        else if(!player.IsOnGround()){ 
            file.weaponsUsed[playerUID].stats.time.air = expect float(file.weaponsUsed[playerUID].stats.time.air) + 0.2
            file.weaponsUsed[playerUID].stats.distance.air = expect float(file.weaponsUsed[playerUID].stats.distance.air) + Length(diff)
        }
        else{
            file.weaponsUsed[playerUID].stats.time.ground = expect float(file.weaponsUsed[playerUID].stats.time.ground) + 0.2
            file.weaponsUsed[playerUID].stats.distance.ground = expect float(file.weaponsUsed[playerUID].stats.distance.ground) + Length(diff)
        }
        position = player.GetOrigin()
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
	Tone_HTTP_Request(
		request,
		void
		function(HttpRequestResponse response) {}
	)
}