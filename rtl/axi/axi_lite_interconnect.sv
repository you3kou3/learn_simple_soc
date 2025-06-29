// ============================================================================
// File    : axi_lite_interconnect.sv
// Author  : Tooru Kino
// Created : 2025-06-22
// License : Public Domain
// ============================================================================

module axi_lite_interconnect #(
   parameter integer NUM_SLAVES = 2,
   parameter integer ADDR_WIDTH = 32,
   parameter [NUM_SLAVES*ADDR_WIDTH-1:0] SLAVE_ADDR_BASES = {32'h1000_0000, 32'h0000_0000}, // MSB first
   parameter [NUM_SLAVES*ADDR_WIDTH-1:0] SLAVE_ADDR_MASKS = {32'hF000_0000, 32'hF000_0000}  // MSB first
)(
   input  wire                  clk,
   input  wire                  resetn,

   // Master Interface 
   input  wire                  m_axi_awvalid,
   output wire                  m_axi_awready,
   input  wire [ADDR_WIDTH-1:0] m_axi_awaddr,
   input  wire [2:0]            m_axi_awprot,

   input  wire                  m_axi_wvalid,
   output wire                  m_axi_wready,
   input  wire [31:0]           m_axi_wdata,
   input  wire [3:0]            m_axi_wstrb,

   output wire                  m_axi_bvalid,
   input  wire                  m_axi_bready,

   input  wire                  m_axi_arvalid,
   output wire                  m_axi_arready,
   input  wire [ADDR_WIDTH-1:0] m_axi_araddr,
   input  wire [2:0]            m_axi_arprot,

   output wire                  m_axi_rvalid,
   input  wire                  m_axi_rready,
   output wire [31:0]           m_axi_rdata,
   output wire [1:0]            m_axi_rresp,

   // Slave Interfaces (x NUM_SLAVES)
   output wire [NUM_SLAVES-1:0] s_axi_awvalid,
   input  wire [NUM_SLAVES-1:0] s_axi_awready,
   output wire [NUM_SLAVES*ADDR_WIDTH-1:0] s_axi_awaddr,
   output wire [NUM_SLAVES*3-1:0] s_axi_awprot,

   output wire [NUM_SLAVES-1:0] s_axi_wvalid,
   input  wire [NUM_SLAVES-1:0] s_axi_wready,
   output wire [NUM_SLAVES*32-1:0] s_axi_wdata,
   output wire [NUM_SLAVES*4-1:0] s_axi_wstrb,

   input  wire [NUM_SLAVES-1:0] s_axi_bvalid,
   output wire [NUM_SLAVES-1:0] s_axi_bready,

   output wire [NUM_SLAVES-1:0] s_axi_arvalid,
   input  wire [NUM_SLAVES-1:0] s_axi_arready,
   output wire [NUM_SLAVES*ADDR_WIDTH-1:0] s_axi_araddr,
   output wire [NUM_SLAVES*3-1:0] s_axi_arprot,

   input  wire [NUM_SLAVES-1:0] s_axi_rvalid,
   output wire [NUM_SLAVES-1:0] s_axi_rready,
   input  wire [NUM_SLAVES*32-1:0] s_axi_rdata,
   input  wire [NUM_SLAVES*2-1:0]  s_axi_rresp
);

   // --------------------------------------------------
   // Address Decoder Logic (AW and AR channels) using SLAVE_ADDR_BASES and SLAVE_ADDR_MASKS
   // --------------------------------------------------
   function automatic int decode_slave(input logic [ADDR_WIDTH-1:0] addr);
      int i;
      logic match;
      logic [ADDR_WIDTH-1:0] base;
      logic [ADDR_WIDTH-1:0] mask;
      begin
         decode_slave = 0; // default slave 0
         for (i = 0; i < NUM_SLAVES; i++) begin
            base = SLAVE_ADDR_BASES >> ((NUM_SLAVES-1 - i)*ADDR_WIDTH);
            mask = SLAVE_ADDR_MASKS >> ((NUM_SLAVES-1 - i)*ADDR_WIDTH);
            if ((addr & mask) == (base & mask)) begin
               decode_slave = i;
               break;
            end
         end
      end
   endfunction

   logic [$clog2(NUM_SLAVES)-1:0] selected_slave_aw;
   logic [$clog2(NUM_SLAVES)-1:0] selected_slave_ar;

   always_comb begin
      selected_slave_aw = decode_slave(m_axi_awaddr);
      selected_slave_ar = decode_slave(m_axi_araddr);
   end

   // --------------------------------------------------
   // AW channel routing
   // --------------------------------------------------
   genvar i;
   generate
      for (i=0; i<NUM_SLAVES; i=i+1) begin : AW_ROUTING
         assign s_axi_awvalid[i] = (i == selected_slave_aw) ? m_axi_awvalid : 1'b0;
         assign s_axi_awaddr[(i+1)*ADDR_WIDTH-1 -: ADDR_WIDTH] = (i == selected_slave_aw) ? m_axi_awaddr : {ADDR_WIDTH{1'b0}};
         assign s_axi_awprot[(i+1)*3-1 -: 3] = (i == selected_slave_aw) ? m_axi_awprot : 3'b000;
      end
   endgenerate

   assign m_axi_awready = s_axi_awready[selected_slave_aw];

   // --------------------------------------------------
   // Write Data Channel routing
   // --------------------------------------------------
   logic [$clog2(NUM_SLAVES)-1:0] r_selected_slave;
   logic r_active;

   always_ff @(posedge clk or negedge resetn) begin
      if (!resetn) begin
         r_selected_slave <= 0;
         r_active <= 1'b0;
      end else begin
         if (m_axi_awvalid && m_axi_awready) begin
            r_selected_slave <= selected_slave_aw;
            r_active <= 1'b1;
         end else if (m_axi_wvalid && m_axi_wready) begin
            r_active <= 1'b0;
         end
      end
   end

   generate
      for (i=0; i<NUM_SLAVES; i=i+1) begin : W_ROUTING
         assign s_axi_wvalid[i] = (r_active && (i == r_selected_slave)) ? m_axi_wvalid : 1'b0;
         assign s_axi_wdata[(i+1)*32-1 -: 32] = (r_active && (i == r_selected_slave)) ? m_axi_wdata : 32'b0;
         assign s_axi_wstrb[(i+1)*4-1 -: 4] = (r_active && (i == r_selected_slave)) ? m_axi_wstrb : 4'b0;
      end
   endgenerate

   assign m_axi_wready = s_axi_wready[r_selected_slave];

   // --------------------------------------------------
   // Write Response channel routing
   // --------------------------------------------------
   generate
      for (i=0; i<NUM_SLAVES; i=i+1) begin : B_ROUTING
         assign s_axi_bready[i] = (i == r_selected_slave) ? m_axi_bready : 1'b0;
      end
   endgenerate

   assign m_axi_bvalid = s_axi_bvalid[r_selected_slave];

   // --------------------------------------------------
   // AR channel routing
   // --------------------------------------------------
   generate
      for (i=0; i<NUM_SLAVES; i=i+1) begin : AR_ROUTING
         assign s_axi_arvalid[i] = (i == selected_slave_ar) ? m_axi_arvalid : 1'b0;
         assign s_axi_araddr[(i+1)*ADDR_WIDTH-1 -: ADDR_WIDTH] = (i == selected_slave_ar) ? m_axi_araddr : {ADDR_WIDTH{1'b0}};
         assign s_axi_arprot[(i+1)*3-1 -: 3] = (i == selected_slave_ar) ? m_axi_arprot : 3'b000;
      end
   endgenerate

   assign m_axi_arready = s_axi_arready[selected_slave_ar];

   // --------------------------------------------------
   // Read Data Channel routing
   // --------------------------------------------------
   generate
      for (i=0; i<NUM_SLAVES; i=i+1) begin : R_ROUTING
         assign s_axi_rready[i] = (i == selected_slave_ar) ? m_axi_rready : 1'b0;
      end
   endgenerate

   assign m_axi_rvalid = s_axi_rvalid[selected_slave_ar];
   assign m_axi_rdata  = s_axi_rdata[(selected_slave_ar+1)*32-1 -: 32];
   assign m_axi_rresp  = s_axi_rresp[(selected_slave_ar+1)*2-1 -: 2];

endmodule
