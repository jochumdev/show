#!/usr/bin/env -S nu

# https://www.mux.com/articles/how-to-create-webm-videos-with-ffmpeg
def main [
  input: string,
  output: string
] {
  ^ffmpeg -i $input -c:v libvpx-vp9 -b:v 3.5M -pass 1 -an -f null /dev/null
  ^ffmpeg -i $input -c:v libvpx-vp9 -b:v 3.5M -pass 2 -c:a libopus $output
}
