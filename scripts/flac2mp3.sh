for i in ./*.flac; do
  ffmpeg -i "$i" -q:a 0 "${i%.*}".mp3
done
