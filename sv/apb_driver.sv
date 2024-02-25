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
`ifndef SV_APB_DRIVER
`define SV_APB_DRIVER

class apb_driver extends uvm_driver #(apb_trans_item, apb_trans_item);
	`uvm_component_utils(apb_driver)

	uvm_analysis_port #(apb_trans_item) ap; // for scoreboarding

	virtual apb_if vif;

	function new(string name = "apb_driver", uvm_component parent = null);
		super.new(name, parent);
		if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
			`uvm_fatal(get_full_name(), "VIF not set!");
			
		// instantiate the analysis port
		ap = new("ap", this);
	endfunction

	// this is an API task for the driver, it will be redefined in the derived classes
	virtual task init_driver();
	endtask

	// this is an API task for the driver, it will be redefined in the derived classes
	virtual task get_and_drive();
	endtask

	// if one modifies just the called tasks, there is no need to redefine this
	virtual task run_phase(uvm_phase phase);
		init_driver;
		forever get_and_drive;
	endtask	

endclass : apb_driver

`endif // SV_APB_DRIVER
