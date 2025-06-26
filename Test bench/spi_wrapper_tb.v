`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Abdelrhman Khaled
//////////////////////////////////////////////////////////////////////////////////


module spi_wrapper_tb();

  // Wrapper interface signals
    reg         i_spi_wrapper_clk;
    reg         i_spi_wrapper_rst_n;
    reg  [9:0]  i_spi_wrapper_data_in;
    reg         i_spi_wrapper_start;

    wire [7:0]  o_spi_wrapper_data_out;
    wire        o_spi_wrapper_done;
    wire        o_spi_wrapper_busy;

    // Instantiate the wrapper
    spi_wrapper uut (
        .i_spi_wrapper_clk      (i_spi_wrapper_clk),
        .i_spi_wrapper_rst_n    (i_spi_wrapper_rst_n),
        .i_spi_wrapper_data_in  (i_spi_wrapper_data_in),
        .i_spi_wrapper_start    (i_spi_wrapper_start),
        .o_spi_wrapper_data_out (o_spi_wrapper_data_out),
        .o_spi_wrapper_done     (o_spi_wrapper_done),
        .o_spi_wrapper_busy     (o_spi_wrapper_busy)
    );


reg [7:0] expected_read;
reg [7:0] actual_read;
reg [7:0] addr_list [0:3];
reg [7:0] data_list [0:3];

integer   i;

  // Clock generation: 1 ns period (1000 MHz)
    initial begin
        i_spi_wrapper_clk = 0;
        forever #0.5 i_spi_wrapper_clk = ~i_spi_wrapper_clk;
    end
   
   // Task: perform one wrapper transaction
   // Input: 10-bit word (command+data)
   // Output: 8-bit read_data (only meaningful if command==2'b11)
   task automatic wrapper_transaction(
         input  [9:0] cmd_word,
         output [7:0] read_data
        );
         begin
         // Wait until not busy
             wait (!o_spi_wrapper_busy);
             // Apply command on next rising edge
             @(posedge i_spi_wrapper_clk);
             i_spi_wrapper_data_in <= cmd_word;
             i_spi_wrapper_start   <= 1'b1;
             @(posedge i_spi_wrapper_clk);
             i_spi_wrapper_start   <= 1'b0;
             // Wait until done
             wait (o_spi_wrapper_done);
             // Capture output
             read_data = o_spi_wrapper_data_out;
             // Wait one more cycle for done to deassert
             @(posedge i_spi_wrapper_clk);
          end
   endtask


// Test sequence   
   initial
   begin  
   
         $dumpfile("spi_wrapper_tb.vcd");
         $dumpvars(0,spi_wrapper_tb);
    
         // Initialize
         i_spi_wrapper_rst_n   = 1'b0;
         i_spi_wrapper_data_in = 10'd0;
         i_spi_wrapper_start   = 1'b0;
        
         // Apply reset
         repeat (2) @(posedge i_spi_wrapper_clk);
         i_spi_wrapper_rst_n = 1'b1;
         
         @(posedge i_spi_wrapper_clk);
         $display("Starting SPI wrapper tests...");
        
         // Define some address/data pairs to test         
         addr_list[0] = 8'h10; 
         addr_list[1] = 8'h20; 
         addr_list[2] = 8'h30; 
         addr_list[3] = 8'h40; 
          
         data_list[0] = 8'hAA; 
         data_list[1] = 8'h55; 
         data_list[2] = 8'hFF; 
         data_list[3] = 8'h00; 
         
         // Loop over cases
         for (i = 0; i < 4; i = i + 1) begin
              // 1) Write Address
              $display("\nCase %0d: Write address 0x%02h", i, addr_list[i]);
              wrapper_transaction({2'b00, addr_list[i]}, actual_read);
              // For write-address, data_out may be don't-care. We just check done.
              if (!o_spi_wrapper_done) begin
                  $error("Write-Address: done not asserted");
              end else begin
                  $display("  Write-Address done");
              end
          
              // 2) Write Data
              $display("Case %0d: Write data 0x%02h", i, data_list[i]);
              wrapper_transaction({2'b01, data_list[i]}, actual_read);
              if (!o_spi_wrapper_done) begin
                  $error("Write-Data: done not asserted");
              end else begin
                  $display("  Write-Data done");
              end
          
               // 3) Read Address
               $display("Case %0d: Read address 0x%02h", i, addr_list[i]);
               wrapper_transaction({2'b10, addr_list[i]}, actual_read);
               if (!o_spi_wrapper_done) begin
                   $error("Read-Address: done not asserted");
               end else begin
                   $display("  Read-Address done");
               end
          
                // 4) Read Data
                expected_read = data_list[i];
                $display("Case %0d: Read-Data, expecting 0x%02h", i, expected_read);
                wrapper_transaction({2'b11, 8'h00}, actual_read);
                if (!o_spi_wrapper_done) begin
                    $error("Read-Data: done not asserted");
                end
                else if (actual_read !== expected_read) begin
                    $error("Read-Data MISMATCH: got 0x%02h, expected 0x%02h", actual_read, expected_read);
                end else begin
                    $display("  Read-Data PASS: got 0x%02h", actual_read);
                end
                  end
          
                  $display("\nAll cases completed.");
                  $finish;
              end
   
   


endmodule
