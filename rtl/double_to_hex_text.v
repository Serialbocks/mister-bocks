module double_to_hex_text (
    input  [15:0] data,
    output [31:0] text
);

byte_to_hex_text byte_to_hex_text1(
    .data(data[15:8]),
    .text(text[31:16])
);

byte_to_hex_text byte_to_hex_text2(
    .data(data[7:0]),
    .text(text[15:0])
);

endmodule