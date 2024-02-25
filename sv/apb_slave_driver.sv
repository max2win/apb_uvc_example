/*
* Copyright (c) 2018 Massimo Vincenzi
* THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESSED OR IMPLIED WARRANTIES, 
* INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
* AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
* REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
* PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
* OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
* OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
* ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
* 
*/
`ifndef SV_APB_SLAVE_DRV
`define SV_APB_SLAVE_DRV

class apb_slave_driver extends apb_driver;
	`uvm_component_utils(apb_slave_driver)

	function new(string name = "apb_slave_driver", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	int i;

	virtual task init_driver();
		`uvm_info("SLV", $psprintf("init_driver..."), UVM_HIGH);
		vif.pslverr  <= 1'b0;
		vif.pready   <= 1'b0;
		vif.prdata   <=  'h0;
	endtask

	// implements the API task for the slave flavour
	virtual task get_and_drive();

		// the first request is a convenient way to start driver and sequence in sync
		// we are going to accept from the master only when the slave sequence is ready
		seq_item_port.get_next_item(req);
		`uvm_info("SLV", $psprintf("slave driver is armed."), UVM_HIGH)

		// wait until the slave is selected
		do @(posedge vif.pclk); while (vif.psel == 0);

		// we complete the outstanding sequence by returning the request from master
		// kind of reverse request...
		rsp = apb_trans_item::type_id::create(vif.pwrite ? "write_request" : "read_request", this);
		rsp.set_id_info(req);
		rsp.addr[7:0] = vif.paddr;
		if (!$onehot(vif.psel)) // psel must be onehot encoded
			rsp.addr[11:8] = 4'hF; // this will flag 'decode error'
		else
			rsp.addr[11:8] = $clog2(vif.psel); // bits [11:10] will always be zero if psel is 4 bits wide.
		rsp.trtype = vif.pwrite ? APB_WRITE : APB_READ;
		rsp.wdata  = vif.pwdata;
		rsp.rdata  = vif.prdata; // currently not used
		`uvm_info("SLV", $psprintf("request received:\n%s", rsp.sprint()), UVM_NONE)
		seq_item_port.item_done(rsp); // close the reverse request

		// get the response
		seq_item_port.get_next_item(req);

		`uvm_info("SLV", $psprintf("response #%0d:\n%s", i++, req.sprint()), UVM_NONE)
		repeat(req.ws) @(posedge vif.pclk);

		if (req.trtype inside {APB_READ, APB_READ_WAIT}) begin // this is the echo of the original pwrite, so if it not active, we must return data 
			vif.prdata <= req.rdata;
		end
		vif.pslverr  <= req.slverr;
		vif.pready   <= 1'b1;
		
		rsp = apb_trans_item::type_id::create("slave_completion", this);
		rsp.set_id_info(req);
		while (vif.psel == 1) begin
			rsp.ws++;
			@(posedge vif.pclk); 
		end
		vif.pslverr <= 0;
		vif.pready  <= 1'b0;
		vif.prdata  <= 'h0;
		seq_item_port.item_done(rsp);
	endtask

endclass : apb_slave_driver

`endif // SV_APB_SLAVE_DRV
