`include "Baud.v"
`include "Fifo.v"
`include "Receiver.v"
`include "Transmitter.v"

module UART #(
    parameter dbit = 8, // Data bit width
    parameter stick = 16, // Stop bits
    parameter depth = 16 // FIFO depth
)(
    input clk,            // Clock input
    input rst,            // Reset input
    input rx_in,          // Receive input
    input rd,      // Read enable signal
    input wr,      // Write enable signal
    input [dbit-1:0] wr_data, // Data input to transmitter 
    output wire empty,    // FIFO empty signal
    output wire full,      // FIFO full signal   
    output wire [dbit-1:0] rd_data, // Data output from receiver
    output wire tx_out      // Transmit output
);

wire baud_tick; // Baud rate tick signal
wire [dbit-1:0] tx_data; // Data to be transmitted
wire tx_empty; // Transmitter FIFO empty signal
wire tx_not_empty; // Transmitter FIFO not empty signal
wire tx_done; // Transmit done signal
wire rx_done; // Receive done signal
wire [dbit-1:0] rx_data; // Data received from receiver


assign tx_not_empty = ~tx_empty; // Transmitter FIFO not empty signal

Baud #(
    .N(10),            // Counter value to hold the limit
    .M(651)            // Counter limit
) baud_gen (
    .clk(clk),        // 100 MHz clock input
    .rst(rst),        // Reset
    .baud_tick(baud_tick) // 9600 baud rate tick output
);

transmitter #(
    .dbit(dbit),            // Data width
    .stick(stick)          // Stop bits
) tx (
    .clk(clk),            // Clock input
    .rst(rst),            // Reset input
    .baud_tick(baud_tick),         // Baud rate tick input
    .din(tx_data),          // Data input
    .tx_start(tx_not_empty),      // Transmit start signal
    .tx_out(tx_out),
    .tx_done(tx_done)    // Transmit done signal
);

receiver #(
    .dbit(dbit),            // Data width
    .stick(stick)          // Stop bits
) rx (
    .clk(clk),            // Clock input
    .rst(rst),            // Reset input
    .baud_tick(baud_tick),         // Baud rate tick input
    .rx_in(rx_in),         // Receive input
    .rx_done(rx_done),    // Receive done signal
    .dout(rx_data)  // Data output
);

fifo #(
    .dbit(dbit),            // Data width
    .depth(depth)          // FIFO depth

) fifo_tx (
    .clk(clk),            // Clock input
    .rst(rst),            // Reset input
    .wr_data(wr_data),          // Data input (write port)
    .wr_en(wr),      // Write enable signal
    .rd_en(tx_done),      // Read enable signal
    .empty(tx_empty),    // FIFO empty signal
    .full(full),     // FIFO full signal
    .rd_data(tx_data)  // Data output (read port)
);

fifo #(
    .dbit(dbit),            // Data width
    .depth(depth)          // FIFO depth
) fifo_rx (
    .clk(clk),            // Clock input
    .rst(rst),            // Reset input
    .wr_data(rx_data),          // Data input (write port)
    .wr_en(rx_done),      // Write enable signal
    .rd_en(rd),      // Read enable signal
    .empty(empty),    // FIFO empty signal
    .full(),     // FIFO full signal
    .rd_data(rd_data)  // Data output (read port)
);

endmodule