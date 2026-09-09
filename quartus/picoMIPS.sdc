# =============================================================================
# picoMIPS.sdc  --  Timing Constraints
# Top-level port: fastclk (50 MHz, PIN_AF14)
# =============================================================================

create_clock -name clk -period 20.000 [get_ports clk]
set_false_path -from [get_ports {SW[*]}]
set_false_path -to   [get_ports {LED[*]}]

# Uncomment it for the 7-seg display

#create_clock \
#    -name fastclk \
#   -period 20.000 \
#    [get_ports fastclk]
	
#set_false_path -from [get_ports {SW[*]}]
#set_false_path -to   [get_ports {LED[*]}]
#set_false_path -to   [get_ports {HEX0[*]}]
#set_false_path -to   [get_ports {HEX1[*]}]
#set_false_path -to   [get_ports {HEX2[*]}]
#set_false_path -to   [get_ports {HEX3[*]}]

