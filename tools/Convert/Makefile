.PHONY: clean

_animation.gif: generate_gif_animation.sh _workdir
	./generate_gif_animation.sh

_workdir: image_blur.sh _text_to_image.jpg
	./image_blur.sh

_text_to_image.jpg: text_to_image.sh sample.txt
	./text_to_image.sh

clean:
	rm -f  _text_to_image.jpg _output.gif
	rm -rf _workdir
