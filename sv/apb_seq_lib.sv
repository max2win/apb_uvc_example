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
`ifndef SV_APB_SEQ_LIB
`define SV_APB_SEQ_LIB

// This is what all components and sequences exchange through TLM channels.
// With sequence items, use randomization with care. It is preferable
// to randomize sequences rather than sequence items. You want to control
// constraints by specializing sequences, rather than specializing items
//
class apb_trans_item extends uvm_sequence_item;
	bit [11:0]      addr;
	apb_trtype_t    trtype;
	bit [31:0]      wdata;
	bit [31:0]      rdata;
	bit             slverr;
	int             ws;
	int             trans_tout; // if the slave does not respond within the given timeout, the master aborts.

	`uvm_object_utils_begin(apb_trans_item)
    	`uvm_field_int(addr,                     UVM_ALL_ON | UVM_HEX)
	    `uvm_field_enum(apb_trtype_t,    trtype, UVM_ALL_ON)
	    `uvm_field_int(wdata,                    UVM_ALL_ON | UVM_HEX)
	    `uvm_field_int(rdata,                    UVM_ALL_ON | UVM_HEX)
	    `uvm_field_int(slverr,                   UVM_ALL_ON)
	    `uvm_field_int(ws,                       UVM_ALL_ON)
	    `uvm_field_int(trans_tout,               UVM_ALL_ON | UVM_DEC)
	`uvm_object_utils_end

	function new(string name = "apb_trans_item");
		super.new(name);
	endfunction

endclass : apb_trans_item

class apb_basic_seq extends uvm_sequence #(apb_trans_item, apb_trans_item);
	rand bit [11:0]      addr;
	rand apb_trtype_t    trtype;
	rand bit [31:0]      wdata;
	rand bit [31:0]      rdata;
	rand bit             slverr;
	rand int             ws;
	rand int             trans_tout; // if the slave does not respond within the given timeout, the master aborts.

	`uvm_object_utils_begin(apb_basic_seq)
	    `uvm_field_int(addr,                     UVM_ALL_ON | UVM_HEX)
	    `uvm_field_enum(apb_trtype_t,    trtype, UVM_ALL_ON)
	    `uvm_field_int(wdata,                    UVM_ALL_ON | UVM_HEX)
	    `uvm_field_int(rdata,                    UVM_ALL_ON | UVM_HEX)
	    `uvm_field_int(slverr,                   UVM_ALL_ON)
	    `uvm_field_int(ws,                       UVM_ALL_ON)
	    `uvm_field_int(trans_tout,               UVM_ALL_ON | UVM_DEC)
	`uvm_object_utils_end

	// using soft constraints, one can randomize the sequence with relevant constraints only,
	// while the unspecified take the defaults
	//
	constraint psel_c       { soft addr[11:8]  == 0; }
	constraint trtype_c     { soft trtype inside { APB_READ, APB_WRITE}; }
	constraint slverr_c     { soft slverr     == 0;  }
	constraint ws_c         { soft ws         == 0;  }
	constraint trans_tout_c { soft trans_tout == 12; }

	function new(string name = "apb_basic_seq");
		super.new(name);
	endfunction

	protected apb_trans_item item;

	virtual task body();
		item = apb_trans_item::type_id::create("apb_trans");
		start_item(item);
		item.addr       = this.addr;
		item.trtype     = this.trtype;
		item.wdata      = this.wdata;
		item.rdata      = this.rdata;
		item.slverr     = this.slverr;
		item.ws         = this.ws;
		item.trans_tout = this.trans_tout;
		finish_item(item);
	endtask

endclass : apb_basic_seq

