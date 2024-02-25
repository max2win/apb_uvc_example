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
`ifndef SV_APB_AGENT
`define SV_APB_AGENT

// Description: agent class is a component. An active agent contains three
// sub-components: sequencer, driver and monitor. A passive agent contains
// only the monitor.
// 
// This particular agent can be configured either as master or responder

class apb_agent extends uvm_agent;

	apb_cfg       cfg;          // handle, do not instantiate
	protected int agent_kind;

	`uvm_component_utils_begin(apb_agent)
          `uvm_field_int(agent_kind, UVM_ALL_ON)
	`uvm_component_utils_end

	apb_sequencer seqr;
	apb_driver    drv;
	apb_monitor  mon;

	function new(string name = "apb_agent", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		mon  = apb_monitor  ::type_id::create("mon",  this);
		if ( get_is_active() == UVM_ACTIVE ) begin
			seqr = apb_sequencer::type_id::create("seqr", this);
			if (agent_kind == `IS_MASTER)
				drv  = apb_master_driver::type_id::create("drv",  this);
			else
				drv  = apb_slave_driver::type_id::create("drv",  this);
		end
	endfunction 

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		if (drv != null && seqr != null) 
		  drv.seq_item_port.connect(seqr.seq_item_export);
	endfunction 

endclass : apb_agent

`endif // SV_APB_AGENT
