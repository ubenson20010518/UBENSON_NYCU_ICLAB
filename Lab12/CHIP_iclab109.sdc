###################################################################

# Created by write_sdc on Sat May 25 23:39:45 2024

###################################################################
set sdc_version 2.1

set_units -time ns -resistance kOhm -capacitance pF -voltage V -current mA
set_load -pin_load 0.05 [get_ports out_valid]
set_load -pin_load 0.05 [get_ports out_value]
set_max_capacitance 0.15 [get_ports clk]
set_max_capacitance 0.15 [get_ports rst_n]
set_max_capacitance 0.15 [get_ports in_valid]
set_max_capacitance 0.15 [get_ports in_valid2]
set_max_capacitance 0.15 [get_ports mode]
set_max_capacitance 0.15 [get_ports {matrix_size[1]}]
set_max_capacitance 0.15 [get_ports {matrix_size[0]}]
set_max_capacitance 0.15 [get_ports {matrix[7]}]
set_max_capacitance 0.15 [get_ports {matrix[6]}]
set_max_capacitance 0.15 [get_ports {matrix[5]}]
set_max_capacitance 0.15 [get_ports {matrix[4]}]
set_max_capacitance 0.15 [get_ports {matrix[3]}]
set_max_capacitance 0.15 [get_ports {matrix[2]}]
set_max_capacitance 0.15 [get_ports {matrix[1]}]
set_max_capacitance 0.15 [get_ports {matrix[0]}]
set_max_capacitance 0.15 [get_ports {matrix_idx[3]}]
set_max_capacitance 0.15 [get_ports {matrix_idx[2]}]
set_max_capacitance 0.15 [get_ports {matrix_idx[1]}]
set_max_capacitance 0.15 [get_ports {matrix_idx[0]}]
set_max_fanout 10 [get_ports clk]
set_max_fanout 10 [get_ports rst_n]
set_max_fanout 10 [get_ports in_valid]
set_max_fanout 10 [get_ports in_valid2]
set_max_fanout 10 [get_ports mode]
set_max_fanout 10 [get_ports {matrix_size[1]}]
set_max_fanout 10 [get_ports {matrix_size[0]}]
set_max_fanout 10 [get_ports {matrix[7]}]
set_max_fanout 10 [get_ports {matrix[6]}]
set_max_fanout 10 [get_ports {matrix[5]}]
set_max_fanout 10 [get_ports {matrix[4]}]
set_max_fanout 10 [get_ports {matrix[3]}]
set_max_fanout 10 [get_ports {matrix[2]}]
set_max_fanout 10 [get_ports {matrix[1]}]
set_max_fanout 10 [get_ports {matrix[0]}]
set_max_fanout 10 [get_ports {matrix_idx[3]}]
set_max_fanout 10 [get_ports {matrix_idx[2]}]
set_max_fanout 10 [get_ports {matrix_idx[1]}]
set_max_fanout 10 [get_ports {matrix_idx[0]}]
set_max_transition 3 [get_ports clk]
set_max_transition 3 [get_ports rst_n]
set_max_transition 3 [get_ports in_valid]
set_max_transition 3 [get_ports in_valid2]
set_max_transition 3 [get_ports mode]
set_max_transition 3 [get_ports {matrix_size[1]}]
set_max_transition 3 [get_ports {matrix_size[0]}]
set_max_transition 3 [get_ports {matrix[7]}]
set_max_transition 3 [get_ports {matrix[6]}]
set_max_transition 3 [get_ports {matrix[5]}]
set_max_transition 3 [get_ports {matrix[4]}]
set_max_transition 3 [get_ports {matrix[3]}]
set_max_transition 3 [get_ports {matrix[2]}]
set_max_transition 3 [get_ports {matrix[1]}]
set_max_transition 3 [get_ports {matrix[0]}]
set_max_transition 3 [get_ports {matrix_idx[3]}]
set_max_transition 3 [get_ports {matrix_idx[2]}]
set_max_transition 3 [get_ports {matrix_idx[1]}]
set_max_transition 3 [get_ports {matrix_idx[0]}]
create_clock [get_ports clk]  -period 10  -waveform {0 5}
# set_clock_uncertainty 0.1  [get_clocks clk]
# set_clock_transition -max -rise 0.1 [get_clocks clk]
# set_clock_transition -max -fall 0.1 [get_clocks clk]
# set_clock_transition -min -rise 0.1 [get_clocks clk]
# set_clock_transition -min -fall 0.1 [get_clocks clk]
set_input_delay -clock clk  0  [get_ports clk]
set_input_delay -clock clk  0  [get_ports rst_n]
set_input_delay -clock clk  -max 5  [get_ports in_valid]
set_input_delay -clock clk  -min 0  [get_ports in_valid]
set_input_delay -clock clk  -max 5  [get_ports in_valid2]
set_input_delay -clock clk  -min 0  [get_ports in_valid2]
set_input_delay -clock clk  -max 5  [get_ports mode]
set_input_delay -clock clk  -min 0  [get_ports mode]
set_input_delay -clock clk  -max 5  [get_ports {matrix_size[1]}]
set_input_delay -clock clk  -min 0  [get_ports {matrix_size[1]}]
set_input_delay -clock clk  -max 5  [get_ports {matrix_size[0]}]
set_input_delay -clock clk  -min 0  [get_ports {matrix_size[0]}]
set_input_delay -clock clk  -max 5  [get_ports {matrix[7]}]
set_input_delay -clock clk  -min 0  [get_ports {matrix[7]}]
set_input_delay -clock clk  -max 5  [get_ports {matrix[6]}]
set_input_delay -clock clk  -min 0  [get_ports {matrix[6]}]
set_input_delay -clock clk  -max 5  [get_ports {matrix[5]}]
set_input_delay -clock clk  -min 0  [get_ports {matrix[5]}]
set_input_delay -clock clk  -max 5  [get_ports {matrix[4]}]
set_input_delay -clock clk  -min 0  [get_ports {matrix[4]}]
set_input_delay -clock clk  -max 5  [get_ports {matrix[3]}]
set_input_delay -clock clk  -min 0  [get_ports {matrix[3]}]
set_input_delay -clock clk  -max 5  [get_ports {matrix[2]}]
set_input_delay -clock clk  -min 0  [get_ports {matrix[2]}]
set_input_delay -clock clk  -max 5  [get_ports {matrix[1]}]
set_input_delay -clock clk  -min 0  [get_ports {matrix[1]}]
set_input_delay -clock clk  -max 5  [get_ports {matrix[0]}]
set_input_delay -clock clk  -min 0  [get_ports {matrix[0]}]
set_input_delay -clock clk  -max 5  [get_ports {matrix_idx[3]}]
set_input_delay -clock clk  -min 0  [get_ports {matrix_idx[3]}]
set_input_delay -clock clk  -max 5  [get_ports {matrix_idx[2]}]
set_input_delay -clock clk  -min 0  [get_ports {matrix_idx[2]}]
set_input_delay -clock clk  -max 5  [get_ports {matrix_idx[1]}]
set_input_delay -clock clk  -min 0  [get_ports {matrix_idx[1]}]
set_input_delay -clock clk  -max 5  [get_ports {matrix_idx[0]}]
set_input_delay -clock clk  -min 0  [get_ports {matrix_idx[0]}]
set_output_delay -clock clk  -max 5  [get_ports out_valid]
set_output_delay -clock clk  -min 0  [get_ports out_valid]
set_output_delay -clock clk  -max 5  [get_ports out_value]
set_output_delay -clock clk  -min 0  [get_ports out_value]
set_input_transition -max 0.5  [get_ports clk]
set_input_transition -min 0.5  [get_ports clk]
set_input_transition -max 0.5  [get_ports rst_n]
set_input_transition -min 0.5  [get_ports rst_n]
set_input_transition -max 0.5  [get_ports in_valid]
set_input_transition -min 0.5  [get_ports in_valid]
set_input_transition -max 0.5  [get_ports in_valid2]
set_input_transition -min 0.5  [get_ports in_valid2]
set_input_transition -max 0.5  [get_ports mode]
set_input_transition -min 0.5  [get_ports mode]
set_input_transition -max 0.5  [get_ports {matrix_size[1]}]
set_input_transition -min 0.5  [get_ports {matrix_size[1]}]
set_input_transition -max 0.5  [get_ports {matrix_size[0]}]
set_input_transition -min 0.5  [get_ports {matrix_size[0]}]
set_input_transition -max 0.5  [get_ports {matrix[7]}]
set_input_transition -min 0.5  [get_ports {matrix[7]}]
set_input_transition -max 0.5  [get_ports {matrix[6]}]
set_input_transition -min 0.5  [get_ports {matrix[6]}]
set_input_transition -max 0.5  [get_ports {matrix[5]}]
set_input_transition -min 0.5  [get_ports {matrix[5]}]
set_input_transition -max 0.5  [get_ports {matrix[4]}]
set_input_transition -min 0.5  [get_ports {matrix[4]}]
set_input_transition -max 0.5  [get_ports {matrix[3]}]
set_input_transition -min 0.5  [get_ports {matrix[3]}]
set_input_transition -max 0.5  [get_ports {matrix[2]}]
set_input_transition -min 0.5  [get_ports {matrix[2]}]
set_input_transition -max 0.5  [get_ports {matrix[1]}]
set_input_transition -min 0.5  [get_ports {matrix[1]}]
set_input_transition -max 0.5  [get_ports {matrix[0]}]
set_input_transition -min 0.5  [get_ports {matrix[0]}]
set_input_transition -max 0.5  [get_ports {matrix_idx[3]}]
set_input_transition -min 0.5  [get_ports {matrix_idx[3]}]
set_input_transition -max 0.5  [get_ports {matrix_idx[2]}]
set_input_transition -min 0.5  [get_ports {matrix_idx[2]}]
set_input_transition -max 0.5  [get_ports {matrix_idx[1]}]
set_input_transition -min 0.5  [get_ports {matrix_idx[1]}]
set_input_transition -max 0.5  [get_ports {matrix_idx[0]}]
set_input_transition -min 0.5  [get_ports {matrix_idx[0]}]
