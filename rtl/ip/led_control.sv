// ============================================================================
// File    : led_control.sv
// Author  : Tooru Kino
// Created : 2025-06-22
// License : Public Domain
// ============================================================================

module led_control #(
   parameter ADDR_WIDTH = 4
)(
   input  logic                   clk,
   input  logic                   rstn,

   // AXI Lite Write Address Channel
   input  logic                   s_axi_awvalid,
   output logic                   s_axi_awready,
   input  logic [ADDR_WIDTH-1:0]  s_axi_awaddr,

   // AXI Lite Write Data Channel
   input  logic                   s_axi_wvalid,
   output logic                   s_axi_wready,
   input  logic [31:0]            s_axi_wdata,
   input  logic [3:0]             s_axi_wstrb,

   // AXI Lite Write Response Channel
   output logic                   s_axi_bvalid,
   input  logic                   s_axi_bready,

   // AXI Lite Read Address Channel
   input  logic                   s_axi_arvalid,
   output logic                   s_axi_arready,
   input  logic [ADDR_WIDTH-1:0]  s_axi_araddr,

   // AXI Lite Read Data Channel
   output logic                   s_axi_rvalid,
   input  logic                   s_axi_rready,
   output logic [31:0]            s_axi_rdata,
   output logic [1:0]             s_axi_rresp,

   // LED outputs
   output logic [31:0]            leds
);

   // Control registers
   logic [31:0] enable_reg;
   logic [31:0] led_reg;

   // Internal latched address for write/read
   logic [ADDR_WIDTH-1:0] latched_awaddr;
   logic [ADDR_WIDTH-1:0] latched_araddr;

   // AXI handshakes
   logic aw_handshake, w_handshake, b_handshake, ar_handshake, r_handshake;
   assign aw_handshake = s_axi_awready && s_axi_awvalid;
   assign w_handshake  = s_axi_wready  && s_axi_wvalid;
   assign b_handshake  = s_axi_bvalid  && s_axi_bready;
   assign ar_handshake = s_axi_arready && s_axi_arvalid;
   assign r_handshake  = s_axi_rvalid  && s_axi_rready;

   // AW channel
   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         s_axi_awready <= 1'b0;
      end else if (!s_axi_awready && s_axi_awvalid) begin
         s_axi_awready <= 1'b1;
         latched_awaddr <= s_axi_awaddr;
      end else if (b_handshake) begin
         s_axi_awready <= 1'b0;
      end
   end

   // W channel
   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         s_axi_wready <= 1'b0;
      end else if (!s_axi_wready && s_axi_wvalid) begin
         s_axi_wready <= 1'b1;
      end else if (b_handshake) begin
         s_axi_wready <= 1'b0;
      end
   end

   // B channel
   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         s_axi_bvalid <= 1'b0;
      end else if (aw_handshake && w_handshake && !s_axi_bvalid) begin
         s_axi_bvalid <= 1'b1;
      end else if (b_handshake) begin
         s_axi_bvalid <= 1'b0;
      end
   end

   // Write register
   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         enable_reg <= 32'd0;
         led_reg <= 32'd0;
      end else if (aw_handshake && w_handshake) begin
         case (latched_awaddr)
            4'h0: begin // enable register
               if (s_axi_wstrb[0]) enable_reg[7:0]   <= s_axi_wdata[7:0];
               if (s_axi_wstrb[1]) enable_reg[15:8]  <= s_axi_wdata[15:8];
               if (s_axi_wstrb[2]) enable_reg[23:16] <= s_axi_wdata[23:16];
               if (s_axi_wstrb[3]) enable_reg[31:24] <= s_axi_wdata[31:24];
            end
            4'h4: begin // LED register
               if (enable_reg[0]) begin // only writable if enabled
                  if (s_axi_wstrb[0]) led_reg[7:0]   <= s_axi_wdata[7:0];
                  if (s_axi_wstrb[1]) led_reg[15:8]  <= s_axi_wdata[15:8];
                  if (s_axi_wstrb[2]) led_reg[23:16] <= s_axi_wdata[23:16];
                  if (s_axi_wstrb[3]) led_reg[31:24] <= s_axi_wdata[31:24];
               end
            end
            default: ; // no operation
         endcase
      end
   end

   // AR channel
   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         s_axi_arready <= 1'b0;
      end else if (!s_axi_arready && s_axi_arvalid) begin
         s_axi_arready <= 1'b1;
         latched_araddr <= s_axi_araddr;
      end else if (r_handshake) begin
         s_axi_arready <= 1'b0;
      end
   end

   // R channel
   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         s_axi_rvalid <= 1'b0;
         s_axi_rdata  <= 32'd0;
         s_axi_rresp  <= 2'b00; // OKAY
      end else if (ar_handshake && !s_axi_rvalid) begin
         s_axi_rvalid <= 1'b1;
         unique case (latched_araddr)
            4'h0: s_axi_rdata <= enable_reg;
            4'h4: s_axi_rdata <= led_reg;
            default: s_axi_rdata <= 32'hDEAD_BEEF;
         endcase
         s_axi_rresp <= 2'b00;
      end else if (r_handshake) begin
         s_axi_rvalid <= 1'b0;
      end
   end

   // Output to LED
   assign leds = led_reg;

endmodule
