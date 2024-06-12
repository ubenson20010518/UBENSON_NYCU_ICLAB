###############################################################
#  Generated by:      Cadence Innovus 20.15-s105_1
#  OS:                Linux x86_64(Host ID ee27)
#  Generated on:      Wed May 29 22:51:07 2024
#  Design:            CHIP
#  Command:           routeDesign -globalDetail -viaOpt -wireOpt
###############################################################
current_design CHIP
create_clock [get_ports {clk}]  -name clk -period 20.000000 -waveform {0.000000 10.000000}
set_propagated_clock  [get_ports {clk}]
set_drive 0.1  [get_ports {clk}]
set_drive 0.1  [get_ports {rst_n}]
set_drive 0.1  [get_ports {in_valid}]
set_drive 0.1  [get_ports {in_weight[2]}]
set_drive 0.1  [get_ports {in_weight[1]}]
set_drive 0.1  [get_ports {in_weight[0]}]
set_drive 0.1  [get_ports {out_mode}]
set_load -pin_load -max  20  [get_ports {out_valid}]
set_load -pin_load -min  20  [get_ports {out_valid}]
set_load -pin_load -max  20  [get_ports {out_code}]
set_load -pin_load -min  20  [get_ports {out_code}]
set_input_delay -add_delay 10 -clock [get_clocks {clk}] [get_ports {in_valid}]
set_input_delay -add_delay 10 -clock [get_clocks {clk}] [get_ports {rst_n}]
set_input_delay -add_delay 10 -clock [get_clocks {clk}] [get_ports {in_weight[2]}]
set_input_delay -add_delay 10 -clock [get_clocks {clk}] [get_ports {in_weight[0]}]
set_input_delay -add_delay 10 -clock [get_clocks {clk}] [get_ports {out_mode}]
set_input_delay -add_delay 10 -clock [get_clocks {clk}] [get_ports {in_weight[1]}]
set_output_delay -add_delay 10 -clock [get_clocks {clk}] [get_ports {out_valid}]
set_output_delay -add_delay 10 -clock [get_clocks {clk}] [get_ports {out_code}]
