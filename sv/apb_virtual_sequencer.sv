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
`ifndef SV_APB_VSEQR
`define SV_APB_VSEQR

class apb_virtual_sequencer extends uvm_sequencer;
	`uvm_component_utils(apb_virtual_sequencer)

	apb_cfg       cfg;        // handle, do not instantiate
	apb_sequencer apb1_seqr;  // handle, do not instantiate
	apb_sequencer apb2_seqr;  // handle, do not instantiate

	function new(string name = "apb_virtual_sequencer", uvm_component parent = null);
		super.new(name, parent);
	endfunction

endclass : apb_virtual_sequencer

`endif // SV_APB_VSEQR