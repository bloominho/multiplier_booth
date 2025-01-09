// MULTIPLIER
//  - Based on Booth Encoding (Radix-4)
//  - Uses Koggie Stone Adder for accumulation -> Can be modified to use any type of adders
//  - Free WIDTH (ODD or EVEN) (ANY!)

// Made by Andrew Inho Park

module multiplier #(
	parameter WIDTH=8
) (
	input [WIDTH-1:0]   A,
	input [WIDTH-1:0]   B,

	output [2*WIDTH-1:0]  result
);

//--- PARAMETERS -----------------
localparam CONVERTED_WIDTH = (WIDTH % 2 == 0) ? WIDTH+2 : WIDTH+1;   // make B's width even
localparam COUNT = CONVERTED_WIDTH / 2;                              // number of encodings

wire [WIDTH+2:0] B_padded = {2'b0, B, 1'b0};                         // zero pad B -> for encoder

wire [(WIDTH+4)*(COUNT+1) - 1 : 0] partial_sums;
genvar i;
generate
    for(i=0; i<COUNT; i=i+1) begin
        //--- Generate Partial Product ----------
        wire [WIDTH : 0] A_pos_1x = {1'b0, A};
        wire [WIDTH : 0] A_pos_2x = {A, 1'b0};
        wire [WIDTH : 0] A_neg_1x = {1'b1, ~A};
        wire [WIDTH : 0] A_neg_2x = {~A, 1'b1};
        wire [WIDTH : 0] zero     = {(WIDTH+1){1'b0}};

        //--- Encoder ------------------
        wire [2:0] code;
        booth_encoder encoder (
            .X      (B_padded[i*2 +: 3]),
            .code   (code)
        );
        wire sign = code[1];
        
        if(i==0) begin
            // First Partial Product -> Does not need to add anything
            //--- Decoder -----------------
            wire [WIDTH   : 0]  A_encoded_temp = code[0] ? zero : (code[1] ? (code[2] ? A_neg_2x : A_neg_1x) : (code[2] ? A_pos_2x : A_pos_1x));
            wire [WIDTH+3 : 0]  A_encoded = {~sign, sign, sign, A_encoded_temp};
            
            assign partial_sums[WIDTH+3 : 0] = A_encoded;

        end else begin
            // Second Partial Product and so on -> Should accumulate

            //--- Calculate Sign of Previous -------
            wire [2:0] code_previous;
            booth_encoder encodoer_previous (
                .X    (B_padded[(i-1)*2 +: 3]),

                .code (code_previous)
            );
            wire sign_previous = code_previous[1];
            

            if(~((i==COUNT-1) | ((WIDTH%2 == 0) && (i== COUNT-2))))begin
                // 2nd ~ Last-1 Partial Products
                //      - Even Number of Partial Products : 2nd ~ Last-1
                //      - Odd Number of Partial Products : 2nd ~ Last

                //--- Decoder------------------------------------------------
                wire [WIDTH   : 0] A_encoded_temp = code[0] ? zero : (code[1] ? (code[2] ? A_neg_2x : A_neg_1x) : (code[2] ? A_pos_2x : A_pos_1x));
                wire [WIDTH+2 : 0] A_encoded = {1'b1, ~sign, A_encoded_temp};

                //--- ADD -----------------------------
                wire [WIDTH+5 : 0] partial_sum;
                koggie_stone_adder #(
                    .WIDTH      (WIDTH+5)
                ) adder (
                    .A          ({A_encoded, 2'b00}),
                    .B          ({1'b0, partial_sums[(WIDTH+4)*(i-1) +: WIDTH+4]}),
                    .c_in       (sign_previous),

                    .sum        (partial_sum[WIDTH+4 : 0]),
                    .c_out      (partial_sum[WIDTH+5])
                );

                assign result[(i-1)*2 +: 2] = partial_sum[1:0];     // 2 LSBs are passed to results
                assign partial_sums[(WIDTH+4)*i +: WIDTH+4] = partial_sum[WIDTH+5 : 2]; // Rest of them are stored as partial sums

            end else if(i == COUNT-2) begin
                // Last-1 Partial Products  (ONLY IN ODD CASES)
                //      - Odd Number of Partial Products : Last-1 (ONLY IN ODD CASES)

                //--- Decoder------------------------------------------------
                wire [WIDTH   : 0] A_encoded_temp = code[0] ? zero : (code[1] ? (code[2] ? A_neg_2x : A_neg_1x) : (code[2] ? A_pos_2x : A_pos_1x));
                wire [WIDTH+1 : 0] A_encoded = {~sign, A_encoded_temp};

                wire [WIDTH+4 : 0] partial_sum;
                koggie_stone_adder #(
                    .WIDTH      (WIDTH+4)
                ) adder (
                    .A          ({A_encoded, 2'b00}),
                    .B          (partial_sums[(WIDTH+4)*(i-1) +: WIDTH+4]),
                    .c_in       (sign_previous),

                    .sum        (partial_sum[WIDTH+3:0]),
                    .c_out      (partial_sum[WIDTH+4])
                );

                assign result[(i-1)*2 +: 2] = partial_sum[1:0];     // 2 LSBs are passed to results
                assign partial_sums[(WIDTH+4)*i +: WIDTH+3] = partial_sum[WIDTH+4 : 2]; // Rest of them are stored as partial sums


            end else begin
                // Last Partial Product

                //--- Decoder------------------------------------------------
                wire [WIDTH   : 0] A_encoded_temp = code[0] ? zero : (code[1] ? (code[2] ? A_neg_2x : A_neg_1x) : (code[2] ? A_pos_2x : A_pos_1x));
                wire [WIDTH : 0] A_encoded = A_encoded_temp;

                wire [WIDTH+2 : 0] partial_sum;
                koggie_stone_adder #(
                    .WIDTH      (WIDTH+3)
                ) adder (
                    .A          ({A_encoded, 2'b00}),
                    .B          (partial_sums[(WIDTH+4)*(i-1) +: WIDTH+3]),
                    .c_in       (sign_previous),

                    .sum        (partial_sum),
                    .c_out      ()
                );
                assign result[(i-1)*2 +: 2] = partial_sum[1:0];     // 2 LSBs are passed to results
                assign partial_sums[(WIDTH+4)*i +: WIDTH+1] = partial_sum[WIDTH+2 : 2]; // Rest of them are stored as partial sums
            end
        end
    end

    if(WIDTH % 2 == 0) begin
        assign result[2*WIDTH-1 -: WIDTH] = partial_sums[(COUNT-1)*(WIDTH+4) +: WIDTH];
    end else begin
        assign result[2*WIDTH-1 -: WIDTH+1] = partial_sums[(COUNT-1)*(WIDTH+4) +: WIDTH+1]; 
    end
endgenerate



endmodule

module booth_encoder (
    input      [2:0] X,

    output reg [2:0] code
);

wire [2:0] zero   = 3'b001;
wire [2:0] pos_1x = 3'b000;
wire [2:0] pos_2x = 3'b100;
wire [2:0] neg_1x = 3'b010;
wire [2:0] neg_2x = 3'b110;

//--- Encode ----------------------------------
always @(*) begin
    case(X)
        3'b000: code = zero;
        3'b001: code = pos_1x;
        3'b010: code = pos_1x;
        3'b011: code = pos_2x;
        3'b100: code = neg_2x;
        3'b101: code = neg_1x;
        3'b110: code = neg_1x;
        3'b111: code = zero;
        default: code = zero;
    endcase
end

endmodule