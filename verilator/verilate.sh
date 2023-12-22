verilator \
-cc -exe --public --trace --savable \
--compiler msvc +define+SIMULATION=1 \
-O3 --x-assign fast --x-initial fast --noassert \
--converge-limit 6000 \
-Wno-UNOPTFLAT \
--top-module top bocks_sim.v \
./sdram_sim.v \
../rtl/vga.v \
../rtl/nibble_to_hex_text.v \
../rtl/byte_to_hex_text.v \
../rtl/double_to_hex_text.v \
../rtl/quad_to_hex_text.v \
../rtl/bocks_top.v