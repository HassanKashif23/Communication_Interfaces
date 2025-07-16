module transmitter #(
    parameter dbit = 8,            // Data width
    parameter stick = 16
) (
    input clk,            // Clock input
    input rst,            // Reset input
    input baud_tick,         // Baud rate tick input
    input [dbit-1:0]din,          // Data input
    input tx_start,      // Transmit start signal
    output reg tx_done,    // Transmit done signal
    output wire tx_out      // Transmit output
);
    //state machine states
    localparam [1:0] IDLE = 00,
                     START = 01,
                     DATA = 10,
                     STOP = 11;
    
    // Register
    reg [1:0] present_state, next_state;      //state registers
    reg [3:0] tick, next_tick;        //ticks received from baud rate generator
    reg [2:0] nbits, next_nbits;      //no of bits transmitted in data state
    reg [dbit-1:0] data, next_data;      //data to be transmitted
    reg tx_reg, next_tx_reg;  //transmit register
    //reg tx_done_reg; // transmit done register

    //Present state logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            present_state <= IDLE;
            tick <= 0;
            nbits <= 0;
            data <= 0;
            tx_reg <= 1; // idle state for tx line is high
            //tx_done <= 0; // Reset tx_done on reset
        end else begin
            present_state <= next_state;
            tick <= next_tick;
            nbits <= next_nbits;
            data <= next_data;
            tx_reg <= next_tx_reg;
            //tx_done <= tx_done_reg;
        end
    end

    //Next state logic
    always @ (*) begin
        // Default assignments
        next_state = present_state;
        next_tick = tick;
        next_nbits = nbits;
        next_data = data;
        next_tx_reg = tx_reg;
        //tx_done_reg = 0; // Default to not done
        case (present_state)

            IDLE : begin
              next_tx_reg = 1'b1; // Idle state for tx line is high
              if (tx_start) begin
                next_state = START;    //Move to START state on tx_start
                next_data = din;       // Load data to be transmitted
                next_tick = 0; // Reset tick counter
              end
            end

            START : begin
              next_tx_reg = 1'b0; // Start bit is low
              if (baud_tick)
                if (tick == 15) begin
                    next_state = DATA;    //Move to DATA state after start bit
                    next_tick = 0; // Reset tick counter
                    next_nbits = 0; // Reset bit counter
                end else
                    next_tick = tick + 1; // Increment tick counter
            end

            DATA : begin
              next_tx_reg = data[0]; // Transmit current bit
                if (baud_tick)
                    if (tick == 15) begin
                        next_tick = 0; // Reset tick counter
                        next_data = data >> 1; // Shift data to get next bit
                        if (nbits == (dbit -1))
                            next_state = STOP; // Move to STOP state after all bits are sent
                        else
                            next_nbits = nbits + 1; // Increment bit counter
                    end else begin
                        next_tick = tick + 1; // Increment tick counter
                    end
            end

            STOP : begin
              next_tx_reg = 1'b1; // Stop bit is high
                if (baud_tick)
                    if (tick == (stick - 1)) begin
                      next_state = IDLE; // Move to IDLE state after stop bit
                      tx_done = 1; // Indicate transmission is done
                end else
                    next_tick = tick + 1; // Increment tick counter
            end
        endcase
    end

    // Output assignment
    assign tx_out = tx_reg;

endmodule