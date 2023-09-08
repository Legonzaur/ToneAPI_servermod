global function killstat_Init

void function killstat_Init() {
    if(GetMapName() == "mp_lobby") {
        return
    }
	AddCallback_OnPlayerKilled(killstat_Record)
}

void function killstat_Record(entity victim, entity attacker, var damageInfo) {
	if (!victim.IsPlayer() || !attacker.IsPlayer() || GetGameState() != eGameState.Playing)
		return
	if(!toneapi_data.matchId){
		ToneAPI_Log("[ERRR] Match is not registered!")
		return
	}



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
		version = toneapi_data.version
		match_id = toneapi_data.matchId
		game_time = Time()
		player_count = GetPlayerArray().len()
		cause_of_death = damageName
		distance = dist
		attacker = {
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
	request.url = toneapi_data.Tone_URI + "/kill"
	request.body = EncodeJSON(values)

	Tone_HTTP_Request(
		request,
		void
		function(HttpRequestResponse response) {}
	)
}

string function GetMovementState(entity player) {
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
int function MainWeaponSort(entity a, entity b) {
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

entity function GetNthWeapon(array < entity > weapons, int index) {
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