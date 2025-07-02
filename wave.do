#add log {/tb_top/dut/*}
add log {/tb/*}
add log {/tb/learn_simple_soc_inst/*}
add log {/tb/learn_simple_soc_inst/memory_inst/*}
for {set i 0} {$i < 16} {incr i} {
    add log -r /tb/learn_simple_soc_inst/memory_inst/memory($i)
}
add log {/tb/learn_simple_soc_inst/interconnect_inst/*}
add log {/tb/learn_simple_soc_inst/picorv32_axi_inst/*}
add log {/tb/learn_simple_soc_inst/led_ctrl_inst/*}

add log {/tb/learn_simple_soc_inst/picorv32_axi_inst/axi_adapter/*}
add log {/tb/learn_simple_soc_inst/picorv32_axi_inst/picorv32_core/*}