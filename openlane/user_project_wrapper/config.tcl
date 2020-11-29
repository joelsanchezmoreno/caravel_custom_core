set script_dir [file dirname [file normalize [info script]]]

set ::env(DESIGN_NAME) user_project_wrapper
set ::env(FP_PIN_ORDER_CFG) $script_dir/pin_order.cfg

set ::env(CLOCK_PORT) "user_clock2"
set ::env(CLOCK_NET) "core_wrapper.wb_clk_i"

set ::env(CLOCK_PERIOD) "10"
 
set ::env(FP_PDN_CORE_RING) 1
set ::env(PDN_CFG) $script_dir/pdn.tcl
set ::env(FP_SIZING) absolute
set ::env(DIE_AREA) "0 0 2920 3520"
set ::env(PL_OPENPHYSYN_OPTIMIZATIONS) 0
set ::env(DIODE_INSERTION_STRATEGY) 0

#set ::env(DESIGN_IS_CORE) 0

#set ::env(PL_BASIC_PLACEMENT) 1
#set ::env(PL_TARGET_DENSITY) 0.15

set ::env(VERILOG_FILES) "\
	$script_dir/../../verilog/rtl/defines.v \
    $script_dir/../../verilog/rtl/custom_core/alu_top.v \
    $script_dir/../../verilog/rtl/custom_core/mul_stage.v \
    $script_dir/../../verilog/rtl/custom_core/mul_top.v \
    $script_dir/../../verilog/rtl/custom_core/tlb_cache.v \
    $script_dir/../../verilog/rtl/custom_core/cache_lru.v \
    $script_dir/../../verilog/rtl/custom_core/cache_top.v \
    $script_dir/../../verilog/rtl/custom_core/store_buffer.v \
    $script_dir/../../verilog/rtl/custom_core/data_cache.v \
    $script_dir/../../verilog/rtl/custom_core/regFile.v \
    $script_dir/../../verilog/rtl/custom_core/decode_top.v \
    $script_dir/../../verilog/rtl/custom_core/core_top.v \
    $script_dir/../../verilog/rtl/custom_core/writeback_xcpt.v \
    $script_dir/../../verilog/rtl/custom_core/reorder_buffer.v \
    $script_dir/../../verilog/rtl/custom_core/wb_top.v \
    $script_dir/../../verilog/rtl/custom_core/fetch_top.v \
    $script_dir/../../verilog/rtl/custom_core/instruction_cache.v \
	$script_dir/../../verilog/rtl/custom_core/core_top_wrapper.v \
	$script_dir/../../verilog/rtl/user_project_wrapper.v "
