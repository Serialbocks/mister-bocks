module byte_to_hex_text (
    input  [7:0] data,
    output [15:0] text
);

nibble_to_hex_text nibble_to_hex_text1(
    .data(data[7:4]),
    .text(text[15:8])
);

nibble_to_hex_text nibble_to_hex_text2(
    .data(data[3:0]),
    .text(text[7:0])
);

endmodule