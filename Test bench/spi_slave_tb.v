`timescale 1ns / 1ps

module spi_slave_tb;

    // Testbench signals
 
 reg      i_spi_slave_clk;
 reg      i_spi_slave_rst_n;                              
 reg      i_spi_slave_ss_bar;  
 reg      i_spi_slave_mosi;                          
 reg [7:0]i_spi_slave_tx_data;
 reg      i_spi_slave_tx_valid;                          
 
 wire [9:0] o_spi_slave_rx_data;
 wire      o_spi_slave_rx_valid;
 wire      o_spi_slave_miso;
 wire      o_spi_slave_miso_valid;
 wire      o_spi_slave_sready;
 
 spi_slave u_spi_slave (
 .i_spi_slave_clk       (i_spi_slave_clk       ),    
 .i_spi_slave_rst_n     (i_spi_slave_rst_n     ),  
 .i_spi_slave_ss_bar    (i_spi_slave_ss_bar    ), 
 .i_spi_slave_mosi      (i_spi_slave_mosi      ),   
 .i_spi_slave_tx_data   (i_spi_slave_tx_data   ), 
 .i_spi_slave_tx_valid  (i_spi_slave_tx_valid  ),
 .o_spi_slave_rx_data   (o_spi_slave_rx_data   ),  
 .o_spi_slave_rx_valid  (o_spi_slave_rx_valid  ), 
 .o_spi_slave_miso      (o_spi_slave_miso      ),     
 .o_spi_slave_miso_valid(o_spi_slave_miso_valid),
 .o_spi_slave_sready    (o_spi_slave_sready    )    
);


    // SPI clock: period 1 ns (1000 MHz), toggle every 10 ns
    initial begin
        i_spi_slave_clk = 0;
        forever #0.5 i_spi_slave_clk = ~i_spi_slave_clk;
    end
 // SPI bit transmission task (LSB first)
       task spi_send_10bit(input [9:0] data);
           integer i;
           begin
               for (i = 9; i >= 0; i = i - 1) begin
                   i_spi_slave_mosi = data[i];
                   #1; // Wait one clock period
               end
           end
       endtask
   
       // Stimulus
       initial begin
          $dumpfile("spi_slave_tb.vcd");
          $dumpvars(0, spi_slave_tb);
           // Initialize
           i_spi_slave_rst_n    = 0;
           i_spi_slave_ss_bar   = 1;
           i_spi_slave_mosi     = 0;
           i_spi_slave_tx_data  = 8'b10101010;
           i_spi_slave_tx_valid = 1;
   
           // Wait a few cycles
           #5;
           i_spi_slave_rst_n = 1;
   
           // Wait for slave to be ready
           wait(o_spi_slave_sready == 1);
   
           // Test WRITE operation (MOSI starts with 0 as command)
           //@(negedge i_spi_slave_clk);
           @(posedge i_spi_slave_clk);
           i_spi_slave_ss_bar = 0;  // Enable slave select
           
           //@(negedge i_spi_slave_clk);
           @(posedge i_spi_slave_clk);
           spi_send_10bit(10'b0110101101); // Example write data
   
           @(posedge i_spi_slave_clk);
           i_spi_slave_ss_bar = 1;  // Disable slave select
   
           #10;
  ////////////////////////////////////////////////////////////////////////////////////
           
           @(posedge i_spi_slave_clk);
           i_spi_slave_ss_bar = 0;  // Enable slave select
           
           //@(negedge i_spi_slave_clk);
           @(posedge i_spi_slave_clk);
           spi_send_10bit(10'b0011111111); // Example write data
           i_spi_slave_mosi = 1'b0;
           @(posedge i_spi_slave_clk);
           i_spi_slave_ss_bar = 1;  // Disable slave select
           
           #10;  
  
   //////////////////////////////////////////////////////////////////////////////
           // Test READ_ADDR (MOSI starts with 1 as command)
           @(posedge i_spi_slave_clk);
           i_spi_slave_ss_bar = 0;  // Enable slave again
           @(posedge i_spi_slave_clk);
           spi_send_10bit(10'b1000000011); // Example read address
   
           @(posedge i_spi_slave_clk);
           i_spi_slave_ss_bar = 1;
   
           #10;
  ////////////////////////////////////////////////////////////////////////////////
   
           // Test READ_DATA
           i_spi_slave_tx_data = 8'b11001100;  // Slave will output this
           i_spi_slave_tx_valid = 1;
   
           @(posedge i_spi_slave_clk);
           i_spi_slave_ss_bar = 0;
   
           repeat (9) begin
               @(posedge i_spi_slave_clk);
           end
   
           @(posedge i_spi_slave_clk);
           i_spi_slave_ss_bar = 1;
   
           // Finish after some delay
           #20;
           $finish;
       end
    

endmodule
