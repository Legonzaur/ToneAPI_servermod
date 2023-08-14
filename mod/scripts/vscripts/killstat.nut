global

function killstat_Init

struct {
	string killstatVersion
	string Tone_URI
	string Tone_protocol
	string Tone_token
	bool connected

	string matchId
	string gameMode
	string map
}
file

void

function killstat_Init() {
	file.killstatVersion = GetConVarString("killstat_version")
	file.Tone_URI = GetConVarString("Tone_URI")
	file.Tone_token = GetConVarString("Tone_token")
	file.connected = false
    if(GetMapName() == "mp_lobby") {
        return
    }
	//Test auth and print result to console when server start
	Tone_Test_Auth()

	//We should probably blacklist mp_lobby this
	Tone_Register_Match()
	// callbacks
	AddCallback_GameStateEnter(eGameState.Playing, killstat_Begin)
	AddCallback_OnPlayerKilled(killstat_Record)
	AddCallback_GameStateEnter(eGameState.Postmatch, killstat_End)
	AddCallback_OnClientConnected(JoinMessage)
}

string prefix = "\x1b[38;5;81m[TONE API]\x1b[0m "

bool function hasCustomAirAccel(){
    return Code_GetCurrentPlaylistVarOrUseValue("custom_air_accel_pilot", "null") != "null"
}

void function JoinMessage(entity player) {
	//Chat_ServerPrivateMessage(player, prefix + "This server collects data using the Tone API. Check your data here: \x1b[34mtoneapi.com/" + player.GetPlayerName()+ "\x1b[0m", false, false)
	Chat_ServerPrivateMessage(player, prefix + "This server collects data using the WIP Tone API. View statistics at https://toneapi.github.io/ToneAPI_webclient/", false, false)
}

void

function killstat_Begin() {
	//TODO : request MatchID from API ------------------------------------------------------------------------------------------------
	//TODO : request anonymization data from API

	Log("-----BEGIN KILLSTAT-----")
	Log("Sending kill data to " + file.Tone_URI + "/kill")
}

void

function killstat_Record(entity victim, entity attacker, var damageInfo) {
	if (!victim.IsPlayer() || !attacker.IsPlayer() || GetGameState() != eGameState.Playing)
		return
	// if(file.matchId)
	//     return


	table attackerValues = {}
	table < string,
		var > victimValues = {}

	array < entity > attackerWeapons = attacker.GetMainWeapons()
	array < entity > victimWeapons = victim.GetMainWeapons()
	array < entity > attackerOffhandWeapons = attacker.GetOffhandWeapons()
	array < entity > victimOffhandWeapons = victim.GetOffhandWeapons()

	attackerWeapons.sort(MainWeaponSort)
	victimWeapons.sort(MainWeaponSort)

	entity aw1 = GetNthWeapon(attackerWeapons, 0)
	entity aw2 = GetNthWeapon(attackerWeapons, 1)
	entity aw3 = GetNthWeapon(attackerWeapons, 2)
	entity vw1 = GetNthWeapon(victimWeapons, 0)
	entity vw2 = GetNthWeapon(victimWeapons, 1)
	entity vw3 = GetNthWeapon(victimWeapons, 2)
	entity aow1 = GetNthWeapon(attackerOffhandWeapons, 0)
	entity aow2 = GetNthWeapon(attackerOffhandWeapons, 1)
	entity aow3 = GetNthWeapon(attackerOffhandWeapons, 2)
	entity vow1 = GetNthWeapon(victimOffhandWeapons, 0)
	entity vow2 = GetNthWeapon(victimOffhandWeapons, 1)
	entity vow3 = GetNthWeapon(victimOffhandWeapons, 2)

	int damageSourceId = DamageInfo_GetDamageSourceIdentifier(damageInfo)
	string damageName = DamageSourceIDToString(damageSourceId)

	float dist = Distance(attacker.GetOrigin(), victim.GetOrigin())

	table values = {
		killstat_version = file.killstatVersion
		match_id = int(file.matchId)
		game_time = Time()
		player_count = GetPlayerArray().len()
		cause_of_death = damageName
		distance = dist
		attacker = {
			name = attacker.GetPlayerName()
			id = attacker.GetUID()
			velocity = Distance( < 0, 0, 0 > , attacker.GetVelocity())
			cloaked = attacker.IsCloaked(true)
			state = GetMovementState(attacker)
			current_weapon = {
				id = GetWeaponName(attacker.GetLatestPrimaryWeapon())
				mods = GetWeaponMods(attacker.GetLatestPrimaryWeapon())
			}
			loadout = {
				primary = {
					id = GetWeaponName(aw1)
					mods = GetWeaponMods(aw1)
				}
				secondary = {
					id = GetWeaponName(aw2)
					mods = GetWeaponMods(aw2)
				}
				anti_titan = {
					id = GetWeaponName(aw3)
					mods = GetWeaponMods(aw3)
				}
				ordnance = {
					id = GetWeaponName(aow1)
					mods = GetWeaponMods(aow1)
				}
				tactical = {
					id = GetWeaponName(aow2)
					mods = GetWeaponMods(aow2)
				}
                passive1 = getPlayerPassive1(attacker)
                passive2 = getPlayerPassive2(attacker)
                titan = GetTitan(attacker)
			}
		}
		victim = {
			name = victim.GetPlayerName()
			id = victim.GetUID()
			velocity = Distance( < 0, 0, 0 > , victim.GetVelocity())
			cloaked = victim.IsCloaked(true)
			state = GetMovementState(victim)
			current_weapon = {
				id = GetWeaponName(victim.GetLatestPrimaryWeapon())
				mods = GetWeaponMods(victim.GetLatestPrimaryWeapon())
			}
			loadout = {
				primary = {
					id = GetWeaponName(vw1)
					mods = GetWeaponMods(vw1)
				}
				secondary = {
					id = GetWeaponName(vw2)
					mods = GetWeaponMods(vw2)
				}
				anti_titan = {
					id = GetWeaponName(vw3)
					mods = GetWeaponMods(vw3)
				}
				ordnance = {
					id = GetWeaponName(vow1)
					mods = GetWeaponMods(vow1)
				}
				tactical = {
					id = GetWeaponName(vow2)
					mods = GetWeaponMods(vow2)
				}
                passive1 = getPlayerPassive1(victim)
                passive2 = getPlayerPassive2(victim)
                titan = GetTitan(victim)
			}
		}
	}


	HttpRequest request
	request.method = HttpRequestMethod.POST
	request.url = file.Tone_URI + "/kill"
	request.body = EncodeJSON(values)

	Tone_HTTP_Request(
		request,
		void
		function(HttpRequestResponse response) {}
	)
}

