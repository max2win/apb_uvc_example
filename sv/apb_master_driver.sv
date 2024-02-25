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
`ifndef SV_APB_MASTER_DRV
`define SV_APB_MASTER_DRV

class apb_master_driver extends apb_driver;
	`uvm_component_utils(apb_master_driver)

	int i;

	function new(string name = "apb_master_driver", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	// ---------------------------------------------------------
	// This is the APB's T1 phase, where the slave is addressed.
	// It is non-blocking and lasts 1 clock tick exactly.
	//
	virtual task apb_t1();
		@(posedge vif.pclk); // T1
		`uvm_info("DRV", $psprintf("T1"), UVM_DEBUG)
		vif.paddr    <= req.addr[7:0];
		vif.psel     <= 1 << req.addr[9:8];
		vif.penable  <= 1'b0;
		if (req.trtype inside {APB_WRITE, APB_WRITE_WAIT}) begin
			vif.pwrite <= 1'b1;
			vif.pwdata <= req.wdata;
		end
		else begin
			vif.pwrite <= 1'b0;
		end
	endtask : apb_t1

	// implements the API task for the master role
	virtual task get_and_drive();

		seq_item_port.get_next_item(req);
		`uvm_info("DRV", $psprintf("driving request #%0d:\n%s", i++, req.sprint()), UVM_NONE)
		rsp = apb_trans_item::type_id::create("rsp");
		rsp.copy(req);        // make a copy, so that rsp.trans_tout gets correctly initialized
		rsp.set_id_info(req); // copying the req ID is mandatory if you need to send back a response


		// Call the apb_t1 task here
		apb_t1();
		
		
		@(posedge vif.pclk); // T2
		`uvm_info("DRV", $psprintf("T2"), UVM_NONE)
		vif.penable<= 1'b1;
		do begin // T3
			@(posedge vif.pclk);
			`uvm_info("DRV", $psprintf("T3"), UVM_NONE)
			if (rsp.trans_tout-- <= 0) begin
				`uvm_error("DRV", $psprintf("master timed out!"))
				break;
			end
		end
		while (vif.pready != 1'b1);

		// at this point, rsp.trans_out tells how long the transaction lasted (0 if it timed out)

		rsp.slverr  = vif.pslverr;
		vif.psel   <=  'b0;
		vif.penable<= 1'b0;
		vif.pwdata <= 'h0;
		
		// using the analysis port, publish the reference data item
		ap.write(rsp); // for scoreboarding

		seq_item_port.item_done(rsp);
		`uvm_info("DRV", $psprintf("Done."), UVM_HIGH)
    endtask

	// From the direct_test example, import the init_driver task
	// Declare it as virtual.
	//
	// 
	virtual task init_driver();
		`uvm_info("DRV", $psprintf("init_driver..."), UVM_HIGH)
		vif.paddr  <= 'h0;
		vif.pwdata <= 'h0;
		vif.psel   <= 'b0;
		vif.penable<= 1'b0;
		@(posedge vif.pclk);
	endtask	

endclass : apb_master_driver

`endif // SV_APB_MASTER_DRV
