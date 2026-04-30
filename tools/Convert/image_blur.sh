#!/bin/sh

# 作業用ディレクトリ（存在しなければ作る。あれば再利用。）
mkdir -p _workdir

# 作業用ディレクトリ中にjpgファイルがあれば削除しておく。
rm -f _workdir/*.jpg

for i in `seq 0 2 50`   # 数列 0, 2, 4, ..., 50
do
  num=`printf %03d $i`  # 3桁に0パディング
  blur_param=${i}x${i}  # 0x0, 2x2, 4x4, etc. 下で使う 
  output=$num.jpg       # 000.jpg, 002.jpg, etc.
  echo generating _workdir/$output
  magick _text_to_image.jpg -gaussian-blur $blur_param _workdir/$output
done
