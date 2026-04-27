`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/27/2026 10:04:21 AM
// Design Name: 
// Module Name: cluster_assign
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


module cluster_assign (
    input [15:0] x, y,
    input [15:0] cx0, cy0,
    input [15:0] cx1, cy1,
    output cluster_id
);

    wire [31:0] d0, d1;

    // Distance to centroid 0
    distance_unit dist0 (
        .x(x),
        .y(y),
        .cx(cx0),
        .cy(cy0),
        .distance(d0)
    );

    // Distance to centroid 1
    distance_unit dist1 (
        .x(x),
        .y(y),
        .cx(cx1),
        .cy(cy1),
        .distance(d1)
    );

    // Compare distances
    min_finder mf (
        .d0(d0),
        .d1(d1),
        .cluster_id(cluster_id)
    );

endmodule
