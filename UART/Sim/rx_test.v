// `timescale 1ns/1ps
// `include "Receiver.v"
// `include "Fifo.v"
// module receiver_fifo_tb;

//   parameter DBIT  = 8;
//   parameter STICK = 16;
//   parameter DEPTH = 16;

//   // Clock & Reset
//   reg clk = 0;
//   reg rst = 1;
//   // UART input
//   reg rx_in;
//   // Baud tick generator signals
//   reg baud_tick = 0;
//   // Receiver output
//   wire rx_done;
//   wire [DBIT-1:0] dout;
//   // FIFO interface
//   wire empty;
//   reg rd_en = 0;
//   wire [DBIT-1:0] rd_data;
//   // Clock generation (100 MHz)
//   always #5 clk = ~clk;

//   // Baud tick generation (tick every 651 cycles for 9600*16)
//   integer tick_count = 0;
//   always @(posedge clk) begin
//     if (tick_count == 650) begin
//       baud_tick <= 1;
//       tick_count <= 0;
//     end else begin
//       baud_tick <= 0;
//       tick_count <= tick_count + 1;
//     end
//   end

//   // Instantiate receiver
//   receiver #(
//     .dbit(DBIT),
//     .stick(STICK)
//   ) dut_rx (
//     .clk(clk),
//     .rst(rst),
//     .baud_tick(baud_tick),
//     .rx_in(rx_in),
//     .rx_done(rx_done),
//     .dout(dout)
//   );

//   // Instantiate FIFO
//   fifo #(
//     .dbit(DBIT),
//     .depth(DEPTH)
//   ) dut_fifo (
//     .clk(clk),
//     .rst(rst),
//     .wr_data(dout),
//     .wr_en(rx_done),
//     .rd_en(rd_en),
//     .empty(empty),
//     .full(),
//     .rd_data(rd_data)
//   );

//   // UART byte task
//   task send_uart_byte(input [7:0] data);
//     integer i;
//     begin
//       $display("[TB] Sending UART byte: 0x%02h at time %t", data, $time);

//       // Start bit
//       rx_in = 0;
//       repeat(16) @(posedge baud_tick);

//       // Data bits (LSB first)
//       for (i = 0; i < 8; i = i + 1) begin
//         rx_in = data[i];
//         repeat(16) @(posedge baud_tick);
//       end

//       // Stop bit
//       rx_in = 1;
//       repeat(16) @(posedge baud_tick);
//     end
//   endtask

//   // Read FIFO byte task
//   task read_fifo_byte;
//     begin
//       wait (!empty);
//       @(posedge clk);
//       rd_en <= 1;
//       @(posedge clk);
//       rd_en <= 0;
//       @(posedge clk);
//       $display("[TB] Read from FIFO: 0x%02h at time %t", rd_data, $time);
//     end
//   endtask

//   // Stimulus
//   initial begin
//     $dumpfile("receiver_fifo_tb.vcd");
//     $dumpvars(0, receiver_fifo_tb);

//     rx_in = 1; // Idle
//     #50;
//     rst = 0;

//     #100;

//     send_uart_byte(8'hA5); // First byte
//     send_uart_byte(8'h5A); // Second byte

//     #1000000; // Wait for receiver and FIFO to update

//     read_fifo_byte();
//     read_fifo_byte();

//     #1000;
//     $display("[TB] Test completed.");
//     $finish;
//   end

// endmodule


`timescale 1ns / 1ps
`include "UART.v"

module uart_rx_tb;

    localparam dbit  = 8;
    localparam stick = 16;
    localparam depth = 16;

    reg clk;
    reg rst;
    reg rd;
    wire empty;
    wire full;
    wire [7:0] rd_data;

    reg rx_in;

    // Instantiate the DUT (Receiver path of UART)
    UART #(
        .dbit(dbit),
        .stick(stick),
        .depth(depth)
    ) uart_inst (
        .clk(clk),
        .rst(rst),
        .rx_in(rx_in),
        .rd(rd),
        .wr(1'b0),             // Tx path unused
        .wr_data(8'b0),        // Tx path unused
        .empty(empty),
        .full(full),
        .rd_data(rd_data),
        .tx_out()              // Unused
    );

    // Clock generation: 100MHz (10ns period)
    always #5 clk = ~clk;

    initial begin
        $dumpfile("uart_rx_tb.vcd");
        $dumpvars(0, uart_rx_tb);

        clk = 0;
        rst = 1;
        rd = 0;
        rx_in = 1;

        #100;
        rst = 0;

        #500;

        send_uart_byte(8'hA5);
        #1000000;
        read_and_check(8'hA5);

        send_uart_byte(8'h5A);
        #1000000;
        read_and_check(8'h5A);
        #1000000;

        $display("✅ Receiver test passed.");
        $finish;
    end

    // Task to send one UART byte serially (LSB first)
    task send_uart_byte(input [7:0] data);
        integer i;
        begin
            $display("[TB] Sending UART byte: 0x%02h at time %t", data, $time);

            // Start bit
            rx_in <= 0;
            #100000;

            // Data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx_in <= data[i];
                #100000;
            end

            // Stop bit
            rx_in <= 1;
            #100000;
        end
    endtask

    // Task to read and check the received data from Rx FIFO
    task read_and_check(input [7:0] expected);
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
