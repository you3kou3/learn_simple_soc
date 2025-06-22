// -----------------------------------------------------------------------------
// Module: axi_memory
// Description: AXI memory model RTL implementation
//
// This module is based on the simple AXI memory model from the PicoRV32 testbench project.
// Original source: https://github.com/cliffordwolf/picorv32
// Original author: Clifford Wolf
// License: Public domain
//
// Modified by: tooru.kino
// Date: 2025-06-22
// -----------------------------------------------------------------------------

module axi_memory #(
   parameter MEM_SIZE_BYTES = 128*1024
)(
   input  logic         clk,
   input  logic         rstn,

   // AXI Write Address Channel
   input  logic         mem_axi_awvalid,
   output logic         mem_axi_awready,
   input  logic [31:0]  mem_axi_awaddr,
   input  logic [2:0]   mem_axi_awprot,

   // AXI Write Data Channel
   input  logic         mem_axi_wvalid,
   output logic         mem_axi_wready,
   input  logic [31:0]  mem_axi_wdata,
   input  logic [3:0]   mem_axi_wstrb,

   // AXI Write Response Channel
   output logic         mem_axi_bvalid,
   input  logic         mem_axi_bready,

   // AXI Read Address Channel
   input  logic         mem_axi_arvalid,
   output logic         mem_axi_arready,
   input  logic [31:0]  mem_axi_araddr,
   input  logic [2:0]   mem_axi_arprot,

   // AXI Read Data Channel
   output logic         mem_axi_rvalid,
   input  logic         mem_axi_rready,
   output logic [31:0]  mem_axi_rdata
);

   // memory 
   logic [31:0] memory [0:(MEM_SIZE_BYTES/4)-1];

   initial begin
      $display("Loading memory from firmware.hex");
      $readmemh("firmware.hex", memory);
   end


   // logic declarations
   logic         latched_waddr_en, latched_wdata_en, latched_raddr_en;
   logic [31:0]  latched_waddr, latched_wdata, latched_raddr;
   logic [3:0]   latched_wstrb;
   logic         latched_rinsn;

   // AXI Write Address Channel
   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         mem_axi_awready <= 0;
         latched_waddr_en <= 0;
         latched_waddr <= 0;
      end else begin
         if (!mem_axi_awready && mem_axi_awvalid) begin
            mem_axi_awready <= 1;
            latched_waddr <= mem_axi_awaddr;
            latched_waddr_en <= 1;
         end else begin
            mem_axi_awready <= 0;
            if (mem_axi_bvalid && mem_axi_bready) begin
               latched_waddr_en <= 0;
            end
         end
      end
   end

   // AXI Write Data Channel
   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         mem_axi_wready <= 0;
         latched_wdata_en <= 0;
         latched_wdata <= 0;
         latched_wstrb <= 0;
      end else begin
         if (!mem_axi_wready && mem_axi_wvalid) begin
            mem_axi_wready <= 1;
            latched_wdata <= mem_axi_wdata;
            latched_wstrb <= mem_axi_wstrb;
            latched_wdata_en <= 1;
         end else begin
            mem_axi_wready <= 0;
            if (mem_axi_bvalid && mem_axi_bready) begin
               latched_wdata_en <= 0;
            end
         end
      end
   end

   // AXI Write Response Channel
   logic mem_axi_bvalid_reg;
   assign mem_axi_bvalid = mem_axi_bvalid_reg;

   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         mem_axi_bvalid_reg <= 0;
      end else begin
         if (latched_waddr_en && latched_wdata_en && !mem_axi_bvalid_reg) begin
            // write data
            if ((latched_waddr >> 2) < (MEM_SIZE_BYTES/4)) begin
               if (latched_wstrb[0]) memory[latched_waddr >> 2][ 7: 0] <= latched_wdata[ 7: 0];
               if (latched_wstrb[1]) memory[latched_waddr >> 2][15: 8] <= latched_wdata[15: 8];
               if (latched_wstrb[2]) memory[latched_waddr >> 2][23:16] <= latched_wdata[23:16];
               if (latched_wstrb[3]) memory[latched_waddr >> 2][31:24] <= latched_wdata[31:24];
            end
            mem_axi_bvalid_reg <= 1;
         end else if (mem_axi_bvalid_reg && mem_axi_bready) begin
            mem_axi_bvalid_reg <= 0;
         end
      end
   end

   // AXI Read Address Channel
   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         mem_axi_arready <= 0;
         latched_raddr_en <= 0;
         latched_raddr <= 0;
         latched_rinsn <= 0;
      end else begin
         if (!mem_axi_arready && mem_axi_arvalid) begin
            mem_axi_arready <= 1;
            latched_raddr <= mem_axi_araddr;
            latched_rinsn <= mem_axi_arprot[2];
            latched_raddr_en <= 1;
         end else begin
            mem_axi_arready <= 0;
            if (mem_axi_rvalid && mem_axi_rready) begin
               latched_raddr_en <= 0;
            end
         end
      end
   end

   // AXI Read Data Channel
   logic mem_axi_rvalid_reg;
   assign mem_axi_rvalid = mem_axi_rvalid_reg;

   always_ff @(posedge clk or negedge rstn) begin
      if (!rstn) begin
         mem_axi_rvalid_reg <= 0;
         mem_axi_rdata <= 0;
      end else begin
         if (latched_raddr_en && !mem_axi_rvalid_reg) begin
            mem_axi_rvalid_reg <= 1;
            if ((latched_raddr >> 2) < (MEM_SIZE_BYTES/4)) begin
               mem_axi_rdata <= memory[latched_raddr >> 2];
            end 
            else begin
               mem_axi_rdata <= 32'hDEAD_BEEF; // dummy data for accessing to out of range 
            end
         end else if (mem_axi_rvalid_reg && mem_axi_rready) begin
            mem_axi_rvalid_reg <= 0;
         end
      end
   end

endmodule
