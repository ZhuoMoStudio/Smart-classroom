import cairosvg
from PIL import Image

cairosvg.svg2png(url="assets/icon.svg", write_to="assets/icon.png", output_width=512, output_height=512)
img = Image.open("assets/icon.png")
img.save("icon.ico", format="ICO", sizes=[(256,256)])
print("Done: assets/icon.png and icon.ico generated.")