void

function killstat_End() {
	Log("-----END KILLSTAT-----")
}

string

function GetMovementState(entity player) {
	Assert(IsPilot(player))
	//IsPhaseShifted
	//IsStanding
	if (player.IsWallHanging())
		return "WallHanging"
	if (player.IsWallRunning())
		return "WallRunning"
	if (player.IsZiplining())
		return "Ziplining"
	if (!player.IsOnGround())
		return "Airborne"
	if (player.IsCrouched())
		return "Crouching"
	return "OnGround"
}

// Should sort main weapons in following order:
// 1. primary
// 2. secondary
// 3. anti-titan
int

function MainWeaponSort(entity a, entity b) {
	int aID = a.GetDamageSourceID()
	int bID = b.GetDamageSourceID()

	int aIdx = MAIN_DAMAGE_SOURCES.find(aID)
	int bIdx = MAIN_DAMAGE_SOURCES.find(bID)

	if (aIdx == bIdx) {
		return 0
	} else if (aIdx != -1 && bIdx == -1) {
		return -1
	} else if (aIdx == -1 && bIdx != -1) {
		return 1
	}

	return aIdx < bIdx ? -1 : 1
}

entity
function GetNthWeapon(array < entity > weapons, int index) {
	return index < weapons.len() ? weapons[index] : null
}

var function GetWeaponData(entity weapon){
    if(weapon != null) {
        return {
            id = weapon.GetWeaponClassName()
            mods = weapon.GetModBitField()
        }
    }
    return null
}
var function GetWeaponName(entity weapon) {
	if (weapon != null) {
		return weapon.GetWeaponClassName()
	}
    return null
}

int
function GetWeaponMods(entity weapon) {
	if (weapon == null) {
		return 0
	}
	int modBits = weapon.GetModBitField()
	// return format("%d", modBits)
	return modBits
}

var function GetTitan(entity player) {
	if (player.IsTitan()){
        return GetTitanCharacterName(player)
    }
    return null
}

void
function Log(string s) {
	print(prefix + s)
}

void
function Tone_Test_Auth() {
	HttpRequest request
	request.method = HttpRequestMethod.POST
	request.url = file.Tone_URI + "/"
	Tone_HTTP_Request(
		request,
		void
		function(HttpRequestResponse response) {
			Log("Tone API Initialized")
			file.connected = true
		}
	)
}


