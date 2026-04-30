#!/bin/sh
#  
#  アニメーションgifファイルを作るmagick convertコマンド
#
#  引数は N+1 個
#  形式は magick <入力> <出力>
#
#  <入力> N個の連番静止画像ファイル群  
#  <出力> 1個のgif（アニメ）ファイル
#

magick _workdir/*.jpg _output.gif
