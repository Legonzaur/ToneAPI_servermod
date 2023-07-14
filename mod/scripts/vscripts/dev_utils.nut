array<int> MAIN_DAMAGE_SOURCES = [
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

void function DumpWeaponModBitFields() {
    Log("[DumpWeaponModBitFields]")
    foreach (int damageSourceId in MAIN_DAMAGE_SOURCES) {
        string weaponName = DamageSourceIDToString(damageSourceId)
        array<string> mods = GetWeaponMods_Global(weaponName)
        array<string> list = [weaponName]
        foreach (string mod in mods) {
            list.append(mod)
        }

        Log("[DumpWeaponModBitFields] " + ToPythonList(list))
    }
}


string function ToPythonList(array<string> list) {
    array<string> quoted = []
    foreach (string s in list) {
        quoted.append("'" + s + "'")
    }

    return "\"[" + join(quoted, ", ") + "]\""
}


string function join(array<string> list, string separator) {
    string s = ""
        for (int i = 0; i < list.len(); i++) {
            s += list[i]
                if (i < list.len() - 1) {
                    s += separator
                }
        }

    return s
}

int function WeaponNameSort(entity a, entity b) {
    return SortStringAlphabetize(a.GetWeaponClassName(), b.GetWeaponClassName())
}