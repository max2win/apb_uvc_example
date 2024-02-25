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

`ifndef SV_APB_PKG
`define SV_APB_PKG

`include "apb_if.sv"

package apb_uvc_pkg;
	`include "uvm_macros.svh"
	import uvm_pkg::*;

	typedef enum bit[1:0] {
		APB_READ       = 0,
		APB_WRITE      = 1,
		APB_READ_WAIT  = 2,
		APB_WRITE_WAIT = 3
	} apb_trtype_t;
	
  `define IS_MASTER 0
	`define IS_SLAVE  1

	`include "apb_cfg.sv"
	`include "apb_seq_lib.sv"
	`include "apb_sequencer.sv"
	`include "apb_driver.sv"
	`include "apb_master_driver.sv"
	`include "apb_slave_driver.sv"
	`include "apb_monitor.sv"
	`include "apb_agent.sv"
	`include "apb_cov_collector.sv"
	`include "apb_virtual_sequencer.sv"
	`include "apb_scoreboard.sv"
	`include "apb_env.sv"
	`include "apb_test_lib.sv"

	typedef int foo;

endpackage

`endif // SV_APB_PKG
