transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+D:/DE10-Nano_v.1.1.0_HWrevE_SystemCD/Projects/Z80-Recreation {D:/DE10-Nano_v.1.1.0_HWrevE_SystemCD/Projects/Z80-Recreation/z80_ram.v}
vlog -sv -work work +incdir+D:/DE10-Nano_v.1.1.0_HWrevE_SystemCD/Projects/Z80-Recreation/CPU {D:/DE10-Nano_v.1.1.0_HWrevE_SystemCD/Projects/Z80-Recreation/CPU/Z80.sv}
vlog -sv -work work +incdir+D:/DE10-Nano_v.1.1.0_HWrevE_SystemCD/Projects/Z80-Recreation/CPU {D:/DE10-Nano_v.1.1.0_HWrevE_SystemCD/Projects/Z80-Recreation/CPU/util.sv}
vlog -sv -work work +incdir+D:/DE10-Nano_v.1.1.0_HWrevE_SystemCD/Projects/Z80-Recreation/CPU {D:/DE10-Nano_v.1.1.0_HWrevE_SystemCD/Projects/Z80-Recreation/CPU/Arbiter.sv}
vlog -sv -work work +incdir+D:/DE10-Nano_v.1.1.0_HWrevE_SystemCD/Projects/Z80-Recreation/CPU {D:/DE10-Nano_v.1.1.0_HWrevE_SystemCD/Projects/Z80-Recreation/CPU/states.sv}
vlog -sv -work work +incdir+D:/DE10-Nano_v.1.1.0_HWrevE_SystemCD/Projects/Z80-Recreation/CPU {D:/DE10-Nano_v.1.1.0_HWrevE_SystemCD/Projects/Z80-Recreation/CPU/SM83.sv}
vlog -sv -work work +incdir+D:/DE10-Nano_v.1.1.0_HWrevE_SystemCD/Projects/Z80-Recreation/CPU {D:/DE10-Nano_v.1.1.0_HWrevE_SystemCD/Projects/Z80-Recreation/CPU/CPU_Internals.sv}

vlog -sv -work work +incdir+D:/DE10-Nano_v.1.1.0_HWrevE_SystemCD/Projects/Z80-Recreation {D:/DE10-Nano_v.1.1.0_HWrevE_SystemCD/Projects/Z80-Recreation/tb.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  Z80

add wave *
view structure
view signals
run -all
