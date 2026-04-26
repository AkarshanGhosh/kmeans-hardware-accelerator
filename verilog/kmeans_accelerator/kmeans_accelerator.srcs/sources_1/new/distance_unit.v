`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/26/2026 12:52:58 PM
// Design Name: 
// Module Name: distance_unit
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


module distance_unit (
    input signed [15:0] x,
    input signed [15:0] y,
    input signed [15:0] cx,
    input signed [15:0] cy,
    output [31:0] distance
);

    // Difference between point and centroid
    wire signed [15:0] dx;
    wire signed [15:0] dy;

    assign dx = x - cx;
    assign dy = y - cy;

    // Distance calculation: (dx^2 + dy^2)
    assign distance = (dx * dx) + (dy * dy);

endmodule
