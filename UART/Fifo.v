module fifo #(
    parameter dbit = 8,            // Data width
    parameter depth = 16      // FIFO depth
) (
    input clk,            // Clock input
    input rst,            // Reset input
    input [dbit-1:0] wr_data,          // Data input (write port)
    input wr_en,      // Write enable signal
    input rd_en,      // Read enable signal
    output reg empty,    // FIFO empty signal
    output reg full,     // FIFO full signal
    output reg [dbit-1:0] rd_data  // Data output (read port)
);

reg [dbit-1:0] fifo_mem [0:depth-1]; // FIFO memory array
reg [3:0] wr_ptr; // Write pointer
reg [3:0] rd_ptr; // Read pointer
reg [3:0] count; // Count of elements in FIFO

always @(posedge clk or posedge rst) begin
    if (rst) begin
        wr_ptr <= 0;
        rd_ptr <= 0;
        empty <= 1;
        full <= 0;
        count <= 0;
    end else begin
        // write operation
        if (wr_en && !full) begin
            fifo_mem[wr_ptr] <= wr_data;
            wr_ptr <= wr_ptr + 1;
            //$display("[FIFO_RX] Wrote to Rx FIFO: 0x%02h at time %t", wr_data, $time);
        end
        // read operation
        if (rd_en && !empty) begin
            rd_data <= fifo_mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
        end
        // count logic
        case ({rd_en && !empty, wr_en && !full})
            2'b00: count <= count; // No operation
            2'b01: count <= count + 1; // Write only
            2'b10: count <= count - 1; // Read only
            2'b11: count <= count; // No operation
        endcase
        // Update empty and full flags
        empty <= (count == 0);
        full <= (count == depth);
    end
end
    
endmodule