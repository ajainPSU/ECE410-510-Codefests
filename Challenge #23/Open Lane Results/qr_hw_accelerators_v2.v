// -----------------------------
// HW Accelerated Modules V2
// - Full GF(256) modular arithmetic
// - Reed-Solomon RS(255, k) decoder (syndromes, BMA, Chien, Forney)
// - NSYM = 102 for QR versions 1–10 @ Level H
// -----------------------------

`timescale 1ns / 1ps

// -----------------------------
// GF(256) Addition w/ XOR
// -----------------------------
module gf256_add (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] result
);
    assign result = a ^ b;
endmodule

// -----------------------------
// GF(256) Multiplication
// -----------------------------
module gf256_mult (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output reg  [7:0] result
);
    reg [15:0] product;
    integer i;

    always @(*) begin
        product = 0;

        for (i = 0; i < 8; i = i + 1)
            if (b[i]) product = product ^ (a << i);

        for (i = 15; i >= 8; i = i - 1)
            if (product[i]) product = product ^ (16'h11D << (i - 8));

        result = product[7:0];
    end
endmodule

// -----------------------------
// GF(256) Division
// -----------------------------
module gf256_div (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] result
);
    wire [7:0] b_inv;
    wire [7:0] r;

    gf256_inverse inv_inst (.a(b), .inv(b_inv));
    gf256_mult    mul_inst (.a(a), .b(b_inv), .result(r));

    assign result = r;
endmodule

// -----------------------------
// GF(256) Inversion
// -----------------------------
module gf256_inverse (
    input  wire [7:0] a,
    output reg  [7:0] inv
);
    function [7:0] gf_mult;
        input [7:0] a, b;
        reg [15:0] p;
        integer j;
        begin
            p = 0;
            for (j = 0; j < 8; j = j + 1)
                if (b[j]) p = p ^ (a << j);
            for (j = 15; j >= 8; j = j - 1)
                if (p[j]) p = p ^ (16'h11D << (j - 8));
            gf_mult = p[7:0];
        end
    endfunction

    integer i;
    reg [7:0] r;

    always @(*) begin
        if (a == 0)
            inv = 0;
        else begin
            r = 1;
            for (i = 0; i < 254; i = i + 1)
                r = gf_mult(r, a);
            inv = r;
        end
    end
endmodule


// -----------------------------
// GF(256) Exponents
// -----------------------------
module gf256_exp (
    input  logic [8:0] in,     // Input exponent index (0–510)
    output logic [7:0] out
);

    logic [7:0] exp_table [0:510];

    initial begin
        exp_table[0] = 8'h01;
        exp_table[1] = 8'h02;
        exp_table[2] = 8'h04;
        exp_table[3] = 8'h08;
        exp_table[4] = 8'h10;
        exp_table[5] = 8'h20;
        exp_table[6] = 8'h40;
        exp_table[7] = 8'h80;
        exp_table[8] = 8'h1d;
        exp_table[9] = 8'h3a;
        exp_table[10] = 8'h74;
        exp_table[11] = 8'he8;
        exp_table[12] = 8'hcd;
        exp_table[13] = 8'h87;
        exp_table[14] = 8'h13;
        exp_table[15] = 8'h26;
        exp_table[16] = 8'h4c;
        exp_table[17] = 8'h98;
        exp_table[18] = 8'h2d;
        exp_table[19] = 8'h5a;
        exp_table[20] = 8'hb4;
        exp_table[21] = 8'h75;
        exp_table[22] = 8'hea;
        exp_table[23] = 8'hc9;
        exp_table[24] = 8'h8f;
        exp_table[25] = 8'h03;
        exp_table[26] = 8'h06;
        exp_table[27] = 8'h0c;
        exp_table[28] = 8'h18;
        exp_table[29] = 8'h30;
        exp_table[30] = 8'h60;
        exp_table[31] = 8'hc0;
        exp_table[32] = 8'h9d;
        exp_table[33] = 8'h27;
        exp_table[34] = 8'h4e;
        exp_table[35] = 8'h9c;
        exp_table[36] = 8'h25;
        exp_table[37] = 8'h4a;
        exp_table[38] = 8'h94;
        exp_table[39] = 8'h35;
        exp_table[40] = 8'h6a;
        exp_table[41] = 8'hd4;
        exp_table[42] = 8'hb5;
        exp_table[43] = 8'h77;
        exp_table[44] = 8'hee;
        exp_table[45] = 8'hc1;
        exp_table[46] = 8'h9f;
        exp_table[47] = 8'h23;
        exp_table[48] = 8'h46;
        exp_table[49] = 8'h8c;
        exp_table[50] = 8'h05;
        exp_table[51] = 8'h0a;
        exp_table[52] = 8'h14;
        exp_table[53] = 8'h28;
        exp_table[54] = 8'h50;
        exp_table[55] = 8'ha0;
        exp_table[56] = 8'h5d;
        exp_table[57] = 8'hba;
        exp_table[58] = 8'h69;
        exp_table[59] = 8'hd2;
        exp_table[60] = 8'hb9;
        exp_table[61] = 8'h6f;
        exp_table[62] = 8'hde;
        exp_table[63] = 8'ha1;
        exp_table[64] = 8'h5f;
        exp_table[65] = 8'hbe;
        exp_table[66] = 8'h61;
        exp_table[67] = 8'hc2;
        exp_table[68] = 8'h99;
        exp_table[69] = 8'h2f;
        exp_table[70] = 8'h5e;
        exp_table[71] = 8'hbc;
        exp_table[72] = 8'h65;
        exp_table[73] = 8'hca;
        exp_table[74] = 8'h89;
        exp_table[75] = 8'h0f;
        exp_table[76] = 8'h1e;
        exp_table[77] = 8'h3c;
        exp_table[78] = 8'h78;
        exp_table[79] = 8'hf0;
        exp_table[80] = 8'hfd;
        exp_table[81] = 8'he7;
        exp_table[82] = 8'hd3;
        exp_table[83] = 8'hbb;
        exp_table[84] = 8'h6b;
        exp_table[85] = 8'hd6;
        exp_table[86] = 8'hb1;
        exp_table[87] = 8'h7f;
        exp_table[88] = 8'hfe;
        exp_table[89] = 8'he1;
        exp_table[90] = 8'hdf;
        exp_table[91] = 8'ha3;
        exp_table[92] = 8'h5b;
        exp_table[93] = 8'hb6;
        exp_table[94] = 8'h71;
        exp_table[95] = 8'he2;
        exp_table[96] = 8'hd9;
        exp_table[97] = 8'haf;
        exp_table[98] = 8'h43;
        exp_table[99] = 8'h86;
        exp_table[100] = 8'h11;
        exp_table[101] = 8'h22;
        exp_table[102] = 8'h44;
        exp_table[103] = 8'h88;
        exp_table[104] = 8'h0d;
        exp_table[105] = 8'h1a;
        exp_table[106] = 8'h34;
        exp_table[107] = 8'h68;
        exp_table[108] = 8'hd0;
        exp_table[109] = 8'hbd;
        exp_table[110] = 8'h67;
        exp_table[111] = 8'hce;
        exp_table[112] = 8'h81;
        exp_table[113] = 8'h1f;
        exp_table[114] = 8'h3e;
        exp_table[115] = 8'h7c;
        exp_table[116] = 8'hf8;
        exp_table[117] = 8'hed;
        exp_table[118] = 8'hc7;
        exp_table[119] = 8'h93;
        exp_table[120] = 8'h3b;
        exp_table[121] = 8'h76;
        exp_table[122] = 8'hec;
        exp_table[123] = 8'hc5;
        exp_table[124] = 8'h97;
        exp_table[125] = 8'h33;
        exp_table[126] = 8'h66;
        exp_table[127] = 8'hcc;
        exp_table[128] = 8'h85;
        exp_table[129] = 8'h17;
        exp_table[130] = 8'h2e;
        exp_table[131] = 8'h5c;
        exp_table[132] = 8'hb8;
        exp_table[133] = 8'h6d;
        exp_table[134] = 8'hda;
        exp_table[135] = 8'ha9;
        exp_table[136] = 8'h4f;
        exp_table[137] = 8'h9e;
        exp_table[138] = 8'h21;
        exp_table[139] = 8'h42;
        exp_table[140] = 8'h84;
        exp_table[141] = 8'h15;
        exp_table[142] = 8'h2a;
        exp_table[143] = 8'h54;
        exp_table[144] = 8'ha8;
        exp_table[145] = 8'h4d;
        exp_table[146] = 8'h9a;
        exp_table[147] = 8'h29;
        exp_table[148] = 8'h52;
        exp_table[149] = 8'ha4;
        exp_table[150] = 8'h55;
        exp_table[151] = 8'haa;
        exp_table[152] = 8'h49;
        exp_table[153] = 8'h92;
        exp_table[154] = 8'h39;
        exp_table[155] = 8'h72;
        exp_table[156] = 8'he4;
        exp_table[157] = 8'hd5;
        exp_table[158] = 8'hb7;
        exp_table[159] = 8'h73;
        exp_table[160] = 8'he6;
        exp_table[161] = 8'hd1;
        exp_table[162] = 8'hbf;
        exp_table[163] = 8'h63;
        exp_table[164] = 8'hc6;
        exp_table[165] = 8'h91;
        exp_table[166] = 8'h3f;
        exp_table[167] = 8'h7e;
        exp_table[168] = 8'hfc;
        exp_table[169] = 8'he5;
        exp_table[170] = 8'hd7;
        exp_table[171] = 8'hb3;
        exp_table[172] = 8'h7b;
        exp_table[173] = 8'hf6;
        exp_table[174] = 8'hf1;
        exp_table[175] = 8'hff;
        exp_table[176] = 8'he3;
        exp_table[177] = 8'hdb;
        exp_table[178] = 8'hab;
        exp_table[179] = 8'h4b;
        exp_table[180] = 8'h96;
        exp_table[181] = 8'h31;
        exp_table[182] = 8'h62;
        exp_table[183] = 8'hc4;
        exp_table[184] = 8'h95;
        exp_table[185] = 8'h37;
        exp_table[186] = 8'h6e;
        exp_table[187] = 8'hdc;
        exp_table[188] = 8'ha5;
        exp_table[189] = 8'h57;
        exp_table[190] = 8'hae;
        exp_table[191] = 8'h41;
        exp_table[192] = 8'h82;
        exp_table[193] = 8'h19;
        exp_table[194] = 8'h32;
        exp_table[195] = 8'h64;
        exp_table[196] = 8'hc8;
        exp_table[197] = 8'h8d;
        exp_table[198] = 8'h07;
        exp_table[199] = 8'h0e;
        exp_table[200] = 8'h1c;
        exp_table[201] = 8'h38;
        exp_table[202] = 8'h70;
        exp_table[203] = 8'he0;
        exp_table[204] = 8'hdd;
        exp_table[205] = 8'ha7;
        exp_table[206] = 8'h53;
        exp_table[207] = 8'ha6;
        exp_table[208] = 8'h51;
        exp_table[209] = 8'ha2;
        exp_table[210] = 8'h59;
        exp_table[211] = 8'hb2;
        exp_table[212] = 8'h79;
        exp_table[213] = 8'hf2;
        exp_table[214] = 8'hf9;
        exp_table[215] = 8'hef;
        exp_table[216] = 8'hc3;
        exp_table[217] = 8'h9b;
        exp_table[218] = 8'h2b;
        exp_table[219] = 8'h56;
        exp_table[220] = 8'hac;
        exp_table[221] = 8'h45;
        exp_table[222] = 8'h8a;
        exp_table[223] = 8'h09;
        exp_table[224] = 8'h12;
        exp_table[225] = 8'h24;
        exp_table[226] = 8'h48;
        exp_table[227] = 8'h90;
        exp_table[228] = 8'h3d;
        exp_table[229] = 8'h7a;
        exp_table[230] = 8'hf4;
        exp_table[231] = 8'hf5;
        exp_table[232] = 8'hf7;
        exp_table[233] = 8'hf3;
        exp_table[234] = 8'hfb;
        exp_table[235] = 8'heb;
        exp_table[236] = 8'hcb;
        exp_table[237] = 8'h8b;
        exp_table[238] = 8'h0b;
        exp_table[239] = 8'h16;
        exp_table[240] = 8'h2c;
        exp_table[241] = 8'h58;
        exp_table[242] = 8'hb0;
        exp_table[243] = 8'h7d;
        exp_table[244] = 8'hfa;
        exp_table[245] = 8'he9;
        exp_table[246] = 8'hcf;
        exp_table[247] = 8'h83;
        exp_table[248] = 8'h1b;
        exp_table[249] = 8'h36;
        exp_table[250] = 8'h6c;
        exp_table[251] = 8'hd8;
        exp_table[252] = 8'had;
        exp_table[253] = 8'h47;
        exp_table[254] = 8'h8e;
        exp_table[255] = 8'h01;
        exp_table[256] = 8'h02;
        exp_table[257] = 8'h04;
        exp_table[258] = 8'h08;
        exp_table[259] = 8'h10;
        exp_table[260] = 8'h20;
        exp_table[261] = 8'h40;
        exp_table[262] = 8'h80;
        exp_table[263] = 8'h1d;
        exp_table[264] = 8'h3a;
        exp_table[265] = 8'h74;
        exp_table[266] = 8'he8;
        exp_table[267] = 8'hcd;
        exp_table[268] = 8'h87;
        exp_table[269] = 8'h13;
        exp_table[270] = 8'h26;
        exp_table[271] = 8'h4c;
        exp_table[272] = 8'h98;
        exp_table[273] = 8'h2d;
        exp_table[274] = 8'h5a;
        exp_table[275] = 8'hb4;
        exp_table[276] = 8'h75;
        exp_table[277] = 8'hea;
        exp_table[278] = 8'hc9;
        exp_table[279] = 8'h8f;
        exp_table[280] = 8'h03;
        exp_table[281] = 8'h06;
        exp_table[282] = 8'h0c;
        exp_table[283] = 8'h18;
        exp_table[284] = 8'h30;
        exp_table[285] = 8'h60;
        exp_table[286] = 8'hc0;
        exp_table[287] = 8'h9d;
        exp_table[288] = 8'h27;
        exp_table[289] = 8'h4e;
        exp_table[290] = 8'h9c;
        exp_table[291] = 8'h25;
        exp_table[292] = 8'h4a;
        exp_table[293] = 8'h94;
        exp_table[294] = 8'h35;
        exp_table[295] = 8'h6a;
        exp_table[296] = 8'hd4;
        exp_table[297] = 8'hb5;
        exp_table[298] = 8'h77;
        exp_table[299] = 8'hee;
        exp_table[300] = 8'hc1;
        exp_table[301] = 8'h9f;
        exp_table[302] = 8'h23;
        exp_table[303] = 8'h46;
        exp_table[304] = 8'h8c;
        exp_table[305] = 8'h05;
        exp_table[306] = 8'h0a;
        exp_table[307] = 8'h14;
        exp_table[308] = 8'h28;
        exp_table[309] = 8'h50;
        exp_table[310] = 8'ha0;
        exp_table[311] = 8'h5d;
        exp_table[312] = 8'hba;
        exp_table[313] = 8'h69;
        exp_table[314] = 8'hd2;
        exp_table[315] = 8'hb9;
        exp_table[316] = 8'h6f;
        exp_table[317] = 8'hde;
        exp_table[318] = 8'ha1;
        exp_table[319] = 8'h5f;
        exp_table[320] = 8'hbe;
        exp_table[321] = 8'h61;
        exp_table[322] = 8'hc2;
        exp_table[323] = 8'h99;
        exp_table[324] = 8'h2f;
        exp_table[325] = 8'h5e;
        exp_table[326] = 8'hbc;
        exp_table[327] = 8'h65;
        exp_table[328] = 8'hca;
        exp_table[329] = 8'h89;
        exp_table[330] = 8'h0f;
        exp_table[331] = 8'h1e;
        exp_table[332] = 8'h3c;
        exp_table[333] = 8'h78;
        exp_table[334] = 8'hf0;
        exp_table[335] = 8'hfd;
        exp_table[336] = 8'he7;
        exp_table[337] = 8'hd3;
        exp_table[338] = 8'hbb;
        exp_table[339] = 8'h6b;
        exp_table[340] = 8'hd6;
        exp_table[341] = 8'hb1;
        exp_table[342] = 8'h7f;
        exp_table[343] = 8'hfe;
        exp_table[344] = 8'he1;
        exp_table[345] = 8'hdf;
        exp_table[346] = 8'ha3;
        exp_table[347] = 8'h5b;
        exp_table[348] = 8'hb6;
        exp_table[349] = 8'h71;
        exp_table[350] = 8'he2;
        exp_table[351] = 8'hd9;
        exp_table[352] = 8'haf;
        exp_table[353] = 8'h43;
        exp_table[354] = 8'h86;
        exp_table[355] = 8'h11;
        exp_table[356] = 8'h22;
        exp_table[357] = 8'h44;
        exp_table[358] = 8'h88;
        exp_table[359] = 8'h0d;
        exp_table[360] = 8'h1a;
        exp_table[361] = 8'h34;
        exp_table[362] = 8'h68;
        exp_table[363] = 8'hd0;
        exp_table[364] = 8'hbd;
        exp_table[365] = 8'h67;
        exp_table[366] = 8'hce;
        exp_table[367] = 8'h81;
        exp_table[368] = 8'h1f;
        exp_table[369] = 8'h3e;
        exp_table[370] = 8'h7c;
        exp_table[371] = 8'hf8;
        exp_table[372] = 8'hed;
        exp_table[373] = 8'hc7;
        exp_table[374] = 8'h93;
        exp_table[375] = 8'h3b;
        exp_table[376] = 8'h76;
        exp_table[377] = 8'hec;
        exp_table[378] = 8'hc5;
        exp_table[379] = 8'h97;
        exp_table[380] = 8'h33;
        exp_table[381] = 8'h66;
        exp_table[382] = 8'hcc;
        exp_table[383] = 8'h85;
        exp_table[384] = 8'h17;
        exp_table[385] = 8'h2e;
        exp_table[386] = 8'h5c;
        exp_table[387] = 8'hb8;
        exp_table[388] = 8'h6d;
        exp_table[389] = 8'hda;
        exp_table[390] = 8'ha9;
        exp_table[391] = 8'h4f;
        exp_table[392] = 8'h9e;
        exp_table[393] = 8'h21;
        exp_table[394] = 8'h42;
        exp_table[395] = 8'h84;
        exp_table[396] = 8'h15;
        exp_table[397] = 8'h2a;
        exp_table[398] = 8'h54;
        exp_table[399] = 8'ha8;
        exp_table[400] = 8'h4d;
        exp_table[401] = 8'h9a;
        exp_table[402] = 8'h29;
        exp_table[403] = 8'h52;
        exp_table[404] = 8'ha4;
        exp_table[405] = 8'h55;
        exp_table[406] = 8'haa;
        exp_table[407] = 8'h49;
        exp_table[408] = 8'h92;
        exp_table[409] = 8'h39;
        exp_table[410] = 8'h72;
        exp_table[411] = 8'he4;
        exp_table[412] = 8'hd5;
        exp_table[413] = 8'hb7;
        exp_table[414] = 8'h73;
        exp_table[415] = 8'he6;
        exp_table[416] = 8'hd1;
        exp_table[417] = 8'hbf;
        exp_table[418] = 8'h63;
        exp_table[419] = 8'hc6;
        exp_table[420] = 8'h91;
        exp_table[421] = 8'h3f;
        exp_table[422] = 8'h7e;
        exp_table[423] = 8'hfc;
        exp_table[424] = 8'he5;
        exp_table[425] = 8'hd7;
        exp_table[426] = 8'hb3;
        exp_table[427] = 8'h7b;
        exp_table[428] = 8'hf6;
        exp_table[429] = 8'hf1;
        exp_table[430] = 8'hff;
        exp_table[431] = 8'he3;
        exp_table[432] = 8'hdb;
        exp_table[433] = 8'hab;
        exp_table[434] = 8'h4b;
        exp_table[435] = 8'h96;
        exp_table[436] = 8'h31;
        exp_table[437] = 8'h62;
        exp_table[438] = 8'hc4;
        exp_table[439] = 8'h95;
        exp_table[440] = 8'h37;
        exp_table[441] = 8'h6e;
        exp_table[442] = 8'hdc;
        exp_table[443] = 8'ha5;
        exp_table[444] = 8'h57;
        exp_table[445] = 8'hae;
        exp_table[446] = 8'h41;
        exp_table[447] = 8'h82;
        exp_table[448] = 8'h19;
        exp_table[449] = 8'h32;
        exp_table[450] = 8'h64;
        exp_table[451] = 8'hc8;
        exp_table[452] = 8'h8d;
        exp_table[453] = 8'h07;
        exp_table[454] = 8'h0e;
        exp_table[455] = 8'h1c;
        exp_table[456] = 8'h38;
        exp_table[457] = 8'h70;
        exp_table[458] = 8'he0;
        exp_table[459] = 8'hdd;
        exp_table[460] = 8'ha7;
        exp_table[461] = 8'h53;
        exp_table[462] = 8'ha6;
        exp_table[463] = 8'h51;
        exp_table[464] = 8'ha2;
        exp_table[465] = 8'h59;
        exp_table[466] = 8'hb2;
        exp_table[467] = 8'h79;
        exp_table[468] = 8'hf2;
        exp_table[469] = 8'hf9;
        exp_table[470] = 8'hef;
        exp_table[471] = 8'hc3;
        exp_table[472] = 8'h9b;
        exp_table[473] = 8'h2b;
        exp_table[474] = 8'h56;
        exp_table[475] = 8'hac;
        exp_table[476] = 8'h45;
        exp_table[477] = 8'h8a;
        exp_table[478] = 8'h09;
        exp_table[479] = 8'h12;
        exp_table[480] = 8'h24;
        exp_table[481] = 8'h48;
        exp_table[482] = 8'h90;
        exp_table[483] = 8'h3d;
        exp_table[484] = 8'h7a;
        exp_table[485] = 8'hf4;
        exp_table[486] = 8'hf5;
        exp_table[487] = 8'hf7;
        exp_table[488] = 8'hf3;
        exp_table[489] = 8'hfb;
        exp_table[490] = 8'heb;
        exp_table[491] = 8'hcb;
        exp_table[492] = 8'h8b;
        exp_table[493] = 8'h0b;
        exp_table[494] = 8'h16;
        exp_table[495] = 8'h2c;
        exp_table[496] = 8'h58;
        exp_table[497] = 8'hb0;
        exp_table[498] = 8'h7d;
        exp_table[499] = 8'hfa;
        exp_table[500] = 8'he9;
        exp_table[501] = 8'hcf;
        exp_table[502] = 8'h83;
        exp_table[503] = 8'h1b;
        exp_table[504] = 8'h36;
        exp_table[505] = 8'h6c;
        exp_table[506] = 8'hd8;
        exp_table[507] = 8'had;
        exp_table[508] = 8'h47;
        exp_table[509] = 8'h8e;
    end

    assign out = exp_table[in];

endmodule

// -----------------------------
// GF256 Logarithmic Module
// -----------------------------
module gf256_log(
    input  [7:0] data_in,
    output reg [7:0] log_out
);

always @(*) begin
    case(data_in)
        8'd1: log_out = 8'd0;
        8'd2: log_out = 8'd1;
        8'd3: log_out = 8'd25;
        8'd4: log_out = 8'd2;
        8'd5: log_out = 8'd50;
        8'd6: log_out = 8'd26;
        8'd7: log_out = 8'd198;
        8'd8: log_out = 8'd3;
        8'd9: log_out = 8'd223;
        8'd10: log_out = 8'd51;
        8'd11: log_out = 8'd238;
        8'd12: log_out = 8'd27;
        8'd13: log_out = 8'd104;
        8'd14: log_out = 8'd199;
        8'd15: log_out = 8'd75;
        8'd16: log_out = 8'd4;
        8'd17: log_out = 8'd100;
        8'd18: log_out = 8'd224;
        8'd19: log_out = 8'd14;
        8'd20: log_out = 8'd52;
        8'd21: log_out = 8'd141;
        8'd22: log_out = 8'd239;
        8'd23: log_out = 8'd129;
        8'd24: log_out = 8'd28;
        8'd25: log_out = 8'd193;
        8'd26: log_out = 8'd105;
        8'd27: log_out = 8'd248;
        8'd28: log_out = 8'd200;
        8'd29: log_out = 8'd8;
        8'd30: log_out = 8'd76;
        8'd31: log_out = 8'd113;
        8'd32: log_out = 8'd5;
        8'd33: log_out = 8'd138;
        8'd34: log_out = 8'd101;
        8'd35: log_out = 8'd47;
        8'd36: log_out = 8'd225;
        8'd37: log_out = 8'd36;
        8'd38: log_out = 8'd15;
        8'd39: log_out = 8'd33;
        8'd40: log_out = 8'd53;
        8'd41: log_out = 8'd147;
        8'd42: log_out = 8'd142;
        8'd43: log_out = 8'd218;
        8'd44: log_out = 8'd240;
        8'd45: log_out = 8'd18;
        8'd46: log_out = 8'd130;
        8'd47: log_out = 8'd69;
        8'd48: log_out = 8'd29;
        8'd49: log_out = 8'd181;
        8'd50: log_out = 8'd194;
        8'd51: log_out = 8'd125;
        8'd52: log_out = 8'd106;
        8'd53: log_out = 8'd39;
        8'd54: log_out = 8'd249;
        8'd55: log_out = 8'd185;
        8'd56: log_out = 8'd201;
        8'd57: log_out = 8'd154;
        8'd58: log_out = 8'd9;
        8'd59: log_out = 8'd120;
        8'd60: log_out = 8'd77;
        8'd61: log_out = 8'd228;
        8'd62: log_out = 8'd114;
        8'd63: log_out = 8'd166;
        8'd64: log_out = 8'd6;
        8'd65: log_out = 8'd191;
        8'd66: log_out = 8'd139;
        8'd67: log_out = 8'd98;
        8'd68: log_out = 8'd102;
        8'd69: log_out = 8'd221;
        8'd70: log_out = 8'd48;
        8'd71: log_out = 8'd253;
        8'd72: log_out = 8'd226;
        8'd73: log_out = 8'd152;
        8'd74: log_out = 8'd37;
        8'd75: log_out = 8'd179;
        8'd76: log_out = 8'd16;
        8'd77: log_out = 8'd145;
        8'd78: log_out = 8'd34;
        8'd79: log_out = 8'd136;
        8'd80: log_out = 8'd54;
        8'd81: log_out = 8'd208;
        8'd82: log_out = 8'd148;
        8'd83: log_out = 8'd206;
        8'd84: log_out = 8'd143;
        8'd85: log_out = 8'd150;
        8'd86: log_out = 8'd219;
        8'd87: log_out = 8'd189;
        8'd88: log_out = 8'd241;
        8'd89: log_out = 8'd210;
        8'd90: log_out = 8'd19;
        8'd91: log_out = 8'd92;
        8'd92: log_out = 8'd131;
        8'd93: log_out = 8'd56;
        8'd94: log_out = 8'd70;
        8'd95: log_out = 8'd64;
        8'd96: log_out = 8'd30;
        8'd97: log_out = 8'd66;
        8'd98: log_out = 8'd182;
        8'd99: log_out = 8'd163;
        8'd100: log_out = 8'd195;
        8'd101: log_out = 8'd72;
        8'd102: log_out = 8'd126;
        8'd103: log_out = 8'd110;
        8'd104: log_out = 8'd107;
        8'd105: log_out = 8'd58;
        8'd106: log_out = 8'd40;
        8'd107: log_out = 8'd84;
        8'd108: log_out = 8'd250;
        8'd109: log_out = 8'd133;
        8'd110: log_out = 8'd186;
        8'd111: log_out = 8'd61;
        8'd112: log_out = 8'd202;
        8'd113: log_out = 8'd94;
        8'd114: log_out = 8'd155;
        8'd115: log_out = 8'd159;
        8'd116: log_out = 8'd10;
        8'd117: log_out = 8'd21;
        8'd118: log_out = 8'd121;
        8'd119: log_out = 8'd43;
        8'd120: log_out = 8'd78;
        8'd121: log_out = 8'd212;
        8'd122: log_out = 8'd229;
        8'd123: log_out = 8'd172;
        8'd124: log_out = 8'd115;
        8'd125: log_out = 8'd243;
        8'd126: log_out = 8'd167;
        8'd127: log_out = 8'd87;
        8'd128: log_out = 8'd7;
        8'd129: log_out = 8'd112;
        8'd130: log_out = 8'd192;
        8'd131: log_out = 8'd247;
        8'd132: log_out = 8'd140;
        8'd133: log_out = 8'd128;
        8'd134: log_out = 8'd99;
        8'd135: log_out = 8'd13;
        8'd136: log_out = 8'd103;
        8'd137: log_out = 8'd74;
        8'd138: log_out = 8'd222;
        8'd139: log_out = 8'd237;
        8'd140: log_out = 8'd49;
        8'd141: log_out = 8'd197;
        8'd142: log_out = 8'd254;
        8'd143: log_out = 8'd24;
        8'd144: log_out = 8'd227;
        8'd145: log_out = 8'd165;
        8'd146: log_out = 8'd153;
        8'd147: log_out = 8'd119;
        8'd148: log_out = 8'd38;
        8'd149: log_out = 8'd184;
        8'd150: log_out = 8'd180;
        8'd151: log_out = 8'd124;
        8'd152: log_out = 8'd17;
        8'd153: log_out = 8'd68;
        8'd154: log_out = 8'd146;
        8'd155: log_out = 8'd217;
        8'd156: log_out = 8'd35;
        8'd157: log_out = 8'd32;
        8'd158: log_out = 8'd137;
        8'd159: log_out = 8'd46;
        8'd160: log_out = 8'd55;
        8'd161: log_out = 8'd63;
        8'd162: log_out = 8'd209;
        8'd163: log_out = 8'd91;
        8'd164: log_out = 8'd149;
        8'd165: log_out = 8'd188;
        8'd166: log_out = 8'd207;
        8'd167: log_out = 8'd205;
        8'd168: log_out = 8'd144;
        8'd169: log_out = 8'd135;
        8'd170: log_out = 8'd151;
        8'd171: log_out = 8'd178;
        8'd172: log_out = 8'd220;
        8'd173: log_out = 8'd252;
        8'd174: log_out = 8'd190;
        8'd175: log_out = 8'd97;
        8'd176: log_out = 8'd242;
        8'd177: log_out = 8'd86;
        8'd178: log_out = 8'd211;
        8'd179: log_out = 8'd171;
        8'd180: log_out = 8'd20;
        8'd181: log_out = 8'd42;
        8'd182: log_out = 8'd93;
        8'd183: log_out = 8'd158;
        8'd184: log_out = 8'd132;
        8'd185: log_out = 8'd60;
        8'd186: log_out = 8'd57;
        8'd187: log_out = 8'd83;
        8'd188: log_out = 8'd71;
        8'd189: log_out = 8'd109;
        8'd190: log_out = 8'd65;
        8'd191: log_out = 8'd162;
        8'd192: log_out = 8'd31;
        8'd193: log_out = 8'd45;
        8'd194: log_out = 8'd67;
        8'd195: log_out = 8'd216;
        8'd196: log_out = 8'd183;
        8'd197: log_out = 8'd123;
        8'd198: log_out = 8'd164;
        8'd199: log_out = 8'd118;
        8'd200: log_out = 8'd196;
        8'd201: log_out = 8'd23;
        8'd202: log_out = 8'd73;
        8'd203: log_out = 8'd236;
        8'd204: log_out = 8'd127;
        8'd205: log_out = 8'd12;
        8'd206: log_out = 8'd111;
        8'd207: log_out = 8'd246;
        8'd208: log_out = 8'd108;
        8'd209: log_out = 8'd161;
        8'd210: log_out = 8'd59;
        8'd211: log_out = 8'd82;
        8'd212: log_out = 8'd41;
        8'd213: log_out = 8'd157;
        8'd214: log_out = 8'd85;
        8'd215: log_out = 8'd170;
        8'd216: log_out = 8'd251;
        8'd217: log_out = 8'd96;
        8'd218: log_out = 8'd134;
        8'd219: log_out = 8'd177;
        8'd220: log_out = 8'd187;
        8'd221: log_out = 8'd204;
        8'd222: log_out = 8'd62;
        8'd223: log_out = 8'd90;
        8'd224: log_out = 8'd203;
        8'd225: log_out = 8'd89;
        8'd226: log_out = 8'd95;
        8'd227: log_out = 8'd176;
        8'd228: log_out = 8'd156;
        8'd229: log_out = 8'd169;
        8'd230: log_out = 8'd160;
        8'd231: log_out = 8'd81;
        8'd232: log_out = 8'd11;
        8'd233: log_out = 8'd245;
        8'd234: log_out = 8'd22;
        8'd235: log_out = 8'd235;
        8'd236: log_out = 8'd122;
        8'd237: log_out = 8'd117;
        8'd238: log_out = 8'd44;
        8'd239: log_out = 8'd215;
        8'd240: log_out = 8'd79;
        8'd241: log_out = 8'd174;
        8'd242: log_out = 8'd213;
        8'd243: log_out = 8'd233;
        8'd244: log_out = 8'd230;
        8'd245: log_out = 8'd231;
        8'd246: log_out = 8'd173;
        8'd247: log_out = 8'd232;
        8'd248: log_out = 8'd116;
        8'd249: log_out = 8'd214;
        8'd250: log_out = 8'd244;
        8'd251: log_out = 8'd234;
        8'd252: log_out = 8'd168;
        8'd253: log_out = 8'd80;
        8'd254: log_out = 8'd88;
        8'd255: log_out = 8'd175;
        default: log_out = 8'd0;  // log(0) undefined
    endcase
end
endmodule

// -----------------------------
// GF(256) Polynomial Evaluation
// -----------------------------
module poly_eval #(
    parameter NSYM = 102,
    parameter WIDTH = 8
)(
    input  wire [WIDTH*NSYM-1:0] coeffs_flat,  // Flattened version of coeffs
    input  wire [WIDTH-1:0] x,
    output reg  [WIDTH-1:0] result
);
    integer i;
    reg [WIDTH-1:0] temp_result;
    reg [WIDTH-1:0] temp_coeff;

    wire [WIDTH-1:0] mult_result;
    wire [WIDTH-1:0] add_result;

    reg [WIDTH-1:0] mult_a, mult_b;
    reg [WIDTH-1:0] add_a, add_b;

    wire [WIDTH-1:0] coeffs [0:NSYM-1];  // Internal unpacked array

    // Unpack coeffs_flat into coeffs[i]
    genvar gi;
    generate
        for (gi = 0; gi < NSYM; gi = gi + 1) begin : UNPACK
            assign coeffs[gi] = coeffs_flat[(gi+1)*WIDTH-1 -: WIDTH];
        end
    endgenerate

    // Instantiate GF(256) modules
    gf256_mult u_mult (
        .a(mult_a),
        .b(mult_b),
        .result(mult_result)
    );

    gf256_add u_add (
        .a(add_a),
        .b(add_b),
        .result(add_result)
    );

    always @(*) begin
        temp_result = 0;
        for (i = 0; i < NSYM; i = i + 1) begin
            // Multiply temp_result by x
            mult_a = temp_result;
            mult_b = x;
            #1;
            temp_result = mult_result;

            // Add with coeffs[i]
            add_a = temp_result;
            add_b = coeffs[i];
            #1;
            temp_result = add_result;
        end
        result = temp_result;
    end
endmodule

// -----------------------------
// GF(256) Polynomial Derivation
// -----------------------------
module poly_deriv_eval #(
    parameter NSYM = 102,
    parameter WIDTH = 8
)(
    input  wire [WIDTH*NSYM-1:0] coeffs_flat,
    input  wire [WIDTH-1:0] x,
    output reg  [WIDTH-1:0] result
);
    integer i;
    reg [WIDTH-1:0] power;
    reg [WIDTH-1:0] temp;

    wire [WIDTH-1:0] mult_result;
    wire [WIDTH-1:0] add_result;

    reg [WIDTH-1:0] mult_a, mult_b;
    reg [WIDTH-1:0] add_a, add_b;

    // Internal unpacked array for convenience
    wire [WIDTH-1:0] coeffs [0:NSYM-1];

    // Unpack coeffs_flat into coeffs[]
    genvar gi;
    generate
        for (gi = 0; gi < NSYM; gi = gi + 1) begin : UNPACK
            assign coeffs[gi] = coeffs_flat[(gi+1)*WIDTH-1 -: WIDTH];
        end
    endgenerate

    // Instantiate GF(256) modules
    gf256_mult u_mult (
        .a(mult_a),
        .b(mult_b),
        .result(mult_result)
    );

    gf256_add u_add (
        .a(add_a),
        .b(add_b),
        .result(add_result)
    );

    always @(*) begin
        result = 0;
        power = 1;

        for (i = 1; i < NSYM; i = i + 1) begin
            if (i[0]) begin // only odd powers
                mult_a = coeffs[i];
                mult_b = power;
                #1;
                add_a = result;
                add_b = mult_result;
                #1;
                result = add_result;
            end
            mult_a = power;
            mult_b = x;
            #1;
            power = mult_result;
        end
    end
endmodule

// -----------------------------
// warp_image (unchanged)
// -----------------------------
module warp_image #(
    parameter DATA_WIDTH = 16,
    parameter FIXED_SHIFT = 8
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire enable,
    input wire [DATA_WIDTH-1:0] x_in,
    input wire [DATA_WIDTH-1:0] y_in,
    input wire [DATA_WIDTH*9-1:0] H_flat,
    output reg [DATA_WIDTH-1:0] x_warp,
    output reg [DATA_WIDTH-1:0] y_warp,
    output reg done
);
    reg [DATA_WIDTH*2-1:0] tx, ty, tz;
    reg [DATA_WIDTH-1:0] H [0:8];
    reg [1:0] state;
    localparam IDLE = 0, COMPUTE = 1, NORMALIZE = 2, DONE = 3;
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            done <= 0;
            x_warp <= 0;
            y_warp <= 0;
        end else if (enable) begin
            case (state)
                IDLE: begin
                    if (start) begin
                        for (i = 0; i < 9; i = i + 1)
                            H[i] <= H_flat[i*DATA_WIDTH +: DATA_WIDTH];
                        state <= COMPUTE;
                        done <= 0;
                    end
                end
                COMPUTE: begin
                    tx <= H[0]*x_in + H[1]*y_in + H[2];
                    ty <= H[3]*x_in + H[4]*y_in + H[5];
                    tz <= H[6]*x_in + H[7]*y_in + H[8];
                    state <= NORMALIZE;
                end
                NORMALIZE: begin
                    if (tz != 0) begin
                        x_warp <= (tx << FIXED_SHIFT) / tz;
                        y_warp <= (ty << FIXED_SHIFT) / tz;
                    end else begin
                        x_warp <= 0;
                        y_warp <= 0;
                    end
                    state <= DONE;
                end
                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule

// -----------------------------
// Syndrome Calculation (Correct_Errors)
// Computes 2*NSYM syndromes for Reed-Solomon error correction.
// -----------------------------
module syndrome_calc #(
    parameter NSYM = 102
)(
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [8*256-1:0] codeword_flat,                     // Flattened input
    input  wire [7:0]   len,                                   // Number of codewords
    output wire [8*(2*NSYM)-1:0] syndromes_flat,               // Flattened output
    output reg          done
);

    // Internal unpacked array declarations
    wire [7:0] codeword [0:255];
    reg  [7:0] syndromes [0:(2*NSYM)-1];

    // Internal signals
    reg [7:0] i, j;
    reg [8:0] exp_index;
    wire [7:0] exp_val;
    reg [7:0] mult_a, mult_b;
    wire [7:0] mult_result;
    reg [7:0] add_a, add_b;
    wire [7:0] add_result;
    reg [1:0] state;
    integer k;

    localparam IDLE = 0, CALC = 1, WAIT = 2, DONE = 3;

    // Unpack the codeword_flat into codeword[0:255]
    genvar ci;
    generate
        for (ci = 0; ci < 256; ci = ci + 1) begin : CODEWORD_UNPACK
            assign codeword[ci] = codeword_flat[(ci+1)*8-1 -: 8];
        end
    endgenerate

    // Pack syndromes[0:2*NSYM-1] into syndromes_flat
    genvar si;
    generate
        for (si = 0; si < 2*NSYM; si = si + 1) begin : SYNDROMES_PACK
            assign syndromes_flat[(si+1)*8-1 -: 8] = syndromes[si];
        end
    endgenerate

    // GF exponentiation module
    gf256_exp exp_table (
        .in(exp_index),
        .out(exp_val)
    );

    // GF multiplication
    gf256_mult mult_inst (
        .a(mult_a),
        .b(mult_b),
        .result(mult_result)
    );

    // GF addition
    gf256_add add_inst (
        .a(add_a),
        .b(add_b),
        .result(add_result)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            i <= 0;
            j <= 0;
            done <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        i <= 0;
                        j <= 0;
                        done <= 0;
                        for (k = 0; k < 2*NSYM; k = k + 1)
                            syndromes[k] <= 8'd0;
                        state <= CALC;
                    end
                end

                CALC: begin
                    if (j < len) begin
                        exp_index <= i * j;
                        mult_a <= codeword[j];
                        mult_b <= exp_val;
                        add_a <= syndromes[i];
                        add_b <= mult_result;
                        j <= j + 1;
                        state <= WAIT;
                    end else begin
                        i <= i + 1;
                        j <= 0;
                        if (i == (2*NSYM)-1)
                            state <= DONE;
                    end
                end

                WAIT: begin
                    syndromes[i] <= add_result;
                    state <= CALC;
                end

                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

// -----------------------------
// Berlekamp Massey Algorithm for Reed-Solomon correction
// -----------------------------
module berlekamp_massey #(
    parameter NSYM = 102
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire [8*NSYM-1:0] syndrome_flat,
    output reg done,
    output wire [8*NSYM-1:0] locator_flat
);

    // Synthesizable FSM states
    localparam STATE_IDLE         = 3'd0;
    localparam STATE_DISCREPANCY  = 3'd1;
    localparam STATE_UPDATE_POLY  = 3'd2;
    localparam STATE_UPDATE_B     = 3'd3;
    localparam STATE_DONE         = 3'd4;

    reg [2:0] state;

    // Internal unpacked arrays
    wire [7:0] syndrome [0:NSYM-1];
    reg  [7:0] locator  [0:NSYM-1];

    reg [7:0] C [0:NSYM-1];
    reg [7:0] B [0:NSYM-1];
    reg [7:0] T [0:NSYM-1];

    // Flatten locator output
    genvar i_flat;
    generate
        for (i_flat = 0; i_flat < NSYM; i_flat = i_flat + 1) begin
            assign syndrome[i_flat] = syndrome_flat[(i_flat+1)*8-1 -: 8];
            assign locator_flat[(i_flat+1)*8-1 -: 8] = locator[i_flat];
        end
    endgenerate

    // GF256 multiplication
    reg [7:0] mult_a, mult_b;
    wire [7:0] mult_result;

    gf256_mult gf_mult_inst (
        .a(mult_a),
        .b(mult_b),
        .result(mult_result)
    );

    // Control variables
    reg [7:0] L, m, n, d;
    reg [7:0] temp_sum;
    reg [7:0] step_i;
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            done <= 0;
            L <= 0;
            m <= 1;
            n <= 0;
            for (i = 0; i < NSYM; i = i + 1) begin
                C[i] <= 8'd0;
                B[i] <= 8'd0;
                locator[i] <= 8'd0;
            end
            C[0] <= 8'd1;
            B[0] <= 8'd1;
        end else begin
            case (state)
                STATE_IDLE: begin
                    done <= 0;
                    if (start) begin
                        L <= 0;
                        m <= 1;
                        n <= 0;
                        state <= STATE_DISCREPANCY;
                    end
                end

                STATE_DISCREPANCY: begin
                    if (n < NSYM) begin
                        temp_sum <= syndrome[n];
                        step_i <= 1;
                        state <= STATE_UPDATE_POLY;
                    end else begin
                        for (i = 0; i < NSYM; i = i + 1)
                            locator[i] <= C[i];
                        state <= STATE_DONE;
                    end
                end

                STATE_UPDATE_POLY: begin
                    if (step_i <= L) begin
                        mult_a <= C[step_i];
                        mult_b <= syndrome[n - step_i];
                        step_i <= step_i + 1;
                        temp_sum <= temp_sum ^ mult_result;
                    end else begin
                        d <= temp_sum;
                        if (temp_sum != 0) begin
                            for (i = 0; i < NSYM; i = i + 1)
                                T[i] <= C[i];

                            step_i <= m;
                            state <= STATE_UPDATE_B;
                        end else begin
                            m <= m + 1;
                            n <= n + 1;
                            state <= STATE_DISCREPANCY;
                        end
                    end
                end

                STATE_UPDATE_B: begin
                    if (step_i < NSYM) begin
                        mult_a <= d;
                        mult_b <= B[step_i - m];
                        C[step_i] <= C[step_i] ^ mult_result;
                        step_i <= step_i + 1;
                    end else begin
                        if (2 * L <= n) begin
                            for (i = 0; i < NSYM; i = i + 1)
                                B[i] <= T[i];
                            L <= n + 1 - L;
                            m <= 1;
                        end else begin
                            m <= m + 1;
                        end
                        n <= n + 1;
                        state <= STATE_DISCREPANCY;
                    end
                end

                STATE_DONE: begin
                    done <= 1;
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule

// -----------------------------
// Chien Search module for Reed-Solomon error correction.
// -----------------------------
module chien_search #(
    parameter NSYM = 102,
    parameter N = 255,
    parameter M = 8
)(
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire [M*NSYM-1:0] lambda_flat,
    output reg  done,
    output wire [N-1:0] error_locations_flat
);

    // State definitions (replace typedef)
    localparam STATE_IDLE           = 3'd0;
    localparam STATE_POLY_EVAL_INIT = 3'd1;
    localparam STATE_POLY_EVAL_MUL  = 3'd2;
    localparam STATE_POLY_EVAL_ACCUM = 3'd3;
    localparam STATE_NEXT_INDEX     = 3'd4;
    localparam STATE_DONE           = 3'd5;

    reg [2:0] state;

    // Unflatten lambda input
    wire [7:0] lambda [0:NSYM-1];
    genvar i;
    generate
        for (i = 0; i < NSYM; i = i + 1) begin : lambda_unflatten
            assign lambda[i] = lambda_flat[(i+1)*M-1 -: M];
        end
    endgenerate

    // Declare error location bits
    reg [N-1:0] error_locations;
    assign error_locations_flat = error_locations;

    // Internal signals
    integer index;       // 0 to N-1
    integer l_index;     // 0 to NSYM

    reg [7:0] poly_eval;
    reg [7:0] alpha_power;
    reg [7:0] mult_a, mult_b;
    wire [7:0] mult_result;
    reg [7:0] lambda_val;
    reg [7:0] accum;

    gf256_mult mult_inst (
        .a(mult_a),
        .b(mult_b),
        .result(mult_result)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            done <= 0;
            index <= 0;
            l_index <= 0;
            poly_eval <= 0;
            alpha_power <= 8'd1;
            error_locations <= {N{1'b0}};
        end else begin
            case (state)
                STATE_IDLE: begin
                    done <= 0;
                    if (start) begin
                        index <= 0;
                        poly_eval <= 0;
                        alpha_power <= 8'd1;
                        state <= STATE_POLY_EVAL_INIT;
                    end
                end

                STATE_POLY_EVAL_INIT: begin
                    l_index <= 0;
                    accum <= 0;
                    state <= STATE_POLY_EVAL_MUL;
                end

                STATE_POLY_EVAL_MUL: begin
                    mult_a <= lambda[l_index];
                    mult_b <= alpha_power;
                    state <= STATE_POLY_EVAL_ACCUM;
                end

                STATE_POLY_EVAL_ACCUM: begin
                    accum <= accum ^ mult_result;

                    mult_a <= alpha_power;
                    mult_b <= 8'd2;
                    alpha_power <= mult_result;

                    l_index <= l_index + 1;
                    if (l_index < NSYM + 1)
                        state <= STATE_POLY_EVAL_MUL;
                    else begin
                        poly_eval <= accum;
                        state <= STATE_NEXT_INDEX;
                    end
                end

                STATE_NEXT_INDEX: begin
                    if (poly_eval == 0)
                        error_locations[index] <= 1'b1;
                    else
                        error_locations[index] <= 1'b0;

                    index <= index + 1;
                    if (index < N) begin
                        alpha_power <= 8'd1;
                        state <= STATE_POLY_EVAL_INIT;
                    end else begin
                        state <= STATE_DONE;
                    end
                end

                STATE_DONE: begin
                    done <= 1;
                    state <= STATE_IDLE;
                end
            endcase
        end
    end
endmodule

// -----------------------------
// Forney Algorithm module for Reed-Solomon error correction.
// Computes the error magnitudes for Reed-Solomon correction using the Forney algorithm.
// -----------------------------
module forney_algorithm #(
    parameter NSYM = 102,
    parameter SYMBOL_WIDTH = 8
)(
    input  wire                       clk,
    input  wire                       rst,
    input  wire [SYMBOL_WIDTH*NSYM-1:0] syndromes_flat,
    input  wire [SYMBOL_WIDTH*NSYM-1:0] error_locator_poly_flat,
    input  wire [SYMBOL_WIDTH*NSYM-1:0] error_evaluator_poly_flat,
    input  wire [SYMBOL_WIDTH*NSYM-1:0] error_positions_flat,
    input  wire [6:0]                num_errors,
    output reg  [SYMBOL_WIDTH*NSYM-1:0] error_magnitudes_flat
);

    // FSM state encoding
    localparam STATE_IDLE         = 4'd0;
    localparam STATE_LOAD         = 4'd1;
    localparam STATE_EVAL_Y_MUL   = 4'd2;
    localparam STATE_EVAL_Y_ACC   = 4'd3;
    localparam STATE_EVAL_DY_MUL  = 4'd4;
    localparam STATE_EVAL_DY_ACC  = 4'd5;
    localparam STATE_DIVIDE       = 4'd6;
    localparam STATE_NEXT         = 4'd7;
    localparam STATE_DONE         = 4'd8;

    reg [3:0] state;

    // Internal flat arrays
    wire [SYMBOL_WIDTH-1:0] syndromes       [0:NSYM-1];
    wire [SYMBOL_WIDTH-1:0] error_locator   [0:NSYM-1];
    wire [SYMBOL_WIDTH-1:0] error_evaluator [0:NSYM-1];
    wire [SYMBOL_WIDTH-1:0] error_positions [0:NSYM-1];
    reg  [SYMBOL_WIDTH-1:0] error_magnitudes [0:NSYM-1];

    // Unflatten inputs
    genvar idx;
    generate
        for (idx = 0; idx < NSYM; idx = idx + 1) begin : UNFLATTEN
            assign syndromes[idx]       = syndromes_flat[(idx+1)*SYMBOL_WIDTH-1 -: SYMBOL_WIDTH];
            assign error_locator[idx]   = error_locator_poly_flat[(idx+1)*SYMBOL_WIDTH-1 -: SYMBOL_WIDTH];
            assign error_evaluator[idx] = error_evaluator_poly_flat[(idx+1)*SYMBOL_WIDTH-1 -: SYMBOL_WIDTH];
            assign error_positions[idx] = error_positions_flat[(idx+1)*SYMBOL_WIDTH-1 -: SYMBOL_WIDTH];
        end
    endgenerate

    // Flatten output
    generate
        for (idx = 0; idx < NSYM; idx = idx + 1) begin : FLATTEN
            always @(*) begin
                error_magnitudes_flat[(idx+1)*SYMBOL_WIDTH-1 -: SYMBOL_WIDTH] = error_magnitudes[idx];
            end
        end
    endgenerate

    // Internal variables
    integer i, j;
    reg [7:0] x;
    reg [7:0] power_y, power_dy;
    reg [7:0] mult_a, mult_b;
    wire [7:0] mult_result;
    reg [7:0] y, dy;
    wire [7:0] div_result;

    gf256_mult gf_mult_inst (
        .a(mult_a),
        .b(mult_b),
        .result(mult_result)
    );

    gf256_div gf_div_inst (
        .a(y),
        .b(dy),
        .result(div_result)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            i <= 0;
            j <= 0;
            state <= STATE_IDLE;
            y <= 0;
            dy <= 0;
            x <= 0;
            power_y <= 1;
            power_dy <= 1;
            for (i = 0; i < NSYM; i = i + 1)
                error_magnitudes[i] <= 0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    if (num_errors > 0) begin
                        i <= 0;
                        state <= STATE_LOAD;
                    end
                end

                STATE_LOAD: begin
                    x <= error_positions[i];
                    j <= 0;
                    power_y <= 8'd1;
                    y <= 8'd0;
                    state <= STATE_EVAL_Y_MUL;
                end

                STATE_EVAL_Y_MUL: begin
                    mult_a <= error_evaluator[j];
                    mult_b <= power_y;
                    state <= STATE_EVAL_Y_ACC;
                end

                STATE_EVAL_Y_ACC: begin
                    y <= y ^ mult_result;
                    mult_a <= power_y;
                    mult_b <= x;
                    power_y <= mult_result;
                    j <= j + 1;
                    if (j < NSYM)
                        state <= STATE_EVAL_Y_MUL;
                    else begin
                        j <= 1;
                        dy <= 0;
                        power_dy <= 8'd1;
                        state <= STATE_EVAL_DY_MUL;
                    end
                end

                STATE_EVAL_DY_MUL: begin
                    if (j[0]) begin
                        mult_a <= error_locator[j];
                        mult_b <= power_dy;
                        state <= STATE_EVAL_DY_ACC;
                    end else begin
                        mult_a <= power_dy;
                        mult_b <= x;
                        state <= STATE_EVAL_DY_ACC;
                    end
                end

                STATE_EVAL_DY_ACC: begin
                    if (j[0])
                        dy <= dy ^ mult_result;

                    mult_a <= power_dy;
                    mult_b <= x;
                    power_dy <= mult_result;

                    j <= j + 1;
                    if (j < NSYM)
                        state <= STATE_EVAL_DY_MUL;
                    else
                        state <= STATE_DIVIDE;
                end

                STATE_DIVIDE: begin
                    error_magnitudes[i] <= div_result;
                    state <= STATE_NEXT;
                end

                STATE_NEXT: begin
                    i <= i + 1;
                    if (i < num_errors)
                        state <= STATE_LOAD;
                    else
                        state <= STATE_DONE;
                end

                STATE_DONE: begin
                    // Stay here until reset
                end
            endcase
        end
    end
endmodule

// -----------------------------
// Apply Corrections Module.
// Takes all of the correction above and then combines them.
// -----------------------------
module apply_corrections #(
    parameter DATA_WIDTH = 8,
    parameter NSYM = 102
)(
    input  wire                        clk,
    input  wire [DATA_WIDTH*NSYM-1:0]  received_flat,
    input  wire [DATA_WIDTH*NSYM-1:0]  error_magnitude_flat,
    input  wire [NSYM-1:0]             error_position,
    output reg  [DATA_WIDTH*NSYM-1:0]  corrected_flat
);

    wire [DATA_WIDTH-1:0] received        [0:NSYM-1];
    wire [DATA_WIDTH-1:0] error_magnitude [0:NSYM-1];
    wire                  error_pos       [0:NSYM-1];
    reg  [DATA_WIDTH-1:0] corrected       [0:NSYM-1];

    genvar idx;
    generate
        for (idx = 0; idx < NSYM; idx = idx + 1) begin : UNPACK
            assign received[idx]        = received_flat[(idx+1)*DATA_WIDTH-1 -: DATA_WIDTH];
            assign error_magnitude[idx] = error_magnitude_flat[(idx+1)*DATA_WIDTH-1 -: DATA_WIDTH];
            assign error_pos[idx]       = error_position[idx];
        end
    endgenerate

    generate
        for (idx = 0; idx < NSYM; idx = idx + 1) begin : PIPELINE
            always @(posedge clk) begin
                if (error_pos[idx])
                    corrected[idx] <= received[idx] ^ error_magnitude[idx];
                else
                    corrected[idx] <= received[idx];
            end

            always @(posedge clk) begin
                corrected_flat[(idx+1)*DATA_WIDTH-1 -: DATA_WIDTH] <= corrected[idx];
            end
        end
    endgenerate

endmodule

