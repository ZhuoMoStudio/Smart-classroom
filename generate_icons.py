import cairosvg
from PIL import Image

cairosvg.svg2png(url="assets/icon.svg", write_to="icon.png", output_width=512, output_height=512)
img = Image.open("icon.png")
img.save("icon.ico", format="ICO", sizes=[(16,16),(32,32),(48,48),(256,256)])
print("✅ icon.png 和 icon.ico 已生成")