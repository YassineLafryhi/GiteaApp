#!/bin/bash

svgPath="gitea.svg"

sizes=(128 256 16 32 256 512 32 64 512 1024)
files=("logo-128.png" "logo-256.png" "logo-16.png" "logo-16@2x.png" "logo-128@2x.png" "logo-256@2x.png" "logo-32.png" "logo-32@2x.png" "logo-512.png" "logo-512@2x.png")

for i in "${!sizes[@]}"; do
    inkscape "$svgPath" --export-filename="${files[$i]}" --export-width=${sizes[$i]} --export-height=${sizes[$i]}
done

mv ./*.png ./Gitea/Assets.xcassets/AppIcon.appiconset/
