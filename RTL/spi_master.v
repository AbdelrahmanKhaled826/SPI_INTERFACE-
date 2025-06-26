`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Abdelrahman Khaled
// 
// Create Date: 06/22/2025 05:06:15 AM
// Module Name: spi_master
//////////////////////////////////////////////////////////////////////////////////

module spi_master (
input            i_spi_master_clk,
input            i_spi_master_rst_n,
input      [9:0] i_spi_master_data_in,
input            i_spi_master_start,

input            i_spi_master_miso,       //master input slave output come from slave module
input            i_spi_master_miso_valid, //indicate that data valid and come from slave module
input            i_spi_master_sready,     //indicate that slave ready to receive data and come from slave


output reg [7:0] o_spi_master_data_out,   // to user
output reg       o_spi_master_done,       //if operation is complete 
output reg       o_spi_master_busy,       //if master send data to slave 

output           o_spi_master_sclk,       //send to slave 
output reg       o_spi_master_mosi,       //send to slave
output reg       o_spi_master_ss_bar
	);

parameter IDLE        = 3'b000 ,
          WAIT_SREADY = 3'b001 , 
          ASSERT_SS   = 3'b010 ,
          SEND_MOSI   = 3'b011 ,
          RECV_MISO   = 3'b100 ,
          END         = 3'b101 ;

reg [2:0] curr_state  ;
reg [2:0] nxt_state   ;
reg [9:0] mosi_reg    ;
reg [7:0] miso_reg    ;
reg [4:0] counter     ;
reg       start_shift1 ;
reg       start_shift2 ;
reg       send_clk;
reg       rst_counter ;
wire      start_edge  ;



//edge detector for start
always @(posedge i_spi_master_clk or negedge i_spi_master_rst_n) begin
	if (!i_spi_master_rst_n) begin
		start_shift1 <= 1'b0;
		start_shift2 <= 1'b0;
	end
	else begin
	     start_shift1 <= i_spi_master_start ;
	     start_shift2 <= start_shift1;
	end
end



assign  start_edge       =  i_spi_master_start & ~start_shift2 ;

assign o_spi_master_sclk = (send_clk)? i_spi_master_clk : 1'b0 ; 


//fsm registers
always @(posedge i_spi_master_clk or negedge i_spi_master_rst_n)
begin
	if(!i_spi_master_rst_n)
	begin
		curr_state <= IDLE    ;
	end
	else begin
		curr_state <= nxt_state;
	end

end

//fsm next state
always @(*) 
begin
    nxt_state = curr_state ;
    case(curr_state)
      IDLE: begin
        if(start_edge) begin
            nxt_state = WAIT_SREADY;
        end
        else begin
            nxt_state = IDLE ;   	
        end
      end 

      WAIT_SREADY: begin
        if(i_spi_master_sready) begin
            nxt_state = ASSERT_SS;
        end
        else begin
            nxt_state = WAIT_SREADY;   	
        end
      end 

      ASSERT_SS: begin
        nxt_state   = SEND_MOSI	;         
      end 

      SEND_MOSI: begin 
        if (counter=='d3 && i_spi_master_data_in[9:8] ==2'b11) begin
            nxt_state   = RECV_MISO ;
            rst_counter =1'b1;
            
        end
        else if(counter<'d10) begin
            nxt_state = SEND_MOSI ;
        end
        else begin
            nxt_state = END ; 
        end
             	
      end 

      RECV_MISO: begin
        if(counter=='d7 && i_spi_master_miso_valid) begin
           nxt_state = END ;  
        end
        else begin
            nxt_state = RECV_MISO ;
         end 
      end

      END: begin
        nxt_state = IDLE ;
      end

      default : begin
        nxt_state = IDLE ;          
      end
    endcase
end


//outputs and registers update

always @(posedge i_spi_master_clk or negedge i_spi_master_rst_n) begin
	if (!i_spi_master_rst_n) begin
	      	o_spi_master_data_out <= 'b0;
 			o_spi_master_done     <= 'b0; 			
 			o_spi_master_busy     <= 'b0;
 			o_spi_master_mosi     <= 'b0;
 			o_spi_master_ss_bar   <= 'b1;
 			mosi_reg              <= 'b0;
 			counter               <= 'b0;
 			miso_reg              <= 'b0;
 			send_clk              <= 'b0;
 			rst_counter           <= 'b0;
		
	end
	else begin
	     case(curr_state)
	     IDLE: begin
	       o_spi_master_ss_bar <= 'b1;
	       o_spi_master_busy   <= 'b0;
	       o_spi_master_done   <= 1'b0;
	       if(start_edge) begin
	           mosi_reg            <= i_spi_master_data_in ;
	       end
	       else begin
	           mosi_reg            <= mosi_reg ;
	       end       
	     end

	     WAIT_SREADY: begin
	        o_spi_master_busy   <= 'b1;
	     end
	     
	     ASSERT_SS: begin
	     	o_spi_master_ss_bar <= 'b0;
	     	send_clk <= 1'b1;
	     end
	     SEND_MOSI: begin
	     	o_spi_master_mosi <= mosi_reg[9];
	     	mosi_reg   <= mosi_reg << 1;
	     	if (counter != 10) begin
	     	    counter <= counter + 1'b1;	     		
	     	end
	     	else begin
	     		counter <= 'b0;
	     		o_spi_master_ss_bar <= 'b1;
	     	end

	     end 
	     RECV_MISO: begin
	     	o_spi_master_ss_bar <= 'b0;
	     	if (counter != 7) begin
	     	    if(rst_counter) begin
	     	     counter <='b0;
                end
                else begin 
	     		counter <= counter +1'b1;
	     		miso_reg <= {miso_reg[6:0],i_spi_master_miso} ;
	     		end
	     		rst_counter<=1'b0;
	     	end
	     	else begin
	     		o_spi_master_data_out <= {miso_reg[6:0],i_spi_master_miso};
	     		o_spi_master_ss_bar <= 'b1;
	     	end
	     end

	     END: begin
	     	o_spi_master_busy   <= 1'b0 ;
	     	o_spi_master_done   <= 1'b1 ;
	     	o_spi_master_ss_bar <= 1'b1 ;
	     	send_clk            <= 1'b1 ;
	     	counter             <= 'b0  ;
	     end

	     endcase
	end
end









endmodule