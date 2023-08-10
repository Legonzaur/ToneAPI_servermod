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

void

function JoinMessage(entity player) {
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

function killstat_Record(entity victim, entity attacker,
	var damageInfo) {
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
		match_id = file.matchId
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
				name = GetWeaponName(attacker.GetLatestPrimaryWeapon())
				mods = GetWeaponMods(attacker.GetLatestPrimaryWeapon())
			}
			loadout = {
				primary = {
					name = GetWeaponName(aw1)
					mods = GetWeaponMods(aw1)
				}
				secondary = {
					name = GetWeaponName(aw2)
					mods = GetWeaponMods(aw2)
				}
				anti_titan = {
					name = GetWeaponName(aw3)
					mods = GetWeaponMods(aw3)
				}
				ordnance = {
					name = GetWeaponName(aow1)
					mods = GetWeaponMods(aow1)
				}
				tactical = {
					name = GetWeaponName(aow2)
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
				name = GetWeaponName(victim.GetLatestPrimaryWeapon())
				mods = GetWeaponMods(victim.GetLatestPrimaryWeapon())
			}
			loadout = {
				primary = {
					name = GetWeaponName(vw1)
					mods = GetWeaponMods(vw1)
				}
				secondary = {
					name = GetWeaponName(vw2)
					mods = GetWeaponMods(vw2)
				}
				anti_titan = {
					name = GetWeaponName(vw3)
					mods = GetWeaponMods(vw3)
				}
				ordnance = {
					name = GetWeaponName(vow1)
					mods = GetWeaponMods(vow1)
				}
				tactical = {
					name = GetWeaponName(vow2)
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
	request.url = file.Tone_URI + "/server/kill"
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

string
function GetWeaponName(entity weapon) {
	string s = "null"
	if (weapon != null) {
		s = weapon.GetWeaponClassName()
	}
	return s
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

string
function GetTitan(entity player) {
	if (!player.IsTitan()) return "null"
	return GetTitanCharacterName(player)
}

void
function Log(string s) {
	print(prefix + " " + s)
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
			Log("Tone API Online !")
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
		gameMode = GameRules_GetGameMode()
		map = StringReplace(GetMapName(), "mp_", "")
		servername = GetConVarString("ns_server_name")
	})
	Tone_HTTP_Request(
		request,
		void
		function(HttpRequestResponse response) {
			Log("match ID : " + response.body)
			file.matchId = response.body
		}
	)
}


void
function Tone_HTTP_Request(HttpRequest request, void functionref(HttpRequestResponse) cbSuccess) {
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
				Log("[WARN] Something might be wrong with your token")
				Log("[WARN]" + response.statusCode)
				Log("[WARN]" + response.body)
			}
		},
		void
		function(HttpRequestFailure failure) {
			Log("[WARN] Couldn't request the server! ToneAPI may be down.")
			Log("[WARN]" + failure.errorCode)
			Log("[WARN]" + failure.errorMessage)
		}
	)
}

string
function getPlayerPassive1(player entity) {
	foreach(string passive in passive1Names) {
		if (PlayerHasPassive(player, passive)) {
			return passive
		}
	}
    return null
}

string
function getPlayerPassive2(player entity) {
	foreach(string passive in passive2Names) {
		if (PlayerHasPassive(player, passive)) {
			return passive
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