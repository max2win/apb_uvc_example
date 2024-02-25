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
`ifndef SV_APB_CFG
`define SV_APB_CFG

class apb_cfg extends uvm_object;

	int n_iter = 1;

	`uvm_object_utils_begin(apb_cfg)
	    `uvm_field_int( n_iter, UVM_ALL_ON | UVM_DEC )
	`uvm_object_utils_end

	function new(string name = "apb_cfg");
		super.new(name);
		$value$plusargs("N_ITER=%d", n_iter);
	endfunction

endclass : apb_cfg

`endif // SV_APB_CFG