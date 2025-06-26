`timescale 1ns / 1ps
// SPI Slave Module with inline comments explaining each section and highlighting issues

module spi_slave (
    input            i_spi_slave_clk,    // SPI clock input
    input            i_spi_slave_rst_n,  // Active-low reset

    input            i_spi_slave_ss_bar, // Active-low Slave Select
    input            i_spi_slave_mosi,   // Master Out, Slave In

    input      [7:0] i_spi_slave_tx_data, // Data to shift out in READ_DATA (external)
    input            i_spi_slave_tx_valid,// Indicates tx_data is valid

    output reg [9:0] o_spi_slave_rx_data,  // Captured 10-bit word from MOSI
    output reg       o_spi_slave_rx_valid, // Pulses when rx_data is valid
    output reg       o_spi_slave_miso,     // Slave Out, Master In
    output reg       o_spi_slave_miso_valid,// High while shifting out data
    output wire      o_spi_slave_sready    // Indicates slave ready for new transaction
);

// State encoding: one-hot with 5 bits. Must match reg width [4:0].
parameter IDLE      = 5'b00001,
          CHK_CMD   = 5'b00010,
          WRITE     = 5'b00100,
          READ_ADDR = 5'b01000,
          READ_DATA = 5'b10000;

(* fsm_encoding = "one_hot" *)
reg [4:0] curr_state;
reg [4:0] nxt_state;

reg [9:0] mosi_shift_reg; // Shift register for incoming bits
reg [3:0] counter;        // Counter for bit shifting; must count up to 9 or 10 depending

reg       addr_stored;    // Flag: high if address was stored for a READ; logic for this is flawed in original
reg       shift_read;     // Flag: indicates read shifting is in progress

// FSM state register
always @(posedge i_spi_slave_clk or negedge i_spi_slave_rst_n) begin
    if (!i_spi_slave_rst_n) begin
        curr_state <= IDLE;
    end else begin
        curr_state <= nxt_state;
    end
end

// FSM next-state logic
always @(*) begin
    nxt_state = curr_state;
    case (curr_state)
        IDLE: begin
            // In IDLE, when SS_bar is high, remain IDLE; when SS_bar goes low, move to CHK_CMD
            if (i_spi_slave_ss_bar) begin
                nxt_state = IDLE;
            end else begin
                nxt_state = CHK_CMD;
            end
        end

        CHK_CMD: begin
            // In CHK_CMD, code samples only one bit from MOSI.
            if (i_spi_slave_ss_bar) begin
                nxt_state = IDLE; // If SS deasserted, go back to IDLE
            end else begin
                // Decides state based on single MOSI bit.
                if (!i_spi_slave_mosi) begin
                    nxt_state = WRITE;
                end else begin
                    if (addr_stored) begin
                        // Using addr_stored to choose between READ_ADDR and READ_DATA is flawed
                        nxt_state = READ_DATA;
                    end else begin
                        nxt_state = READ_ADDR;
                    end
                end
            end
        end

        WRITE: begin
            // In WRITE, remains until SS deasserted.
            if (i_spi_slave_ss_bar) begin
                nxt_state = IDLE;
            end else begin
                nxt_state = WRITE;
            end
        end

        READ_ADDR: begin
            // In READ_ADDR, shifts address bits. 
            if (i_spi_slave_ss_bar) begin
                nxt_state = IDLE;
            end else begin
                nxt_state = READ_ADDR;
            end
        end

        READ_DATA: begin
            if (i_spi_slave_ss_bar) begin
                nxt_state = IDLE;
            end else begin
                nxt_state = READ_DATA;
            end
        end

        default: nxt_state = IDLE;
    endcase
end

// Outputs and registers update
always @(posedge i_spi_slave_clk or negedge i_spi_slave_rst_n) begin
    if (!i_spi_slave_rst_n) begin
        // Reset all outputs and internal regs
        o_spi_slave_rx_data    <= 10'b0;
        o_spi_slave_rx_valid   <= 1'b0;
        o_spi_slave_miso       <= 1'b0;
        o_spi_slave_miso_valid <= 1'b0;
        counter                <= 4'b0;
        addr_stored            <= 1'b0;
        mosi_shift_reg         <= 10'b0;
        shift_read             <= 1'b0;
    end else begin
        case (curr_state)
            IDLE: begin
                // Clear outputs and registers at start of transaction
                o_spi_slave_rx_data    <= 10'b0;
                o_spi_slave_rx_valid   <= 1'b0;
                o_spi_slave_miso       <= 1'b0;
                o_spi_slave_miso_valid <= 1'b0;
                counter                <= 4'd0;
                mosi_shift_reg         <= 10'b0;
            end

            CHK_CMD: begin
                // Samples only one bit into MSB of shift register
                counter                <= 4'd0;
            end

            WRITE: begin
                // Attempts to shift in 9 bits after CHK_CMD.
                if (counter < 9) begin
                    mosi_shift_reg[8:0] <= {mosi_shift_reg[7:0], i_spi_slave_mosi};
                    counter <= counter + 1'b1;
                    o_spi_slave_rx_valid <= 1'b0;
                end else begin
                    o_spi_slave_rx_data  <= {1'b0,mosi_shift_reg[8:0]};
                    o_spi_slave_rx_valid <= 1'b1;
                    counter              <= 1'b0;
                end
            end

            READ_ADDR: begin
                // Similar flawed shift logic as WRITE
                if (counter < 9) begin
                    mosi_shift_reg[8:0] <= {mosi_shift_reg[7:0],i_spi_slave_mosi};
                    counter <= counter + 1'b1;
                    o_spi_slave_rx_valid <= 1'b0;
                end else begin
                    o_spi_slave_rx_data  <= {1'b1,mosi_shift_reg[8:0]};
                    o_spi_slave_rx_valid <= 1'b1;
                    counter              <= 1'b0;
                    addr_stored          <= 1'b1; 
                end
            end

            READ_DATA: begin
            
                if (addr_stored) begin
                    o_spi_slave_rx_data  <= {2'b11,8'b0};
                    shift_read  <= 1'b1;
                    counter     <= 4'd7;
                    addr_stored <= 1'b0;
                    o_spi_slave_rx_valid <= 1'b1;
                end  
                if (shift_read) begin
                    if (i_spi_slave_tx_valid) begin
                        o_spi_slave_miso       <= i_spi_slave_tx_data[counter];
                        o_spi_slave_miso_valid <= 1'b1;
                        if (counter > 0)
                            counter <= counter - 1;
                        else
                            shift_read <= 0;
                   end
                end
            end
            default: begin
                // Safe default: clear outputs
                o_spi_slave_rx_data    <= 10'b0;
                o_spi_slave_rx_valid   <= 1'b0;
                o_spi_slave_miso       <= 1'b0;
                o_spi_slave_miso_valid <= 1'b0;
                counter                <= 4'b0;
                addr_stored            <= 1'b0;
                mosi_shift_reg         <= 10'b0;
                shift_read             <= 1'b0;
            end
        endcase
    end
end

assign     o_spi_slave_sready = (curr_state == IDLE);
 

endmodule

