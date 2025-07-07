onerror {quit -f}
vlib work
vlog -work work elevador_rtl.vo
vlog -work work elevador_rtl.vt
vsim -novopt -c -t 1ps -L cycloneii_ver -L altera_ver -L altera_mf_ver -L 220model_ver -L sgate work.elevador_rtl_vlg_vec_tst
vcd file -direction elevador_rtl.msim.vcd
vcd add -internal elevador_rtl_vlg_vec_tst/*
vcd add -internal elevador_rtl_vlg_vec_tst/i1/*
add wave /*
run -all
