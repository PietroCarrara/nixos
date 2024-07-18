{ cuetools }:

''
  ${cuetools}/bin/cuebreakpoints *.cue | shnsplit -o flac *.flac
  ${cuetools}/bin/cuetag.sh *.cue split-*.flac
''
