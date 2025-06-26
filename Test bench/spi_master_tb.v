`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/22/2025 05:39:22 AM
// Module Name: spi_master_tb
//////////////////////////////////////////////////////////////////////////////////


module spi_master_tb;


reg           i_spi_master_clk;        
reg           i_spi_master_rst_n;      
reg     [9:0] i_spi_master_data_in;      
reg           i_spi_master_start;        
reg           i_spi_master_miso;   
reg           i_spi_master_miso_valid;   
reg           i_spi_master_sready;    
 
wire [7:0] o_spi_master_data_out;     
wire       o_spi_master_done;         
wire       o_spi_master_busy;         
wire       o_spi_master_sclk;         
wire       o_spi_master_mosi;        
wire       o_spi_master_ss_bar;        

spi_master u_spi_master (
.i_spi_master_clk(i_spi_master_clk),
.i_spi_master_rst_n(i_spi_master_rst_n),
.i_spi_master_data_in(i_spi_master_data_in),
.i_spi_master_start(i_spi_master_start),
.i_spi_master_miso(i_spi_master_miso),     
.i_spi_master_miso_valid(i_spi_master_miso_valid), 
.i_spi_master_sready(i_spi_master_sready),     
.o_spi_master_data_out(o_spi_master_data_out),   
.o_spi_master_done(o_spi_master_done),        
.o_spi_master_busy(o_spi_master_busy),       
.o_spi_master_sclk(o_spi_master_sclk),        
.o_spi_master_mosi(o_spi_master_mosi),       
.o_spi_master_ss_bar(o_spi_master_ss_bar)
	);

reg [7:0] resp_pattern;
integer i;

always #0.5 i_spi_master_clk = ~ i_spi_master_clk;

initial 
begin
 // Dump waveforms for inspection
$dumpfile("spi_master_tb.vcd");
$dumpvars(0, spi_master_tb);
i_spi_master_clk        = 1'b0;
i_spi_master_rst_n      =1'b1;
i_spi_master_data_in    ='b0;
i_spi_master_start      ='b0;
i_spi_master_miso       ='d22;
i_spi_master_miso_valid ='b0;
i_spi_master_sready     =1'b0;

#0.5
i_spi_master_rst_n      =1'b0;
#0.5
i_spi_master_rst_n      =1'b1;
i_spi_master_sready     =1'b1;

#20;

i_spi_master_data_in = 10'b01_10101010; // arbitrary 10-bit pattern
    @(posedge i_spi_master_clk);    
    // pulse start
    i_spi_master_start = 1;
    #8;
    @(posedge i_spi_master_clk);
    i_spi_master_start = 0;
// wait untal done pulse
    wait(o_spi_master_done == 1);
    $display("[%0t] TEST1: DONE asserted. data_out = 0x%0h, busy=%b", $time, o_spi_master_data_out, o_spi_master_busy);
    // Expect: since header!=11, FSM should skip receive; data_out likely remains 0 (or reset value).   
 #50;   
 
  // ------------- Test 2: header == 2'b11, expect receive -------------
 // Prepare a 10-bit command with top bits = 2'b11
 // Lower bits can be zero or any value; here we use zeros.
   i_spi_master_data_in = 10'b11_11000001;
          @(posedge i_spi_master_clk);
          // pulse start
          i_spi_master_start = 1;
          @(posedge i_spi_master_clk);
          i_spi_master_start = 0;
 
    // Now the FSM should go: IDLE->WAIT_SREADY->ASSERT_SS->SEND_MOSI (10 cycles)
    // Then since header==11, it will go to RECV_MISO.
    // We need to drive i_spi_master_miso and i_spi_master_miso_valid during that receive window.
    // Because the design ties sclk to clk, SEND_MOSI will consume ~10 clock cycles after ASSERT_SS.
    // We wait some cycles to align roughly with the start of RECV_MISO. Adjust as needed if your simulation shows different timing.
    // Here we wait 15 cycles after the start pulse to enter the receive phase.
    repeat (14) @(posedge i_spi_master_clk);
     // Now drive a sample 8-bit response, say 8'hA5 = 1010_0101.
     // We assert miso_valid during the receive. In the code, FSM waits for miso_valid when counter==7.
   // To be safe, keep miso_valid high across all 8 bits.
        i_spi_master_miso_valid = 1;
        resp_pattern = 8'hA5;

       
       
        for (i = 7; i >= 0; i = i - 1) begin
          i_spi_master_miso = resp_pattern[i];
          @(posedge i_spi_master_clk);
        end

   // After sending 8 bits, deassert miso_valid
    i_spi_master_miso_valid = 0;
    i_spi_master_miso = 0;

    // Wait for done
    wait(o_spi_master_done == 1);
    $display("[%0t] TEST2: DONE asserted. data_out = 0x%0h, busy=%b", $time, o_spi_master_data_out, o_spi_master_busy);
    // Depending on the internal shifting order, data_out may or may not equal 8'hA5.
    // Inspect waveforms to see how bits were captured.
#50;
$finish;
end

endmodule
