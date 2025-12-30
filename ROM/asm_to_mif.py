import subprocess

def proper_hex(x):
    return hex(x).replace("0x","").upper()

retro_assembler_dir = "C:\\Users\\Kenneth\\Documents\\retroassembler\\retroassembler.exe" #download at https://enginedesigns.net/retroassembler/
subprocess.run(retro_assembler_dir+" program.z80.asm")

data = open("program.bin")
chars = data.read()
data.close()
opcodes = [0]
for char in chars:
    opcodes.append(proper_hex(ord(char)))

opcodes.append(0)

header = '''WIDTH = {};
DEPTH = {};
ADDRESS_RADIX = HEX;
DATA_RADIX = HEX;

CONTENT BEGIN'''.format(8, 8*len(opcodes))


footer = '''END;'''

addr = 0
mif = header
for op in opcodes:
    
    mif += "\n\t{} : {};".format(proper_hex(addr),op)

    addr += 1

mif += "\n"+footer

print(mif)

bytecode = open("program.mif",'w')
bytecode.write(mif)
bytecode.close()