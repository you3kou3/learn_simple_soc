// ============================================================================
// File    : tb.sv
// Author  : Tooru Kino
// Created : 2025-06-22
// License : Public Domain
//
// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any means.
//
// Description:
//   Simple testbench to verify SoC with AXI memory preloaded from HEX file.
// ============================================================================

`timescale 1ns/1ps

module tb;

   logic clk = 0;
   logic rstn = 0;

   // Clock generation
   always #5 clk = ~clk;

   // Reset deassertion
   initial begin
      repeat (10) @(posedge clk);
      rstn = 1;
   end

   // Simulation timeout
   initial begin
      #100000;
      $display("TIMEOUT");
      $finish;
   end

   // DUT outputs
   wire trap;

   // Instantiate the top module (SoC)
   learn_simple_soc
      learn_simple_soc_inst (
         .clk     (clk),
         .resetn  (rstn),
         .trap    (trap),
         .leds    ()
   );

   // Trap detection
   initial begin
      wait (rstn && trap);
      $display("TRAP detected, test done.");
      $finish;
   end

endmodule