class apb_responder_seq extends uvm_sequence #(apb_trans_item, apb_trans_item);
	`uvm_object_utils(apb_responder_seq)

	bit [31:0] databuf[256];
	string tagname;

	function new(string name = "apb_responder_seq");
		super.new(name);
		tagname = "RESPONDER";
		// tagname = get_full_name();
	endfunction

	virtual task body();
		bit [7:0] addr8;
		forever begin
			// 1. accept requests
			`uvm_info(tagname, $psprintf("arm slave driver..."), UVM_HIGH)
			req = apb_trans_item::type_id::create("slave_ready");
			start_item(req);
			finish_item(req);

			// 2. decode and respond
			get_response(rsp);
			assert(rsp);
			req = apb_trans_item::type_id::create("slave_response");
			start_item(req);
			addr8      = rsp.addr[7:0];
			req.addr   = addr8;
			req.trtype = rsp.trtype;
			req.slverr = 0;
			req.ws     = 0;
			req.rdata  = databuf[addr8];
			if (rsp.trtype inside {APB_WRITE, APB_WRITE_WAIT}) begin
				`uvm_info(tagname, $psprintf("got WRITE request"), UVM_NONE)
				databuf[addr8] = rsp.wdata;
				req.wdata  = rsp.wdata;
				req.rdata  = 32'hdeadbeef;
			end else begin
				`uvm_info(tagname, $psprintf("got READ request"), UVM_NONE)
				req.wdata  = 32'hdeadbeef;
				req.rdata  = databuf[addr8];
			end
			finish_item(req);
			get_response(rsp);
			`uvm_info(tagname, $psprintf("transaction complete, mem@0x%0x: 0x%8x", addr8, databuf[addr8]), UVM_NONE)
			assert(rsp); // TODO: check that response is good
		end
	endtask

endclass : apb_responder_seq

// Using a forward declaration here for the virtual sequencer class
// which is not declared yet at this point.
typedef class apb_virtual_sequencer;

class apb_virtual_seq extends uvm_sequence;
	`uvm_object_utils(apb_virtual_seq)

	// We must explicitly create a handle 'p_sequencer' and make it
	// point the host sequencer running this virtual sequence.
	`uvm_declare_p_sequencer( apb_virtual_sequencer )

	apb_basic_seq     seq;

	function new(string name = "apb_virtual_seq");
		super.new(name);
	endfunction

	virtual task setup_responder;
		apb_responder_seq responder;
		responder = apb_responder_seq::type_id::create("slave_seq");
		assert(responder.randomize());

		fork : RESPONDER_THREAD // we just want to start the responder and continue
			responder.start( .sequencer( p_sequencer.apb2_seqr ) );
		join_none : RESPONDER_THREAD
	endtask

	virtual task main_sequence;
	endtask

	virtual task body();
		if ($test$plusargs("RESPONDER")) setup_responder;
		main_sequence;
	endtask

endclass : apb_virtual_seq

class apb_smoke_vseq extends apb_virtual_seq;
	`uvm_object_utils(apb_smoke_vseq)

	function new(string name = "apb_smoke_vseq");
		super.new(name);
	endfunction

	virtual task apb_write_rand;
		seq = apb_basic_seq::type_id::create("apb_write_rand");
		assert(seq.randomize() with { trtype == APB_WRITE; });
		seq.start( .sequencer( p_sequencer.apb1_seqr ) );
	endtask
	
	virtual task apb_read_rand;
		seq = apb_basic_seq::type_id::create("apb_read_rand");
		assert(seq.randomize() with { trtype == APB_READ; });
		seq.start( .sequencer( p_sequencer.apb1_seqr ) );
	endtask

	virtual task main_sequence;
		int i;
		
		i = p_sequencer.cfg.n_iter;
		repeat(i) begin
			randcase
	// weight : taskname
				100 : apb_write_rand;
				100 : apb_read_rand;
			endcase
		end
	endtask

endclass : apb_smoke_vseq

class apb_rw_range16_vseq extends apb_virtual_seq;
	`uvm_object_utils(apb_rw_range16_vseq)

	function new(string name = "apb_rw_range16_vseq");
		super.new(name);
	endfunction

	virtual task apb_write_range16;
		seq = apb_basic_seq::type_id::create("apb_write_range16");
		assert(seq.randomize() with {
				addr[11:4] == 0;
				trtype     == APB_WRITE; 
			});
		seq.start( .sequencer( p_sequencer.apb1_seqr ) );
	endtask

	virtual task apb_read_range16;
		seq = apb_basic_seq::type_id::create("apb_write_range16");
		assert(seq.randomize() with { 
				addr[11:4] == 0;
				trtype     == APB_READ; 
			});
		seq.start( .sequencer( p_sequencer.apb1_seqr ) );
	endtask

	virtual task main_sequence;
		int i;
		while (i < p_sequencer.cfg.n_iter) begin
			apb_write_range16;
			apb_read_range16;
			i+=2;
		end
	endtask

endclass : apb_rw_range16_vseq
`endif