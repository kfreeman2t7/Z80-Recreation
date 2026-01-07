from PIL import Image

def proper_hex(x):
    return hex(x).replace("0x","").upper()

img = Image.open("8x8font.png").convert("RGB")

pixels = []

for tileY in range(int(img.height/8)):
    for tileX in range(int(img.width/8)):
        for y in range(8):
            for x in range(8):
                pix = img.getpixel((tileX*8+x,tileY*8+y))
                print(pix)
                pix_str = proper_hex(pix[0])+proper_hex(pix[1])+proper_hex(pix[2])
                pixels.append(pix_str)


header = '''WIDTH = {};
DEPTH = {};
ADDRESS_RADIX = HEX;
DATA_RADIX = HEX;

CONTENT BEGIN'''.format(24, len(pixels))

footer = '''END;'''

addr = 0
mif = header

for op in pixels:
    
    mif += "\n\t{} : {};".format(proper_hex(addr),op)

    addr += 1



mif += "\n"+footer


bytecode = open("text.mif",'w')
bytecode.write(mif)
bytecode.close()

#img.getpixel()