#!/usr/bin/env nu
let the_banner = [
'	 $$$$$$\                                 $$$$$$\                                ',
'	$$  __$$\                               $$  __$$\                               ',
'	$$ /  $$ | $$$$$$\   $$$$$$\  $$$$$$$\  $$ /  $$ | $$$$$$$\  $$$$$$\   $$$$$$\  ',
'	$$ |  $$ |$$  __$$\ $$  __$$\ $$  __$$\ $$$$$$$$ |$$  _____| \____$$\ $$  __$$\ ',
'	$$ |  $$ |$$ /  $$ |$$$$$$$$ |$$ |  $$ |$$  __$$ |\$$$$$$\   $$$$$$$ |$$ |  \__|',
'	$$ |  $$ |$$ |  $$ |$$   ____|$$ |  $$ |$$ |  $$ | \____$$\ $$  __$$ |$$ |      ',
'	 $$$$$$  |$$$$$$$  |\$$$$$$$\ $$ |  $$ |$$ |  $$ |$$$$$$$  |\$$$$$$$ |$$ |      ',
'	 \______/ $$  ____/  \_______|\__|  \__|\__|  \__|\_______/  \_______|\__|      ',
'	          $$ | OpenAsar installer script for Nushell 0.116.0+                   ',
'	          $$ |                                                                  ',
'	          \__|  																',
"\n",
'===================================================================================',
] | ansi gradient -F atlast

# Prints out the super cool ASCII art
for x in $the_banner {print $x}

# A function to call back to that tries to kill the Discord process
def kill_discord [] {
	ps | where name =~ "Discord" | get pid | first | kill -f -q $in
}

sleep 3sec # Dramatic pause for the effect

print "Checking for and attempting to close Discord...please wait.\n"

# Checks for the Discord process and returns boolean
let is_discord_running = (ps | where name =~ "Discord" | is-not-empty) # Looking to remoe this

# If Discord is running then attempt to kill it
while (ps | where name =~ "Discord" | is-not-empty) { kill_discord }

# Wait for processes to fully terminate
sleep 5sec

# Double checks to make sure it isn't running but if so abort the script.
if (ps | where name =~ 'Discord' | is-empty) {
	print "Discord has been closed...continuing.\n"
} else {
	print "There was a problem closing Discord. Please manually close it and try the script again.\n"
	exit --abort
}

# Locate the Discord directory in LOCALAPPDATA
let discord_dir = ($env.LOCALAPPDATA | path join "Discord")

# Find the highest version of Discord installed by matching app-* and sorting
let latest_app = (ls $discord_dir | where name =~ "app-"
    | sort-by name 
    | get name 
    | last)

if ($latest_app | is-empty) {
    error make {msg: "No Discord installation found!\n"}
}

print $"(ansi green)Found latest Discord version at: ($latest_app)(ansi reset)\n"

let resources_dir = ($latest_app | path join "resources")
let app_asar = ($resources_dir | path join "app.asar")
let backup_asar = ($resources_dir | path join "app.asar.backup")
let backup_alt_asar = ($resources_dir | path join "_app.asar.backup")

print "Installing OpenAsar...\n"

# Backup existing app.asar or alternative variants if they exist
if ($app_asar | path exists) {
    cp -f $app_asar $backup_asar
}

let alt_app_asar = ($resources_dir | path join "_app.asar")
let orig_app_asar = ($resources_dir | path join "app.asar.orig")

if ($alt_app_asar | path exists) {
    cp -f $alt_app_asar $backup_alt_asar
	if ($backup_alt_asar | path exists) {
		print "Found and backed up \"_app.asar\" file.\n"
	}
}
if ($orig_app_asar | path exists) {
    cp -f $orig_app_asar $backup_asar
	if ($backup_asar | path exists) {
		print "Backed up \"app.asar\" file.\n"
	}
}

sleep 1sec # Dramatic pause.

# Download OpenAsar nightly build directly into the latest version's resources folder
try {
	print "Downloading OpenAsar nightly directly to the appropriate Discord folder...\n"
	http get https://github.com/GooseMod/OpenAsar/releases/download/nightly/app.asar | save -f $app_asar
} catch {
	|err| $err.msg
}

# Check to see if the file was downloaded to the proper directory and if not abort the script
if ($app_asar | path exists) {
	print "Download and installation sucessful!\n"
} else {
	print "There was a problem downloading or installing OpenAsar. Retry this script again."
	print "This script will now close in 5 seconds."
	sleep 5sec
	exit --abort
}

# Start up Discord using Discord's update.exe
print "Opening Discord...\n"
^($discord_dir | path join "Update.exe") --processStart Discord.exe

sleep 1sec

print ""
print "OpenAsar should be installed! You can check by looking for an \"OpenAsar\" option in your Discord settings."
print "Not installed? Try restarting Discord, running the script again, or joining our Discord server."
print "openasar.dev"