`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Abdelrahman Khaled 
// 
// Create Date: 06/24/2025 10:15:25 PM
//////////////////////////////////////////////////////////////////////////////////


module spi_wrapper(
input            i_spi_wrapper_clk        ,
input            i_spi_wrapper_rst_n      ,
input      [9:0] i_spi_wrapper_data_in    ,
input            i_spi_wrapper_start      ,

output     [7:0] o_spi_wrapper_data_out   ,   
output           o_spi_wrapper_done       ,       
output           o_spi_wrapper_busy       
    );
    
wire        o_spi_master_sclk   ;
wire        mosi                ;
wire        ss_bar              ;
wire        miso                ;    
wire        miso_valid          ;    
wire        sready              ;
wire  [7:0] tx_data             ;   
wire        tx_valid            ; 
wire  [9:0] rx_data             ;  
wire        rx_valid            ;  


  
 //**********MASTER************//
  
spi_master u_spi_master (
  .i_spi_master_clk        (i_spi_wrapper_clk    ),
  .i_spi_master_rst_n      (i_spi_wrapper_rst_n  ),
  .i_spi_master_data_in    (i_spi_wrapper_data_in),
  .i_spi_master_start      (i_spi_wrapper_start  ),
  .i_spi_master_miso       (miso),       
  .i_spi_master_miso_valid (miso_valid ), 
  .i_spi_master_sready     (sready     ),     
  .o_spi_master_data_out   (o_spi_wrapper_data_out),   
  .o_spi_master_done       (o_spi_wrapper_done    ),       
  .o_spi_master_busy       (o_spi_wrapper_busy    ),       
  .o_spi_master_sclk       (o_spi_master_sclk),       
  .o_spi_master_mosi       (mosi),       
  .o_spi_master_ss_bar     (ss_bar)
       );



//***************SLAVE********************//
     
spi_slave u_spi_slave (
  .i_spi_slave_clk          (o_spi_master_sclk),   
  .i_spi_slave_rst_n        (i_spi_wrapper_rst_n),   
  .i_spi_slave_ss_bar       (ss_bar)             ,  
  .i_spi_slave_mosi         (mosi)               ,    
  .i_spi_slave_tx_data      (tx_data  )          , 
  .i_spi_slave_tx_valid     (tx_valid )          ,
  .o_spi_slave_rx_data      (rx_data  )          ,  
  .o_spi_slave_rx_valid     (rx_valid )          , 
  .o_spi_slave_miso         (miso)               ,     
  .o_spi_slave_miso_valid   (miso_valid)         ,
  .o_spi_slave_sready       (sready)    
       );       

RAM u_RAM(
  .i_RAM_clk                (o_spi_master_sclk),
  .i_RAM_rst_n              (i_spi_wrapper_rst_n),
  .i_RAM_en                 (rx_valid),
  .i_RAM_data_in            (rx_data),
  .o_RAM_data_out           (tx_data),
  .o_RAM_data_valid         (tx_valid)

    );
    
    
endmodule
