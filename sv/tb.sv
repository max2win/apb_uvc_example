/*
*
* Copyright 2023 Massimo Vincenzi
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*    http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
*/

`include "apb_uvc_pkg.sv"

`ifndef SV_TB_TOP
`define SV_TB_TOP

module tb;
	timeunit 1ns;
	timeprecision 1ps;

	// -------------------------------------
	// includes
	// -------------------------------------

	// -------------------------------------
	// declarations
	// -------------------------------------
	logic pclk, preset;

	// -------------------------------------
	// interfaces
	// -------------------------------------
	apb_if apb_1(.pclk(pclk), .preset(preset));

	// -------------------------------------
	// clocks, resets
	// -------------------------------------
	initial begin
		pclk = 0;
		forever #5ns pclk = ~pclk;
	end

	`ifdef DEBUG_TB_CLOCK
	always @(posedge pclk) begin
		$display("tick %t", $realtime);
	end
	`endif

	// -------------------------------------
	// DUT instance
	// -------------------------------------
	// `include "dut_inst.v"

	// -------------------------------------
	// Non-UVM verification components
	// -------------------------------------

	// -------------------------------------
	// UVM section
	// -------------------------------------
	import uvm_pkg::*;
	`include "uvm_macros.svh"
	import apb_uvc_pkg::*;

	initial begin
		// In this section, we link the physical APB interface to each of the virtual interfaces in the agents
		// For each component referencing a virtual interface, we must bind the physical SV interface to it
		// We will instantiate 2 agents, each containing a driver and a monitor, 4 virtual interface handles in total.
		// For each of them, we bind the same SV interface named 'apb_1' to the virtual interface handle,
		// named 'vif' everywhere for consistency.
		//
		uvm_config_db#(virtual apb_if)::set(null, "uvm_test_top.env.apb_master.drv", "vif", apb_1);
		uvm_config_db#(virtual apb_if)::set(null, "uvm_test_top.env.apb_master.mon", "vif", apb_1);
		uvm_config_db#(virtual apb_if)::set(null, "uvm_test_top.env.apb_slave.drv",  "vif", apb_1);
		uvm_config_db#(virtual apb_if)::set(null, "uvm_test_top.env.apb_slave.mon",  "vif", apb_1);


		// we will run a very basic test, whose goal is to check the testbench connectivity, the
		// basic agent transactions, etc.
		// Remove the argument from run_test. We will use +UVM_TESTNAME to select which test to run.
		run_test();
	end

endmodule // tb
`endif
