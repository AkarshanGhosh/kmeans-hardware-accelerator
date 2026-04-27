`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/27/2026 10:41:55 AM
// Design Name: 
// Module Name: cluster_tb
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

module cluster_tb;

    reg [15:0] x, y;
    reg [15:0] cx0, cy0;
    reg [15:0] cx1, cy1;

    wire cluster_id;

    cluster_assign uut (
        .x(x), .y(y),
        .cx0(cx0), .cy0(cy0),
        .cx1(cx1), .cy1(cy1),
        .cluster_id(cluster_id)
    );

    initial begin
        // Case 1
        x = 2; y = 3;
        cx0 = 1; cy0 = 1;
        cx1 = 10; cy1 = 10;
        #10;

        // Case 2
        x = 11; y = 12;
        cx0 = 1; cy0 = 1;
        cx1 = 10; cy1 = 10;
        #10;

        // Case 3
        x = 5; y = 5;
        cx0 = 3; cy0 = 3;
        cx1 = 8; cy1 = 8;
        #10;

        $stop;
    end

endmodule
