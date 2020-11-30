set script_dir [file dirname [file normalize [info script]]]

set ::env(DESIGN_NAME) user_proj_example

set ::env(CLOCK_PORT) ""
set ::env(CLOCK_NET) "core_wrapper.wb_clk_i"
set ::env(CLOCK_PERIOD) "10"

set ::env(FP_SIZING) absolute
#set ::env(DIE_AREA) "0 0 2920 3520"
set ::env(DIE_AREA) "0 0 600 600"
set ::env(DESIGN_IS_CORE) 0

set ::env(FP_PIN_ORDER_CFG) $script_dir/pin_order.cfg
# set ::env(FP_CONTEXT_DEF) $script_dir/../user_project_wrapper/runs/user_project_wrapper/tmp/floorplan/ioPlacer.def.macro_placement.def
# set ::env(FP_CONTEXT_LEF) $script_dir/../user_project_wrapper/runs/user_project_wrapper/tmp/merged_unpadded.lef

set ::env(PL_BASIC_PLACEMENT) 1
set ::env(PL_TARGET_DENSITY) 0.15

set ::env(VERILOG_FILES) "\
	$script_dir/../../verilog/rtl/defines.v \
	$script_dir/../../verilog/rtl/user_proj_example.v \
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
	$script_dir/../../verilog/rtl/user_project_wrapper.v"
