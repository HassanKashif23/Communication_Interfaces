module receiver #(
    parameter dbit = 8,            // Data width
    parameter stick = 16
) (
    input clk,            // Clock input
    input rst,            // Reset input
    input baud_tick,         // Baud rate tick input
    input rx_in,         // Receive input
    output reg rx_done,    // Receive done signal
    output wire [dbit-1:0] dout  // Data output
);

    // State machine states
    localparam [1:0] IDLE = 2'b00,
                     START = 2'b01,
                     DATA = 2'b10,
                     STOP = 2'b11;
    
    // Register
    reg [1:0] present_state, next_state;      // State registers
    reg [3:0] tick, next_tick;        // Ticks received from baud rate generator
    reg [2:0] nbits, next_nbits;      // Number of bits received in data state
    reg [dbit-1:0] data, next_data;      // Data to be received

    // Present state logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            present_state <= IDLE;
            tick <= 0;
            nbits <= 0;
            data <= 0;
        end else begin
            present_state <= next_state;
            tick <= next_tick;
            nbits <= next_nbits;
            data <= next_data;
        end
    end
    
    // Next state logic
    always @ (*) begin
        next_state = present_state;
        next_tick = tick;
        next_nbits = nbits;
        next_data = data;
        rx_done = 0; // Default to not done

        case (present_state)
            
            IDLE: begin
              if (baud_tick && rx_in == 0) begin
                next_state = START;    // Move to start state
                next_tick = 0;         // Reset tick counter
              end 
            end

            START: begin
              if (baud_tick) begin
                if (tick == 8) begin
                    next_state = DATA;    //Move to data state
                    next_tick = 0;         // Reset tick counter
                    next_nbits = 0;        // Reset bit counter
                end else begin
                    next_tick = tick + 1;  // Increment tick counter
                end
              end
            end

            DATA: begin
              if (baud_tick)
                if (tick == 15) begin
                    next_tick = 0; // Reset tick counter
                    next_data = {rx_in, data[dbit-1:1]} ; // Shift in the received bit
                    if (nbits == (dbit - 1))
                        next_state = STOP;    // Move to stop state
                    else 
                        next_nbits = nbits + 1; // Increment bit counter
                end else
                    next_tick = tick + 1; // Increment tick counter
            end

            STOP: begin
              if (baud_tick)
                if (tick == (stick - 1)) begin
                    next_state = IDLE;    // Move back to idle state
                    rx_done = 1;          // Indicate that data reception is done
                    $display("[Receiver] Byte received: 0x%02h at time %t", data, $time);
                end else begin
                    next_tick = tick + 1; // Increment tick counter
                end
            end
        endcase
    end

    // Output logic
    assign dout = data;
    

endmodule