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
`ifndef SV_APB_MONITOR
`define SV_APB_MONITOR

class apb_monitor extends uvm_monitor;
	int TOUT = 12;

	`uvm_component_utils_begin(apb_monitor)
	    `uvm_field_int(TOUT, UVM_ALL_ON)
	`uvm_component_utils_end

	uvm_analysis_port #(apb_trans_item) ap;

	virtual apb_if vif;
	int i;

	function new(string name = "apb_monitor", uvm_component parent = null);
		super.new(name, parent);
		if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif)) `uvm_fatal(get_full_name(), "VIF not set!");
		ap = new("ap", this);
	endfunction

	virtual task collect();
		apb_trans_item item;

		do @(posedge vif.pclk); while (vif.psel == 1'b0);
		// @ T2:
		item = apb_trans_item::type_id::create("collected_item");
		item.trans_tout = TOUT;
		item.ws = 0;
		item.addr[7:0] = vif.paddr;
		if (!$onehot(vif.psel))
			item.addr[11:8] = 4'hF; // this will flag 'decode error'
		else
			item.addr[11:8] = $clog2(vif.psel);
		item.wdata     = vif.pwdata;
		item.rdata     = vif.prdata;
		item.trtype    = vif.pwrite ? APB_WRITE : APB_READ;
		item.slverr    = vif.pslverr;
		forever begin
			@(posedge vif.pclk);
			if (vif.pready == 1'b1) break;
			item.trans_tout--;
		end
		// @ T3:
		item.rdata  = vif.prdata;
		item.slverr = vif.pslverr;
		ap.write(item);
		`uvm_info("MON", $psprintf("collected item #%0d:\n%s", i++, item.sprint()), UVM_NONE)
		endtask

	virtual task run_phase(uvm_phase phase);
		`uvm_info("MON", $psprintf("started monitoring..."), UVM_HIGH)
		forever collect;
	endtask	

endclass : apb_monitor

`endif // SV_APB_MONITOR
