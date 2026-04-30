#!/bin/sh
#
#  Imagemagick（convertコマンド）によるテキスト → 画像変換
#
#  magick [オプション] 入力ファイル 出力ファイル
#
#  オプションの説明
#    -geometry WxH 画像のサイズ WidthとHeight
#    -background 背景色
#    -fill この色で塗る
#    -gravity center 画面の中央に配置
#    -pointsize 文字の大きさ
#
#  入力ファイル
#    text:ファイル名でテキストファイルであることを指定
#
#  出力ファイル
#    画像ファイル形式は拡張子で判断
#
#
magick convert -geometry 500x1000     \
       -background white       \
       -fill black             \
       -gravity center         \
       -pointsize 200          \
       text:sample.txt         \
       _text_to_image.jpg

