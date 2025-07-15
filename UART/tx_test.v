`timescale 1ns / 1ps
`include "UART.v"

module uart_tx_tb;

    localparam dbit = 8;
    localparam stick = 16;
    localparam depth = 16;

    reg clk, rst;
    reg wr;
    reg [dbit-1:0] wr_data;
    wire tx_out;

    // Unused in this test
    wire rd = 0;
    wire [dbit-1:0] rd_data;
    wire empty, full;
    wire rx_in = 1'b1;  // Pull up receiver line

    // Instantiate UART (full DUT)
    UART #(
        .dbit(dbit),
        .stick(stick),
        .depth(depth)
    ) uart_inst (
        .clk(clk),
        .rst(rst),
        .rx_in(rx_in),
        .rd(rd),
        .wr(wr),
        .wr_data(wr_data),
        .empty(empty),
        .full(full),
        .rd_data(rd_data),
        .tx_out(tx_out)
    );

    // Clock generation: 10ns period (100 MHz)
    always #5 clk = ~clk;

    // Testbench logic
    initial begin
        $dumpfile("uart_tx_only_tb.vcd");
        $dumpvars(0, uart_tx_tb);

        clk = 0;
        rst = 1;
        wr = 0;
        wr_data = 0;

        #100;
        rst = 0;

        #1000;

        send_uart_byte(8'hA5);
        #1000000;

        send_uart_byte(8'h5A);
        #1000000;

        send_uart_byte(8'h3C);
        #2000000;

        $display("✅ UART Tx + FIFO test complete.");
        $finish;
    end

    task send_uart_byte(input [7:0] byte);
        begin
            @(posedge clk);
            wr_data <= byte;
            wr <= 1;
            @(posedge clk);
            wr <= 0;
            $display("[TB] Wrote byte to UART Tx FIFO: 0x%02h at time %t", byte, $time);
        end
    endtask

endmodule
