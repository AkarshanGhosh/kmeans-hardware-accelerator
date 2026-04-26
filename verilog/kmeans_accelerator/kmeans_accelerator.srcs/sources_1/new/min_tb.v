`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/26/2026 02:33:32 PM
// Design Name: 
// Module Name: min_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module min_tb;

    reg [31:0] d0, d1;
    wire cluster_id;

    min_finder uut (
        .d0(d0),
        .d1(d1),
        .cluster_id(cluster_id)
    );

    initial begin
        // Case 1
        d0 = 5; d1 = 10; #10;

        // Case 2
        d0 = 15; d1 = 8; #10;

        // Case 3
        d0 = 7; d1 = 7; #10;

        $stop;
    end

endmodule
