`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Abdelrahman Khaled

//256-byte memory array Address register for operation sequencing Data output register with valid signal
//////////////////////////////////////////////////////////////////////////////////


module RAM(
input            i_RAM_clk,
input            i_RAM_rst_n,
input            i_RAM_en,
input      [9:0] i_RAM_data_in,

output reg [7:0] o_RAM_data_out,
output reg       o_RAM_data_valid

    );
 (* ram_style = "block" *)    
 reg [7:0] spi_mem [0:255];
 reg [7:0] read_add;
 reg [7:0] write_add;
 integer   i;

 always @(posedge i_RAM_clk or negedge i_RAM_rst_n)
 begin
     if(!i_RAM_rst_n)
     begin
         for (i=0 ; i< 256 ; i=i+1)
         begin
             spi_mem[i] <= 8'b0;     
         end
         write_add        <= 8'b0; 
         read_add         <= 8'b0; 
         o_RAM_data_out   <= 8'b0; 
         o_RAM_data_valid <= 1'b0; 
     end     
     else if(i_RAM_en)
     begin
         case (i_RAM_data_in[9:8]) //hold write address
         2'b00: begin //hold write address
                    write_add        <= i_RAM_data_in[7:0];
                    o_RAM_data_valid <= 1'b0;
                end
         2'b01: begin //write data in address
                     spi_mem[write_add]<= i_RAM_data_in[7:0];
                     o_RAM_data_valid  <= 1'b0;
                end
         2'b10: begin //hold read address
                     read_add         <= i_RAM_data_in[7:0];
                     o_RAM_data_valid <= 1'b0;
                end                       
         2'b11: begin //read data
                    o_RAM_data_out   <=spi_mem[read_add];
                    o_RAM_data_valid <= 1'b1;
                end
         endcase         
     end
     else
     begin
         o_RAM_data_out   <= 8'b0;
         o_RAM_data_valid <= 1'b0; 
     end     
 end
    


endmodule
