global function matchstat_Init

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
    return expect float(value) + 1
}

void function CreatePlayer(entity player){
    string playerUID = player.GetUID()
    if(!(playerUID in file.weaponsUsed)){
        var playerName = player.GetPlayerName()
        file.weaponsUsed[playerUID] <- {}
        file.weaponsUsed[playerUID].weapons <- {}
        file.weaponsUsed[playerUID].titans <- {}
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

void function CreateWeaponStats(string weaponName, entity player){
    CreatePlayer(player)
    string playerUID = player.GetUID()
    if(!(weaponName in file.weaponsUsed[playerUID].weapons)){
        // Has to make ints floats because you can't mix types apparently
        playerSpecificStats stats = {
            shotsFired = 0.0,
            shotsHit = 0.0,
            shotsCrit = 0.0,
            shotsHeadshot = 0.0,
            shotsRichochet = 0.0,
            playtime = 0.0
        }
        file.weaponsUsed[playerUID].weapons[weaponName] <- stats
    }
}

void function CreateTitanStats(string titanName, entity player){
    CreatePlayer(player)
    string playerUID = player.GetUID()
    if(!(titanName in file.weaponsUsed[playerUID].titans)){
        // Has to make ints floats because you can't mix types apparently
        playerSpecificStats stats = {
            shotsFired = 0.0,
            shotsHit = 0.0,
            shotsCrit = 0.0,
            shotsHeadshot = 0.0,
            shotsRichochet = 0.0,
            playtime = 0.0
        }
        file.weaponsUsed[playerUID].titans[titanName] <- stats
    }
}

void function OnWeaponFired(entity weapon, WeaponPrimaryAttackParams attackParams, var ammoUsed){
    entity player = weapon.GetOwner()
    string weaponName = weapon.GetWeaponClassName()
    if(!IsValid(player) || !player.IsPlayer()){
        return
    }
    string playerUID = player.GetUID()
    CreateWeaponStats(weaponName, player)
    file.weaponsUsed[playerUID].weapons[weaponName].shotsFired = incrementVar(file.weaponsUsed[playerUID].weapons[weaponName].shotsFired)
    if(player.IsTitan()){
        string titanName = GetTitanCharacterName(player)
        CreateTitanStats(titanName, player)
        file.weaponsUsed[playerUID].titans[titanName].shotsFired = incrementVar(file.weaponsUsed[playerUID].titans[titanName].shotsFired)
    }
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
    CreateWeaponStats(weaponName, player)
    file.weaponsUsed[playerUID].weapons[weaponName].shotsHit = incrementVar(file.weaponsUsed[playerUID].weapons[weaponName].shotsHit)
    if(player.IsTitan()){
        string titanName = GetTitanCharacterName(player)
        CreateTitanStats(titanName, player)
        file.weaponsUsed[playerUID].titans[titanName].shotsHit = incrementVar(file.weaponsUsed[playerUID].titans[titanName].shotsHit)
    }
    int damageType = DamageInfo_GetCustomDamageType( damageInfo )
    bool crit = bool( damageType & DF_CRITICAL )
    bool headshot = bool( damageType & DF_HEADSHOT )
    // if(crit){
    //     file.weaponsUsed[playerUID].weapons[weaponName].shotsCrit = incrementVar(file.weaponsUsed[playerUID].weapons[weaponName].shotsCrit)
    //     if(player.IsTitan()){
    //         file.weaponsUsed[playerUID].titans[titanName].shotsCrit = incrementVar(file.weaponsUsed[playerUID].titans[titanName].shotsCrit)
    //     }
    // }
    if(headshot || crit){
        file.weaponsUsed[playerUID].weapons[weaponName].shotsHeadshot = incrementVar(file.weaponsUsed[playerUID].weapons[weaponName].shotsHeadshot)
        if(player.IsTitan()){
            string titanName = GetTitanCharacterName(player)
            file.weaponsUsed[playerUID].titans[titanName].shotsHeadshot = incrementVar(file.weaponsUsed[playerUID].titans[titanName].shotsHeadshot)
        }
    }
    if ( inflictor && inflictor.IsProjectile() ){
        if(inflictor.proj.projectileBounceCount > 1){
            file.weaponsUsed[playerUID].weapons[weaponName].shotsRichochet = incrementVar(file.weaponsUsed[playerUID].weapons[weaponName].shotsRichochet)
            if(player.IsTitan()){
                string titanName = GetTitanCharacterName(player)
                file.weaponsUsed[playerUID].titans[titanName].shotsRichochet = incrementVar(file.weaponsUsed[playerUID].titans[titanName].shotsRichochet)
            }
        }
    }  
    
}


void function TrackPlayer(entity player) {
    string playerUID = player.GetUID()
    CreatePlayer(player)
    thread TrackPlayer_Threaded(player)
}

// void function StopTrackPlayer() {

// }

void function TrackPlayer_Threaded(entity player){
    player.EndSignal( "OnDestroy" )
	player.EndSignal( "OnDeath" )
    vector position = player.GetOrigin()
    string playerUID = player.GetUID()
    float interval = 0.2
    while(true){
        wait interval
        // Hmm
        Assert( IsValid( player ) )
        if(!IsValid(player)) return

        // Ugly, should probably use flags
        if(GetGameState() == eGameState.WinnerDetermined) return

        entity weapon = player.GetActiveWeapon()
        if(weapon){
            string weaponName = weapon.GetWeaponClassName()
            CreateWeaponStats(weaponName, player)
            file.weaponsUsed[playerUID].weapons[weaponName].playtime = expect float(file.weaponsUsed[playerUID].weapons[weaponName].playtime) + interval
        }else{
            CreatePlayer(player)
        }

        if(player.IsTitan()){
            string titanName = GetTitanCharacterName(player)
            CreateTitanStats(titanName, player)
            file.weaponsUsed[playerUID].titans[titanName].playtime = expect float(file.weaponsUsed[playerUID].titans[titanName].playtime) + interval
        }else if(player.IsPlayer()){
            // Could be a little inaccurate but should work fine if interval is small enough
            if(player.IsWallRunning()){
                file.weaponsUsed[playerUID].stats.time.wall = expect float(file.weaponsUsed[playerUID].stats.time.wall) + interval
                file.weaponsUsed[playerUID].stats.distance.wall = expect float(file.weaponsUsed[playerUID].stats.distance.wall) + Distance(position, player.GetOrigin())
            }
            else if(!player.IsOnGround()){ 
                file.weaponsUsed[playerUID].stats.time.air = expect float(file.weaponsUsed[playerUID].stats.time.air) + interval
                file.weaponsUsed[playerUID].stats.distance.air = expect float(file.weaponsUsed[playerUID].stats.distance.air) + Distance(position, player.GetOrigin())
            }
            else{
                file.weaponsUsed[playerUID].stats.time.ground = expect float(file.weaponsUsed[playerUID].stats.time.ground) + interval
                file.weaponsUsed[playerUID].stats.distance.ground = expect float(file.weaponsUsed[playerUID].stats.distance.ground) + Distance(position, player.GetOrigin())
            }
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