#!/usr/bin/liquidsoap

# WJRH Station Repeater
# Pulls the WJRH stream from icecast and plays it on 
# the standard audio output

set("log.file.path","/home/wjrh/logs/repeater.log")
set("log.stdout", true)

#backup_songs = mksafe(playlist("/home/connor/backup_songs/music"))

live = strip_blank(
	max_blank=5.,
	input.http("http://www.wjrh.org:8000/WJRH")
)

#stream = fallback([live, backup_songs])

stream = mksafe(live)

output.pulseaudio(stream)
