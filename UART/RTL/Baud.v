module Baud #(
    parameter integer N = 10,            //Counter value to hold the limit
    parameter integer M  = 651          //Counter limit
)
(
    input  wire clk,        // 100 MHz clock input
    input  wire rst,      // reset
    output reg  baud_tick   // 9600 baud rate tick output
);

    // Baud rate = 9600 bits per second
    // Clock frequency  = 100000000 (100Mhz)
    // Sampling rate = 9600*16 = 153600     (16 is taken due to oversampling method)
    // Counter limit = 100_000_000/153600 = 651
    // We'll use 651 for integer division
    reg [N-1:0] counter; // Enough bits to count up to 651

    always @(posedge clk , posedge rst) begin
        if (rst) begin
            counter   <= 0;
            baud_tick <= 0;
        end else if (counter == M-1) begin
            counter   <= 0;
            baud_tick <= 1;
        end else begin
            counter   <= counter + 1;
            baud_tick <= 0;
        end
    end

endmodule