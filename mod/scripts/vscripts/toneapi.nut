global function toneapi_Init
global function Tone_HTTP_Request
global function ToneAPI_Log

string prefix = "\x1b[38;5;81m[TONE API]\x1b[0m "

global struct toneapi_struct {
	string version
	string Tone_URI
	string Tone_protocol
	string Tone_token
	bool connected

	int ornull matchId
	string gameMode
	string map
}

global toneapi_struct toneapi_data

void function toneapi_Init(){
    //TODO : request anonymization data from API
    if(GetMapName() == "mp_lobby") {
        return
    }
    toneapi_data.version = GetConVarString("toneapi_version")
	toneapi_data.Tone_URI = GetConVarString("Tone_URI")
	toneapi_data.Tone_token = GetConVarString("Tone_token")
	toneapi_data.connected = false

    //Test auth and print result to console when server start
	// Tone_Test_Auth()

	//We should probably blacklist mp_lobby this
	Tone_Register_Match()

    AddCallback_OnClientConnected(JoinMessage)
}

void function JoinMessage(entity player) {
	//Chat_ServerPrivateMessage(player, prefix + "This server collects data using the Tone API. Check your data here: \x1b[34mtoneapi.com/" + player.GetPlayerName()+ "\x1b[0m", false, false)
	Chat_ServerPrivateMessage(player, prefix + "This server collects data using the WIP Tone API. View statistics at https://toneapi.github.io/ToneAPI_webclient/", false, false)
}


void function Tone_HTTP_Request(HttpRequest request, void functionref(HttpRequestResponse) cbSuccess) {
	if (!request.method) request.method = HttpRequestMethod.POST
	if (request.url == "") {
		ToneAPI_Log("[ERRR] Couldn't find URI for request. This should be reported")
		return
	}
	request.headers = {
		Authorization = ["Bearer " + toneapi_data.Tone_token]
	}

	NSHttpRequest(
		request,
		void function(HttpRequestResponse response): (cbSuccess) {
			if (response.statusCode == 200 || response.statusCode == 201) {
				cbSuccess(response)
			} else {
                if(response.statusCode == 401){
                    ToneAPI_Log("[WARN] Something might be wrong with your token")
                }else{
                    ToneAPI_Log("[WARN] Something went wrong ! You'd better report this")
                }
				ToneAPI_Log("[WARN] " + response.statusCode)
				ToneAPI_Log("[WARN] " + response.body)
			}
		},
		void function(HttpRequestFailure failure) {
			ToneAPI_Log("[WARN] Couldn't request the server! ToneAPI may be down.")
			ToneAPI_Log("[WARN] " + failure.errorCode)
			ToneAPI_Log("[WARN] " + failure.errorMessage)
		}
	)
}

void function Tone_Test_Auth() {
	HttpRequest request
	request.method = HttpRequestMethod.POST
	request.url = toneapi_data.Tone_URI + "/"
	Tone_HTTP_Request(
		request,
		void function(HttpRequestResponse response) {
			ToneAPI_Log("Tone API Initialized")
			toneapi_data.connected = true
		}
	)
}

bool function hasCustomAirAccel(){
    return Code_GetCurrentPlaylistVarOrUseValue("custom_air_accel_pilot", "null") != "null"
}

void function Tone_Register_Match() {
	HttpRequest request
	request.method = HttpRequestMethod.POST
	request.url = toneapi_data.Tone_URI + "/match"
	request.body = EncodeJSON({
		gamemode = GameRules_GetGameMode()
		game_map = StringReplace(GetMapName(), "mp_", "")
		server_name = GetConVarString("ns_server_name")
        air_accel = hasCustomAirAccel()
	})
	Tone_HTTP_Request(
		request,
		void function(HttpRequestResponse response) {
            table data = DecodeJSON(response.body)
			toneapi_data.matchId = expect int(data.match)
            ToneAPI_Log("Tone API Online !")
			ToneAPI_Log("Sending kills with match ID : " + data.match)
		}
	)
}

void function ToneAPI_Log(string s) {
	print(prefix + s)
}