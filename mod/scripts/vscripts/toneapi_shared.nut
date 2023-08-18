globalize_all_functions

global string killstat_prefix = "\x1b[38;5;81m[TONE API]\x1b[0m "

void function Log(string s) {
	print(killstat_prefix + s)
}