module quad_to_hex_text (
    input  [31:0] data,
    output [63:0] text
);

double_to_hex_text double_to_hex_text1(
    .data(data[31:16]),
    .text(text[63:32])
);

double_to_hex_text double_to_hex_text2(
    .data(data[15:0]),
    .text(text[31:0])
);

endmodule