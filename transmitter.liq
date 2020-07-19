#!/usr/bin/liquidsoap

# WJRH Station Repeater
# Pulls the WJRH stream from icecast and plays it on 
# the standard audio output

%include "/home/wjrh/bin/config.liq"

set("log.file.path","/home/wjrh/logs/.log")
set("log.stdout", true)

# Set up our 3 sources

# live source, pulls from the official wjrh stream
# This is the nominal source, it is what we should be hearing
# if nothing is broken

# strip_blank command turns off the source during silence
# it is necessary to add this in order for the fallback command to work
live = strip_blank(
	# number of seconds before a silent source is considered blank
	max_blank=30.,
	# url of the stream to pull from
	input.http("http://www.wjrh.org:8000/WJRH")
)

# robodj_direct source, plays from the dedicated robodj stream
# If something goes wrong with the board or official stream, but
# the robodj is still up, we will switch to this
#
# This commonly happens when DJs forget to switch the board back
# to robodj before leaving the studio
robodj_direct = strip_blank(
	max_blank=30.,
	input.http("http://www.wjrh.org:8000/WJRH-RoboDJ")
)

# A playlist of local backup songs to play when both of the 
# above streams are down. This should serve as a replacement for 
# the infamous "Pfaffman Playlist" which currently lives on the transmitter
# and plays whenever everything else is silent.
#
# The Pfaffman Playlist is limited by the transmitter to only 20 minutes
# of songs. In contrast, this playlist can be many hundreds of gigabytes
# and should therefore be much more bearable to the people of easton
# during outages
backup_songs = mksafe(playlist(
	mode="randomize",
	reload=1,
	reload_mode="rounds",
	"/home/wjrh/backup_songs/music"
))


# If any of the above sources fail, we should log it and notify
# someone. Define handlers to be called on silence
def on_live_silence()
	system("/home/wjrh/bin/log-script 'wjrh stream is down'")
end
# call this whenever silence is detected
live = on_blank(on_live_silence, live)

# Do the same thing for robodj
def on_robo_silence()
	system("/home/wjrh/bin/log-script 'robodj stream is down'")
end
robodj_direct = on_blank(on_robo_silence, robodj_direct)

# Build the output by combining the above three sources
# with the fallback command
stream = fallback(
	# do not wait for a track to end before switching back to a stream
	track_sensitive=false,
	# Set the priority of each source, with live at the top
	[live, robodj_direct, backup_songs]
)



output.pulseaudio(stream)

output.icecast(%mp3,
	host="wjrh.org",
	port=8000,
	password=icecast_password,
	name="Transmitter",
	description="For testing purposes only. A stream mirroring what the computer in the transmitter room is outputing into the transmitter. If this is silent or down, it is likely nothing is playing on air",
	mount="transmitter",
	stream
)
