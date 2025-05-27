.PHONY: all fasm68k clownassembler clown diff diff-count

all: fasm68k

fasm68k:
	sleep 1
	../../fasm68k sonic.asm -e200 -v2 fasm68k_artifacts/sonic.bin
	sleep 1
	xxd -b -c1 fasm68k_artifacts/sonic.bin | cut -d' ' -f2 > fasm68k_artifacts/sonic.hex
	sleep 1
	git diff --no-index clownassembler_artifacts/sonic.hex fasm68k_artifacts/sonic.hex | wc -l > diffing_lines.txt

vasm:
	clownassembler -noialign -L clownassembler_artifacts/sonic.lst -no-opt -Fbin -spaces -wfail -o clownassembler_artifacts/sonic.bin sonic.asm
	xxd -b -c1 clownassembler_artifacts/sonic.bin | cut -d' ' -f2 > clownassembler_artifacts/sonic.hex

# clownassembler can't assemble sonic.
clown:
	# -w silences warnings.
	clownassembler -c -w -o clownassembler_artifacts/sonic.bin -i sonic.asm
	xxd -b -c1 clownassembler_artifacts/sonic.bin | cut -d' ' -f2 > clownassembler_artifacts/sonic.hex

diff:
	git diff --no-index clownassembler_artifacts/sonic.hex fasm68k_artifacts/sonic.hex

diff-count:
	git diff --no-index clownassembler_artifacts/sonic.hex fasm68k_artifacts/sonic.hex | wc -l
