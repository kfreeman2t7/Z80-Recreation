import subprocess

def proper_hex(x):
    return hex(x).replace("0x","").upper()

retro_assembler_dir = "C:\\Users\\Kenneth\\Documents\\retroassembler\\retroassembler.exe" #download at https://enginedesigns.net/retroassembler/
subprocess.run(retro_assembler_dir+" program.z80.asm")

data = open("program.bin",'rb')
bytes = data.read()
data.close()
opcodes = []
for byte in bytes:
    opcodes.append(proper_hex(byte))

while len(opcodes) < 2**16-1:
    opcodes.append(0)

header = '''WIDTH = {};
DEPTH = {};
ADDRESS_RADIX = HEX;
DATA_RADIX = HEX;

CONTENT BEGIN'''.format(8, len(opcodes))

footer = '''END;'''

addr = 0
mif = header

for op in opcodes:
    
    mif += "\n\t{} : {};".format(proper_hex(addr),op)

    addr += 1



mif += "\n"+footer


bytecode = open("program.mif",'w')
bytecode.write(mif)
bytecode.close()

bytecode = open("../CPU/program.mif",'w')
bytecode.write(mif)
bytecode.close()

subprocess.run("D:\\IntelFPGA_lite\\23.1std\\quartus\\bin64\\quartus_cdb --update_mif ..\\Z80")
subprocess.run("D:\\IntelFPGA_lite\\23.1std\\quartus\\bin64\\quartus_asm ..\\Z80")