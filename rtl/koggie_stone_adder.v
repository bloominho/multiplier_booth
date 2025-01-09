
module koggie_stone_adder #(
	parameter WIDTH=8
) (
	input [WIDTH-1:0] 	A,
	input [WIDTH-1:0] 	B,
	input 				c_in,

	output [WIDTH-1:0] 	sum,
	output				c_out
);

//--- Preparation ----------
wire [WIDTH:0]   G_prep;
wire [WIDTH-1:0] A_prep;
wire [WIDTH-1:0] P_prep;

preparation_stage #(
	.WIDTH	(WIDTH)
) preparation (
	.X		(A),
	.Y		(B),
	.c_in	(c_in),

	.G		(G_prep),
	.A		(A_prep),
	.P		(P_prep)
);

//--- Tree ------------
localparam number_of_layers = $clog2(WIDTH+1);

wire [(WIDTH + 1) * (number_of_layers + 1) - 1 :0] G_tree;
wire [WIDTH * (number_of_layers + 1) - 1 : 0] A_tree;

assign G_tree[WIDTH : 0] = G_prep;
assign A_tree[WIDTH-1:0] = A_prep;

genvar i;
generate
	for(i=0; i<number_of_layers; i=i+1) begin
		tree_stage_layer #(
			.WIDTH	(WIDTH), 
			.layer_number(i)
		) tree (
			.G_in	(G_tree[i*(WIDTH+1) +: WIDTH+1]),
			.A_in	(A_tree[i*WIDTH +: WIDTH]),

			.G_out	(G_tree[(i+1)*(WIDTH+1) +: WIDTH+1]),
			.A_out	(A_tree[(i+1)*WIDTH +: WIDTH])
		);
	end
endgenerate

//--- Summation Stage
summation_stage #(
	.WIDTH (WIDTH)
) summation (
	.G_in	(G_tree[(WIDTH + 1) * (number_of_layers + 1)-1 -: WIDTH+1]),
	.A_in	(A_tree[(WIDTH) * (number_of_layers + 1)-1 -: WIDTH]),
	.P_in	(P_prep),
	
	.sum	(sum),
	.c_out	(c_out)
);


endmodule

//--- Preparation Stage -------------------------------
module preparation_stage #(
	parameter WIDTH = 8
) (
	input  [WIDTH-1 : 0] X,
	input  [WIDTH-1 : 0] Y,
	input  				 c_in,

	output [WIDTH   : 0] G,
	output [WIDTH-1 : 0] A,
	output [WIDTH-1 : 0] P
);

genvar i;
generate
	for(i=0; i<WIDTH; i=i+1) begin :preparation_units
		preparation_unit PU (
			.x(X[i]),
			.y(Y[i]),

			.g(G[i+1]),
			.a(A[i]),
			.p(P[i])
		);
	end
endgenerate

assign G[0] = c_in;

endmodule

//-- Preparation Unit (Used in Preparation Stage)
module preparation_unit (
	input x,
	input y,

	output g,
	output a,
	output p
);

assign p = x ^ y;
assign a = x | y;
assign g = x & y;

endmodule

//--- TREE STAGE ---------------------------------------------------
//----- A layer of Tree Stage
//         - Must be stacked (@top module)
module tree_stage_layer #(
	parameter WIDTH = 8,
	parameter layer_number = 0
) (
	input [WIDTH   : 0] G_in,
	input [WIDTH-1 : 0] A_in,

	output [WIDTH  : 0] G_out,
	output [WIDTH-1 : 0] A_out
);

assign G_out[0 +: 2**layer_number] = G_in[0 +: 2**layer_number];

//--- Blacks -------------
genvar i;
generate
	for(i=0; i<2**layer_number; i=i+1) begin : blacks
		if(2**layer_number + i <= WIDTH) begin
			black b (
				.g_0(G_in[i]),
				.a_1(A_in[(2**layer_number-1) + i]),
				.g_1(G_in[2**layer_number + i]),

				.g_o(G_out[2**layer_number + i])
			);
		end
	end
endgenerate

//--- Whites ------------------
generate
	for(i=0; i<WIDTH+1 - (2**layer_number * 2); i=i+1) begin : whites
		white w (
			.a_0(A_in[2**layer_number - 1 + i]),
			.a_1(A_in[(2**layer_number * 2) - 1 + i]),
			.g_0(G_in[2**layer_number + i]),
			.g_1(G_in[(2**layer_number * 2) + i]),

			.a_o(A_out[(2**layer_number * 2) - 1 + i]),
			.g_o(G_out[(2**layer_number * 2) + i])
		);
	end
endgenerate

endmodule

//-- Black Function (Used in TREE Stage)
module black (
	input g_0,
	input a_1,
	input g_1,

	output g_o
);

assign g_o = (a_1 & g_0) | g_1;

endmodule

//-- White Function (Used in TREE Stage)
module white (
	input a_0,
	input a_1,
	input g_0,
	input g_1,

	output a_o,
	output g_o
);

assign a_o = a_0 & a_1;
assign g_o = g_1 | (a_1 & g_0);

endmodule

//--- Summation Stage ----------------------------------------------
module summation_stage #(
	parameter WIDTH=8
) (
	input [WIDTH   : 0] G_in,
	input [WIDTH-1 : 0] A_in,
	input [WIDTH-1 : 0] P_in,

	output [WIDTH-1 : 0] sum,
	output 				 c_out
);

//--- Produces Sum (SUM = G ^ P)
assign sum = P_in ^ G_in;

//--- Produces Carry Out (c_out = black(G_i, A_i, G_0))
assign c_out = G_in[WIDTH];

endmodule