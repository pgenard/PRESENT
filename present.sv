module present(
  input clk,
  input nrst,
  input start,
  output eoc,
  input [63:0] plaintext,
  input [127:0] key,
  output[63:0] ciphertext
);

//---------wires, registers----------
reg  [127:0] kreg; // key register
reg  [63:0] dreg; // data register
reg  [4:0] round; // round counter
wire [63:0] dat1, dat2, dat3; // intermediate data
wire [127:0] kdat1, kdat2; // intermediate subkey data


//---------combinational processes----------

assign dat1 = dreg ^ kreg[127:64]; // add round key
assign ciphertext = dat1; // output ciphertext
assign eoc = (round == 0) ? 1 : 0;

// key update
assign kdat1 = {kreg[66:0], kreg[127:67]}; // rotate key 61 bits to the left
assign kdat2[61:0] = kdat1[61:0];
assign kdat2[66:62] = kdat1[66:62] ^ round; // xor key data and round counter
assign kdat2[127:67] = kdat1[127:67];


//---------instantiations--------------------

// instantiate 16 substitution boxes (S-Box) for encryption
genvar i;
generate
    for (i=0; i<64; i=i+4) 
    begin: sbox_loop
       present_sbox USBOX( .odat(dat2[i+3:i]), .idat(dat1[i+3:i]) );
    end
endgenerate

// instantiate P-Box (P-layer)
present_pbox UPBOX( .odat(dat3), .idat(dat2) );

// instantiate substitution box (S-Box) for key expansion
present_sbox USBOXKE2( .odat(kdat2[123:120]), .idat(kdat1[123:120]) );
present_sbox USBOXKE1( .odat(kdat2[127:124]), .idat(kdat1[127:124]) );

//---------sequential processes----------
   
// Load data
always @(posedge clk)
begin
   if (start)
      dreg <= plaintext;
   else if (!eoc)
      dreg <= dat3;
end

// Load/reload key into key register
always @(posedge clk)
begin
   if (start)
      kreg <= key;
   else if (!eoc)
      kreg <= kdat2;
end

// Round counter
always @(posedge clk)
begin
   if (start)
      round <= 1;
   else if (!eoc)
      round <= round + 1;
end

endmodule
