`timescale 1ns/1ps
`include "Baud.v"

module BaudRateGenerator_tb;

    // Parameters
    localparam integer N = 10;
    localparam integer M = 651;

    // Testbench signals
    reg clk;
    reg rst;
    wire baud_tick;

    // Instantiate the DUT
    Baud #(
        .N(N),
        .M(M)
    ) dut (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick)
    );

    // Clock generation: 100 MHz => 10 ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    // Test sequence
    initial begin
        // Initialize
        rst = 1;
        #20;
        rst = 0;

        // Run for a few baud ticks
        repeat (10) begin
            wait(baud_tick == 1);
            $display("Time: %0t ns, baud_tick asserted", $time);
            @(posedge clk);
        end

        $display("Test completed.");
    end

    initial begin
        $dumpfile("BaudRateGenerator_tb.vcd");
        $dumpvars(0, BaudRateGenerator_tb); 
        #50000 $finish;
    end

endmodule


`timescale 1ns/1ps
`include "UART.v"

module uart_tb;

    // Parameters
    localparam integer dbit = 8;
    localparam integer stick = 16;
    localparam integer depth = 16;

    // Testbench signals
    reg clk;
    reg rst;
    reg rd;
    reg wr;
    reg rx_in;
    reg [dbit-1:0] wr_data;
    wire empty;
    wire full;
    wire [dbit-1:0] rd_data;
    wire tx_out;

    // internal signals
    // wire rx_in = tx_out; // Loopback for testing

    // Instantiate the DUT
    UART #(
        .dbit(dbit),
        .stick(stick),
        .depth(depth)
    ) dut (
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

    // Clock generation: 100 MHz => 10 ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    // Test sequence
    initial begin
        $display("Starting UART Testbench...");
        // Initialize
        rst = 1;
        wr = 0;
        rd = 0;
        wr_data = 0;
        #20;
        rst = 0;

        // Write some bytes to the Tx fifo
        // writebyte(8'hA5);
        // #100000;
        // writebyte(8'h5A);
        // #100000;
        // writebyte(8'h3C);
        // Send UART-encoded bytes to rx_in
        send_serial(8'hA5);
        send_serial(8'h5A);
        send_serial(8'h3C);

        // wait for a while
        #5000000;

        // Read bytes from the Rx fifo
        readbyte();
        readbyte();
        readbyte();

        #100;

        $display("UART Test completed.");
    end

    // Task to write byte at Tx fifo
    // task writebyte(input [dbit-1:0] data);
    //     begin
    //     @(posedge clk);
    //     wr_data = data;
    //     wr = 1;
    //     @(posedge clk);
    //     wr = 0;
    //     $display("Wrote byte: 0x%0h", data);
    //     end
    // endtask

    task send_serial(input [7:0] data);
    integer i;
    begin
        // Send start bit
        rx_in = 0;
        #(10000); // 9600 baud => 1/9600 = ~104.17 us = 10417 ns

        // Send 8 data bits (LSB first)
        for (i = 0; i < 8; i = i + 1) begin
            rx_in = data[i];
            #(10000);
        end

        // Send stop bit (HIGH)
        rx_in = 1;
        #(10000);
    end
endtask


    // Task to read byte from Rx fifo
    task readbyte();
        begin
        wait(!empty);
        @(posedge clk);
        rd = 1;
        @(posedge clk);
        rd = 0;
        @(posedge clk);
        $display("Read byte: 0x%0h", rd_data);
        end
    endtask

    initial begin
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, uart_tb); 
        #30000000 $finish;
    end

endmodule