void
function Tone_Register_Match() {
	HttpRequest request
	request.method = HttpRequestMethod.POST
	request.url = file.Tone_URI + "/match"
	request.body = EncodeJSON({
		gamemode = GameRules_GetGameMode()
		game_map = StringReplace(GetMapName(), "mp_", "")
		server_name = GetConVarString("ns_server_name")
        air_accel = hasCustomAirAccel()
	})
	Tone_HTTP_Request(
		request,
		void
		function(HttpRequestResponse response) {
            table data = DecodeJSON(response.body)
			Log("match ID : " + string(expect int(data.match)))
			file.matchId = string(expect int(data.match))
		}
	)
}


void function Tone_HTTP_Request(HttpRequest request, void functionref(HttpRequestResponse) cbSuccess) {
	if (!request.method) request.method = HttpRequestMethod.POST
	if (request.url == "") {
		Log("[ERRR] Couldn't find URI for request. This should be reported")
		return
	}
	request.headers = {
		Authorization = ["Bearer " + file.Tone_token]
	}

	NSHttpRequest(
		request,
		void
		function(HttpRequestResponse response): (cbSuccess) {
			if (response.statusCode == 200 || response.statusCode == 201) {
				cbSuccess(response)
			} else {
                if(response.statusCode == 401){
                    Log("[WARN] Something might be wrong with your token")
                }else{
                    Log("[WARN] Something went wrong ! You'd better report this")
                }
				Log("[WARN] " + response.statusCode)
				Log("[WARN] " + response.body)
			}
		},
		void
		function(HttpRequestFailure failure) {
			Log("[WARN] Couldn't request the server! ToneAPI may be down.")
			Log("[WARN] " + failure.errorCode)
			Log("[WARN] " + failure.errorMessage)
		}
	)
}

var function getPlayerPassive1(entity player) {
    foreach (string key, int val in ePassives){
        if (PlayerHasPassive(player, val)) {
            if(passive1Names.find(key) != -1){
                return key
            }
		}
    }
    return null
}

var function getPlayerPassive2(entity player) {
    foreach (string key, int val in ePassives){
        if (PlayerHasPassive(player, val)) {
            if(passive2Names.find(key) != -1){
                return key
            }
		}
    }
    return null
}

array < int > MAIN_DAMAGE_SOURCES = [
	// primaries
	eDamageSourceId.mp_weapon_car,
	eDamageSourceId.mp_weapon_r97,
	eDamageSourceId.mp_weapon_alternator_smg,
	eDamageSourceId.mp_weapon_hemlok_smg,
	eDamageSourceId.mp_weapon_hemlok,
	eDamageSourceId.mp_weapon_vinson,
	eDamageSourceId.mp_weapon_g2,
	eDamageSourceId.mp_weapon_rspn101,
	eDamageSourceId.mp_weapon_rspn101_og,
	eDamageSourceId.mp_weapon_esaw,
	eDamageSourceId.mp_weapon_lstar,
	eDamageSourceId.mp_weapon_lmg,
	eDamageSourceId.mp_weapon_shotgun,
	eDamageSourceId.mp_weapon_mastiff,
	eDamageSourceId.mp_weapon_dmr,
	eDamageSourceId.mp_weapon_sniper,
	eDamageSourceId.mp_weapon_doubletake,
	eDamageSourceId.mp_weapon_pulse_lmg,
	eDamageSourceId.mp_weapon_smr,
	eDamageSourceId.mp_weapon_softball,
	eDamageSourceId.mp_weapon_epg,
	eDamageSourceId.mp_weapon_shotgun_pistol,
	eDamageSourceId.mp_weapon_wingman_n,

	// secondaries
	eDamageSourceId.mp_weapon_smart_pistol,
	eDamageSourceId.mp_weapon_wingman,
	eDamageSourceId.mp_weapon_semipistol,
	eDamageSourceId.mp_weapon_autopistol,

	// anti-titan
	eDamageSourceId.mp_weapon_mgl,
	eDamageSourceId.mp_weapon_rocket_launcher,
	eDamageSourceId.mp_weapon_arc_launcher,
	eDamageSourceId.mp_weapon_defender
]


array < string > passive1Names = [
	"pas_ordnance_pack",
	"pas_power_cell",
	"pas_fast_embark",
	"pas_fast_health_regen"
]


array < string > passive2Names = [
	"pas_stealth_movement",
	"pas_wallhang",
	"pas_ads_hover",
	"pas_enemy_death_icons",
	"pas_at_hunter"
]