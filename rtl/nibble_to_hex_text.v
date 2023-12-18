module nibble_to_hex_text (
   // pixel clock
   input  [3:0] data,
   output reg [7:0] text
);

always@(data) begin
    case(data)
        4'h0 : text = 8'd16;
        4'h1 : text = 8'd17;
        4'h2 : text = 8'd18;
        4'h3 : text = 8'd19;
        4'h4 : text = 8'd20;
        4'h5 : text = 8'd21;
        4'h6 : text = 8'd22;
        4'h7 : text = 8'd23;
        4'h8 : text = 8'd24;
        4'h9 : text = 8'd25;
        4'hA : text = 8'd33;
        4'hB : text = 8'd34;
        4'hC : text = 8'd35;
        4'hD : text = 8'd36;
        4'hE : text = 8'd37;
        4'hF : text = 8'd38;
        default : text = 8'd0;
    endcase
end

endmodule