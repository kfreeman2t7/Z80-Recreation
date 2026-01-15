onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/clk
add wave -noupdate /tb/cpu/core/regfile/ram_read_addr
add wave -noupdate /tb/cpu/core/regfile/ram_write_data
add wave -noupdate /tb/cpu/core/regfile/ram_wren
add wave -noupdate /tb/cpu/core/regfile/ram_read
add wave -noupdate -group IR /tb/cpu/core/IR_FETCH
add wave -noupdate -group IR /tb/cpu/core/IR_READ
add wave -noupdate -group IR /tb/cpu/core/IR_WRITE
add wave -noupdate -divider <NULL>
add wave -noupdate /tb/cpu/core/OP_FETCH
add wave -noupdate /tb/cpu/core/OP_READ
add wave -noupdate /tb/cpu/core/OP_WRITE
add wave -noupdate -divider <NULL>
add wave -noupdate -expand /tb/cpu/core/regfile/reg_arr
add wave -noupdate /tb/cpu/core/regfile/SP
add wave -noupdate /tb/cpu/core/regfile/F
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1912214 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 235
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {1341527 ps} {2366458 ps}
