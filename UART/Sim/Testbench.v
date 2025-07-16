`timescale 1ns / 1ps
`include "UART.v"

module uart_full_tb;

    localparam dbit  = 8;
    localparam stick = 16;
    localparam depth = 16;

    reg clk;
    reg rst;
    reg wr;
    reg rd;
    reg [7:0] wr_data;
    reg rx_in;

    wire tx_out;
    wire [7:0] rd_data;
    wire empty, full;

    // Instantiate the UART core
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

    // Clock generation: 100MHz
    always #5 clk = ~clk;

    initial begin
        $dumpfile("uart_full_tb.vcd");
        $dumpvars(0, uart_full_tb);

        clk = 0;
        rst = 1;
        wr = 0;
        rd = 0;
        wr_data = 0;
        rx_in = 1; // idle line

        #100;
        rst = 0;
        #500;

        // Phase 1: Transmitter + Tx FIFO
        $display("\n[PHASE 1] Transmitter Test");
        send_to_tx_fifo(8'hA5);
        #1000000;
        send_to_tx_fifo(8'h5A);
        #1000000;
        send_to_tx_fifo(8'h3C);
        #2000000;

        // Phase 2: Receiver + Rx FIFO
        $display("\n[PHASE 2] Receiver Test");
        send_uart_byte(8'h12);
        #1200000;
        send_uart_byte(8'h34);
        #1200000;
        send_uart_byte(8'h56);

        #1000000;

        read_from_rx_fifo(8'h12);
        read_from_rx_fifo(8'h34);
        read_from_rx_fifo(8'h56);

        #2000000;
        $display("✅ Full UART test passed.");
        $finish;
    end

    // Send to Tx FIFO (simulate system writing to UART Tx path)
    task send_to_tx_fifo(input [7:0] byte);
        begin
            @(posedge clk);
            wr_data <= byte;
            wr <= 1;
            @(posedge clk);
            wr <= 0;
            $display("[TB] Wrote byte to UART Tx FIFO: 0x%02h at time %t", byte, $time);
        end
    endtask

    // Simulate a serial UART byte into rx_in
    task send_uart_byte(input [7:0] data);
        integer i;
        begin
            $display("[TB] Injected UART byte: 0x%02h at time %t", data, $time);
            rx_in <= 0; // start bit
            #100000;
            for (i = 0; i < 8; i = i + 1) begin
                rx_in <= data[i];
                #100000;
            end
            rx_in <= 1; // stop bit
            #100000;
        end
    endtask

    // Read and check from Rx FIFO
    task read_from_rx_fifo(input [7:0] expected);
        begin
            wait (!empty);
            @(posedge clk);
            rd <= 1;
            @(posedge clk);
            rd <= 0;
            @(posedge clk);
            $display("[TB] Read byte : 0x%02h at time %t", rd_data, $time);
            if (rd_data !== expected) begin
                $display("❌ MISMATCH: expected 0x%02h, got 0x%02h", expected, rd_data);
                $finish;
            end
        end
    endtask

endmodule




//!@@###$$$$%%%%%^^^^^^&&&&&&&********((((((((()))))))))
//(**&&&^^^^%%%%%$$$$$$#######@@@@@@@@!!!!!!!!!)

// `timescale 1ns / 1ps
// `include "UART.v"

// module uart_tb;

//     localparam dbit  = 8;
//     localparam stick = 16;
//     localparam depth = 16;

//     reg clk;
//     reg rst;
//     reg rd;
//     reg wr;
//     reg [dbit-1:0] wr_data;
//     wire [dbit-1:0] rd_data;
//     wire empty, full;
//     wire tx_out;

//     // Loopback connection
//     wire rx_in = tx_out;

//     // Instantiate the DUT
//     UART #(
//         .dbit(dbit),
//         .stick(stick),
//         .depth(depth)
//     ) uart_inst (
//         .clk(clk),
//         .rst(rst),
//         .rx_in(rx_in),
//         .rd(rd),
//         .wr(wr),
//         .wr_data(wr_data),
//         .empty(empty),
//         .full(full),
//         .rd_data(rd_data),
//         .tx_out(tx_out)
//     );

//     // Clock: 100 MHz = 10ns period
//     always #5 clk = ~clk;

//     // Test data to send
//     reg [7:0] test_data [0:2];
//     integer i;

//     initial begin
//         $dumpfile("uart_tb.vcd");
//         $dumpvars(0, uart_tb);

//         // Initialize
//         clk = 0;
//         rst = 1;
//         wr = 0;
//         rd = 0;
//         wr_data = 0;

//         test_data[0] = 8'hA5;
//         test_data[1] = 8'h5A;
//         test_data[2] = 8'h3C;

//         #100;  // Allow system to stabilize
//         rst = 0;

//         #1000;

//         // Transmit each byte
//         for (i = 0; i < 3; i = i + 1) begin
//             write_byte(test_data[i]);
//             wait_for_transmit_done();
//         end

//         // Small delay before reading
//         #1000000;

//         // Read each byte and check
//         for (i = 0; i < 3; i = i + 1) begin
//             read_byte_and_check(test_data[i]);
//         end

//         #1000;
//         $display("✅ UART test passed.");
//         $finish;
//     end

//     // Write one byte to UART
//     task write_byte(input [7:0] data);
//         begin
//             @(posedge clk);
//             wr_data <= data;
//             wr <= 1;
//             @(posedge clk);
//             wr <= 0;
//             $display("[TB] Wrote byte: 0x%02h", data);
//         end
//     endtask

//     // Wait until tx_done signals that transmit is complete
//     task wait_for_transmit_done();
//         begin
//             // Wait generously based on baud rate: 1 byte ~ (10+ stop) * 651 * 10ns
//             #1000000;
//         end
//     endtask

//     // Read byte from Rx FIFO and compare
//     task read_byte_and_check(input [7:0] expected);
//         begin
//             wait (!empty);
//             @(posedge clk);
//             rd <= 1;
//             @(posedge clk);
//             rd <= 0;
//             @(posedge clk);  // Allow rd_data to settle
//             $display("[TB] Read byte : 0x%02h", rd_data);
//             if (rd_data !== expected) begin
//                 $display("❌ MISMATCH: expected 0x%02h, got 0x%02h", expected, rd_data);
//                 $finish;
//             end
//         end
//     endtask

// endmodule