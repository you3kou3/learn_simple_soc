// ============================================================================
// File    : learn_simple_soc.sv
// Author  : Tooru Kino
// Created : 2025-06-20
// License : Public Domain
//
// Top-level module for learn_simple_soc project
// Connects picorv32_axi CPU core with memory and LED control via AXI4-Lite interconnect
// 
// This software has been released into the public domain.
// ============================================================================

module learn_simple_soc (
   input  logic clk,
   input  logic resetn,
   output logic trap,
   output logic [31:0] leds
);

   // --------------------------------------------------
   // AXI4-Lite signals between picorv32_axi (master) 
   //        and interconnect (slave port 0)
   // --------------------------------------------------
   logic        m_axi_awvalid, m_axi_awready;
   logic [31:0] m_axi_awaddr;
   logic [2:0]  m_axi_awprot;

   logic        m_axi_wvalid, m_axi_wready;
   logic [31:0] m_axi_wdata;
   logic [3:0]  m_axi_wstrb;

   logic        m_axi_bvalid, m_axi_bready;

   logic        m_axi_arvalid, m_axi_arready;
   logic [31:0] m_axi_araddr;
   logic [2:0]  m_axi_arprot;

   logic        m_axi_rvalid, m_axi_rready;
   logic [31:0] m_axi_rdata;

   // --------------------------------------------------
   // AXI4-Lite signals from interconnect to slave 0 
   //     (axi_memory)
   // --------------------------------------------------
   logic        s0_axi_awvalid, s0_axi_awready;
   logic [31:0] s0_axi_awaddr;
   logic [2:0]  s0_axi_awprot;

   logic        s0_axi_wvalid, s0_axi_wready;
   logic [31:0] s0_axi_wdata;
   logic [3:0]  s0_axi_wstrb;

   logic        s0_axi_bvalid, s0_axi_bready;

   logic        s0_axi_arvalid, s0_axi_arready;
   logic [31:0] s0_axi_araddr;
   logic [2:0]  s0_axi_arprot;

   logic        s0_axi_rvalid, s0_axi_rready;
   logic [31:0] s0_axi_rdata;

   // --------------------------------------------------
   // AXI4-Lite signals from interconnect to slave 1 
   //   (led_control) 
   // --------------------------------------------------
   logic        s1_axi_awvalid, s1_axi_awready;
   logic [3:0]  s1_axi_awaddr;

   logic        s1_axi_wvalid, s1_axi_wready;
   logic [31:0] s1_axi_wdata;
   logic [3:0]  s1_axi_wstrb;

   logic        s1_axi_bvalid, s1_axi_bready;

   logic        s1_axi_arvalid, s1_axi_arready;
   logic [3:0]  s1_axi_araddr;

   logic        s1_axi_rvalid, s1_axi_rready;
   logic [31:0] s1_axi_rdata;
   logic [1:0]  s1_axi_rresp;

   // --------------------------------------------------
   // Instantiate picorv32_axi (master)
   // --------------------------------------------------
   picorv32_axi
      picorv32_axi_inst (
         .clk              (clk),
         .resetn           (resetn),

         // AXI master interface ----------------
         .mem_axi_awvalid  (m_axi_awvalid),
         .mem_axi_awready  (m_axi_awready),
         .mem_axi_awaddr   (m_axi_awaddr),
         .mem_axi_awprot   (m_axi_awprot),

         .mem_axi_wvalid   (m_axi_wvalid),
         .mem_axi_wready   (m_axi_wready),
         .mem_axi_wdata    (m_axi_wdata),
         .mem_axi_wstrb    (m_axi_wstrb),

         .mem_axi_bvalid   (m_axi_bvalid),
         .mem_axi_bready   (m_axi_bready),

         .mem_axi_arvalid  (m_axi_arvalid),
         .mem_axi_arready  (m_axi_arready),
         .mem_axi_araddr   (m_axi_araddr),
         .mem_axi_arprot   (m_axi_arprot),

         .mem_axi_rvalid   (m_axi_rvalid),
         .mem_axi_rready   (m_axi_rready),
         .mem_axi_rdata    (m_axi_rdata),

         // PCPI, IRQ, Trace ports --------------
         .pcpi_valid       (),
         .pcpi_insn        (),
         .pcpi_rs1         (),
         .pcpi_rs2         (),
         .pcpi_wr          (1'b0),
         .pcpi_rd          (32'b0),
         .pcpi_wait        (1'b0),
         .pcpi_ready       (1'b0),
         .irq              (32'b0),
         .eoi              (),
         .trace_valid      (),
         .trace_data       ()
      );

   // --------------------------------------------------
   // Instantiate axi_lite_interconnect with 2 slaves
   //   slaves0: memory (base address = 0x0000_0000)
   //   slaves1: led_control (base address = 0x1000_0000)
   // --------------------------------------------------
   axi_lite_interconnect #(
         .NUM_SLAVES(2),
         .ADDR_WIDTH(32),
         .SLAVE_ADDR_BASES({32'h1000_0000, 32'h0000_0000}), // Order: slave 1, slave 0 (MSB first)
         .SLAVE_ADDR_MASKS({32'hF000_0000, 32'hF000_0000})
      ) interconnect_inst (
         .clk              (clk),
         .resetn           (resetn),

         // Master AXI interface ---------------
         .m_axi_awvalid    (m_axi_awvalid),
         .m_axi_awready    (m_axi_awready),
         .m_axi_awaddr     (m_axi_awaddr),
         .m_axi_awprot     (m_axi_awprot),

         .m_axi_wvalid     (m_axi_wvalid),
         .m_axi_wready     (m_axi_wready),
         .m_axi_wdata      (m_axi_wdata),
         .m_axi_wstrb      (m_axi_wstrb),

         .m_axi_bvalid     (m_axi_bvalid),
         .m_axi_bready     (m_axi_bready),

         .m_axi_arvalid    (m_axi_arvalid),
         .m_axi_arready    (m_axi_arready),
         .m_axi_araddr     (m_axi_araddr),
         .m_axi_arprot     (m_axi_arprot),

         .m_axi_rvalid     (m_axi_rvalid),
         .m_axi_rready     (m_axi_rready),
         .m_axi_rdata      (m_axi_rdata),

         // Slave  interface (s1: led_control, s0:memory) -------------
         .s_axi_awvalid    ({s1_axi_awvalid, s0_axi_awvalid}),
         .s_axi_awready    ({s1_axi_awready, s0_axi_awready}),
         .s_axi_awaddr     ({s1_axi_awaddr, s0_axi_awaddr}),
         .s_axi_awprot     ({s1_axi_awprot, s0_axi_awprot}),

         .s_axi_wvalid     ({s1_axi_wvalid, s0_axi_wvalid}),
         .s_axi_wready     ({s1_axi_wready, s0_axi_wready}),
         .s_axi_wdata      ({s1_axi_wdata, s0_axi_wdata}),
         .s_axi_wstrb      ({s1_axi_wstrb, s0_axi_wstrb}),

         .s_axi_bvalid     ({s1_axi_bvalid, s0_axi_bvalid}),
         .s_axi_bready     ({s1_axi_bready, s0_axi_bready}),

         .s_axi_arvalid    ({s1_axi_arvalid, s0_axi_arvalid}),
         .s_axi_arready    ({s1_axi_arready, s0_axi_arready}),
         .s_axi_araddr     ({s1_axi_araddr, s0_axi_araddr}),
         .s_axi_arprot     ({s1_axi_arprot, s0_axi_arprot}),

         .s_axi_rvalid     ({s1_axi_rvalid, s0_axi_rvalid}),
         .s_axi_rready     ({s1_axi_rready, s0_axi_rready}),
         .s_axi_rdata      ({s1_axi_rdata, s0_axi_rdata})
      );

   // --------------------------------------------------
   // Instantiate axi_memory (slave 0)
   // --------------------------------------------------
   axi_memory #(
         .MEM_SIZE_BYTES(128*1024)
      ) memory_inst (
         .clk              (clk),
         .rstn             (resetn),

         .mem_axi_awvalid  (s0_axi_awvalid),
         .mem_axi_awready  (s0_axi_awready),
         .mem_axi_awaddr   (s0_axi_awaddr),
         .mem_axi_awprot   (s0_axi_awprot),

         .mem_axi_wvalid   (s0_axi_wvalid),
         .mem_axi_wready   (s0_axi_wready),
         .mem_axi_wdata    (s0_axi_wdata),
         .mem_axi_wstrb    (s0_axi_wstrb),

         .mem_axi_bvalid   (s0_axi_bvalid),
         .mem_axi_bready   (s0_axi_bready),

         .mem_axi_arvalid  (s0_axi_arvalid),
         .mem_axi_arready  (s0_axi_arready),
         .mem_axi_araddr   (s0_axi_araddr),
         .mem_axi_arprot   (s0_axi_arprot),

         .mem_axi_rvalid   (s0_axi_rvalid),
         .mem_axi_rready   (s0_axi_rready),
         .mem_axi_rdata    (s0_axi_rdata)
      );

   // --------------------------------------------------
   // Instantiate led_control (slave 1)
   // --------------------------------------------------
   led_control #(
         .ADDR_WIDTH(4)
      ) led_ctrl_inst (
         .clk(clk),
         .rstn(resetn),

         .s_axi_awvalid    (s1_axi_awvalid),
         .s_axi_awready    (s1_axi_awready),
         .s_axi_awaddr     (s1_axi_awaddr),

         .s_axi_wvalid     (s1_axi_wvalid),
         .s_axi_wready     (s1_axi_wready),
         .s_axi_wdata      (s1_axi_wdata),
         .s_axi_wstrb      (s1_axi_wstrb),

         .s_axi_bvalid     (s1_axi_bvalid),
         .s_axi_bready     (s1_axi_bready),

         .s_axi_arvalid    (s1_axi_arvalid),
         .s_axi_arready    (s1_axi_arready),
         .s_axi_araddr     (s1_axi_araddr),

         .s_axi_rvalid     (s1_axi_rvalid),
         .s_axi_rready     (s1_axi_rready),
         .s_axi_rdata      (s1_axi_rdata),
         .s_axi_rresp      (s1_axi_rresp),

         .leds             (leds)
      );

endmodule
