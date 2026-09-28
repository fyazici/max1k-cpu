
rem C:\Users\fyazici\scoop\apps\ghdl\current\lib\ghdl\vendors\compile-altera.ps1 -Altera -VHDL2008 -Source "C:\altera_lite\25.1std\quartus\eda\sim_lib"

ghdl -i --std=08 -fsynopsys --workdir=work/ -P=altera/ ../src/cpu/*.vhd
ghdl -i --std=08 -fsynopsys --workdir=work/ -P=altera/ ../src/wb/*.vhd
ghdl -i --std=08 -fsynopsys --workdir=work/ -P=altera/ ../src/util/*.vhd
ghdl -i --std=08 -fsynopsys --workdir=work/ -P=altera/ ../src/periph/*.vhd
ghdl -i --std=08 -fsynopsys --workdir=work/ -P=altera/ ../src/boot/*.vhd
ghdl -i --std=08 -fsynopsys --workdir=work/ -P=altera/ tb_cpu.vhd ../src/*.vhd
ghdl -m --std=08 -fsynopsys --workdir=work/ -P=altera/ --warn-no-hide tb_cpu
rem ghdl -r --std=08 -fsynopsys --workdir=work/ -P=altera/ tb_cpu --ieee-asserts=disable --vcd=tb_cpu.vcd --stop-time=100us
ghdl -r --std=08 -fsynopsys --workdir=work/ -P=altera/ tb_cpu --ieee-asserts=disable --stop-time=60ms
