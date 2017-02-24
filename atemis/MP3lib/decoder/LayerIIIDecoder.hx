/*
 * 06/01/07  Ported to ActionScript 3. By Jean-Denis Boivin 
 *			 (jeandenis.boivin@gmail.com) From Team-AtemiS.com
 *
 * 11/19/04	 1.0 moved to LGPL.
 * 
 * 18/06/01  Michael Scheerer,  Fixed bugs which causes
 *           negative indexes in method huffmann_decode and in method 
 *           dequanisize_sample.
 *
 * 16/07/01  Michael Scheerer, Catched a bug in method
 *           huffmann_decode, which causes an outOfIndexException.
 *           Cause : Indexnumber of 24 at SfBandIndex,
 *           which has only a length of 22. I have simply and dirty 
 *           fixed the index to <= 22, because I'm not really be able
 *           to fix the bug. The Indexnumber is taken from the MP3 
 *           file and the origin Ma-Player with the same code works 
 *           well.      
 * 
 * 02/19/99  Java Conversion by E.B, javalayer@javazoom.net
 *-----------------------------------------------------------------------
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as published
 *   by the Free Software Foundation; either version 2 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Library General Public License for more details.
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the Free Software
 *   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *----------------------------------------------------------------------
 */

package atemis.mP3lib.decoder;


/**
 * Class Implementing Layer 3 Decoder.
 *
 * @since 0.0
 */
class LayerIIIDecoder implements FrameDecoder
{
    private var d43 : Float = (4.0 / 3.0);
    
    public var scalefac_buffer : Array<Dynamic>;
    
    // MDM: removed, as this wasn't being used.
    //private float               CheckSumOut1d = 0.0f;
    private var CheckSumHuff : Int = 0;
    private var is_1d : Array<Dynamic>;
    private var ro : Array<Dynamic>;
    private var lr : Array<Dynamic>;
    private var out_1d : Array<Dynamic>;
    private var prevblck : Array<Dynamic>;
    private var k : Array<Dynamic>;
    private var nonzero : Array<Dynamic>;
    private var stream : Bitstream;
    private var header : Header;
    private var filter1 : SynthesisFilter;private var filter2 : SynthesisFilter;
    private var buffer : Obuffer;
    private var which_channels : Int;
    private var br : BitReserve;
    private var si : IIISideInfoT;
    
    private var III_scalefac_t : Array<Dynamic>;
    private var scalefac : Array<Dynamic>;
    // private III_scalefac_t 		scalefac;
    
    private var max_gr : Int;
    private var frame_start : Int;
    private var part2_start : Int;
    private var channels : Int;
    private var first_channel : Int;
    private var last_channel : Int;
    private var sfreq : Int;
    
    
    /**
	 * Constructor.
	 */
    // REVIEW: these constructor arguments should be moved to the
    // decodeFrame() method, where possible, so that one
    public function new(stream0 : Bitstream, header0 : Header,
            filtera : SynthesisFilter, filterb : SynthesisFilter,
            buffer0 : Obuffer, which_ch0 : Int)
    {
        var i : Int;
        var j : Int;
        
        huffcodetab.inithuff();
        is_1d = new Array<Dynamic>(SBLIMIT * SSLIMIT + 4);
        
        ro = new Array<Dynamic>(2);
        for (i in 0...ro.length)
        {
            ro[i] = new Array<Dynamic>(SBLIMIT);
            for (j in 0...ro[i].length)
            {
                ro[i][j] = new Array<Dynamic>(SSLIMIT);
            }
        }
        
        lr = new Array<Dynamic>(2);
        for (i in 0...lr.length)
        {
            lr[i] = new Array<Dynamic>(SBLIMIT);
            for (j in 0...lr[i].length)
            {
                lr[i][j] = new Array<Dynamic>(SSLIMIT);
            }
        }
        
        out_1d = new Array<Dynamic>(SBLIMIT * SSLIMIT);
        
        prevblck = new Array<Dynamic>(2);
        for (i in 0...prevblck.length)
        {
            prevblck[i] = new Array<Dynamic>(SBLIMIT * SSLIMIT);
        }
        
        k = new Array<Dynamic>(2);
        for (i in 0...k.length)
        {
            k[i] = new Array<Dynamic>(SBLIMIT * SSLIMIT);
        }
        
        nonzero = new Array<Dynamic>(2);
        
        //III_scalefact_t
        III_scalefac_t = new Array<Dynamic>(2);
        III_scalefac_t[0] = new Temporaire2();
        III_scalefac_t[1] = new Temporaire2();
        scalefac = III_scalefac_t;
        // L3TABLE INIT
        
        sfBandIndex = new Array<Dynamic>(9);  // SZD: MPEG2.5 +3 indices  
        var l0 : Array<Dynamic> = [0, 6, 12, 18, 24, 30, 36, 44, 54, 66, 80, 96, 116, 140, 168, 200, 238, 284, 336, 396, 464, 522, 576];
        var s0 : Array<Dynamic> = [0, 4, 8, 12, 18, 24, 32, 42, 56, 74, 100, 132, 174, 192];
        var l1 : Array<Dynamic> = [0, 6, 12, 18, 24, 30, 36, 44, 54, 66, 80, 96, 114, 136, 162, 194, 232, 278, 330, 394, 464, 540, 576];
        var s1 : Array<Dynamic> = [0, 4, 8, 12, 18, 26, 36, 48, 62, 80, 104, 136, 180, 192];
        var l2 : Array<Dynamic> = [0, 6, 12, 18, 24, 30, 36, 44, 54, 66, 80, 96, 116, 140, 168, 200, 238, 284, 336, 396, 464, 522, 576];
        var s2 : Array<Dynamic> = [0, 4, 8, 12, 18, 26, 36, 48, 62, 80, 104, 134, 174, 192];
        
        var l3 : Array<Dynamic> = [0, 4, 8, 12, 16, 20, 24, 30, 36, 44, 52, 62, 74, 90, 110, 134, 162, 196, 238, 288, 342, 418, 576];
        var s3 : Array<Dynamic> = [0, 4, 8, 12, 16, 22, 30, 40, 52, 66, 84, 106, 136, 192];
        var l4 : Array<Dynamic> = [0, 4, 8, 12, 16, 20, 24, 30, 36, 42, 50, 60, 72, 88, 106, 128, 156, 190, 230, 276, 330, 384, 576];
        var s4 : Array<Dynamic> = [0, 4, 8, 12, 16, 22, 28, 38, 50, 64, 80, 100, 126, 192];
        var l5 : Array<Dynamic> = [0, 4, 8, 12, 16, 20, 24, 30, 36, 44, 54, 66, 82, 102, 126, 156, 194, 240, 296, 364, 448, 550, 576];
        var s5 : Array<Dynamic> = [0, 4, 8, 12, 16, 22, 30, 42, 58, 78, 104, 138, 180, 192];
        // SZD: MPEG2.5
        var l6 : Array<Dynamic> = [0, 6, 12, 18, 24, 30, 36, 44, 54, 66, 80, 96, 116, 140, 168, 200, 238, 284, 336, 396, 464, 522, 576];
        var s6 : Array<Dynamic> = [0, 4, 8, 12, 18, 26, 36, 48, 62, 80, 104, 134, 174, 192];
        var l7 : Array<Dynamic> = [0, 6, 12, 18, 24, 30, 36, 44, 54, 66, 80, 96, 116, 140, 168, 200, 238, 284, 336, 396, 464, 522, 576];
        var s7 : Array<Dynamic> = [0, 4, 8, 12, 18, 26, 36, 48, 62, 80, 104, 134, 174, 192];
        var l8 : Array<Dynamic> = [0, 12, 24, 36, 48, 60, 72, 88, 108, 132, 160, 192, 232, 280, 336, 400, 476, 566, 568, 570, 572, 574, 576];
        var s8 : Array<Dynamic> = [0, 8, 16, 24, 36, 52, 72, 96, 124, 160, 162, 164, 166, 192];
        
        sfBandIndex[0] = new SBI(l0, s0);
        sfBandIndex[1] = new SBI(l1, s1);
        sfBandIndex[2] = new SBI(l2, s2);
        
        sfBandIndex[3] = new SBI(l3, s3);
        sfBandIndex[4] = new SBI(l4, s4);
        sfBandIndex[5] = new SBI(l5, s5);
        //SZD: MPEG2.5
        sfBandIndex[6] = new SBI(l6, s6);
        sfBandIndex[7] = new SBI(l7, s7);
        sfBandIndex[8] = new SBI(l8, s8);
        // END OF L3TABLE INIT
        
        if (reorder_table == null)
        {
            // SZD: generate LUT
            reorder_table = new Array<Dynamic>(9);
            for (i in 0...9)
            {
                reorder_table[i] = reorder2(sfBandIndex[i].s);
            }
        }
        
        // Sftable
        var ll0 : Array<Dynamic> = [0, 6, 11, 16, 21];
        var ss0 : Array<Dynamic> = [0, 6, 12];
        sftable = new Sftable(ll0, ss0);
        // END OF Sftable
        
        // scalefac_buffer
        scalefac_buffer = new Array<Dynamic>(54);
        // END OF scalefac_buffer
        
        stream = stream0;
        header = header0;
        filter1 = filtera;
        filter2 = filterb;
        buffer = buffer0;
        which_channels = which_ch0;
        
        frame_start = 0;
        channels = ((header.mode() == Header.SINGLE_CHANNEL)) ? 1 : 2;
        max_gr = ((header.version() == Header.MPEG1)) ? 2 : 1;
        
        sfreq = as3hx.Compat.parseInt(header.sample_frequency() +
                        (((header.version() == Header.MPEG1)) ? 3 : 
                        ((header.version() == Header.MPEG25_LSF)) ? 6 : 0));  // SZD  
        
        if (channels == 2)
        {
            switch (which_channels)
            {
                case OutputChannels.LEFT_CHANNEL, OutputChannels.DOWNMIX_CHANNELS:
                    first_channel = last_channel = 0;
                
                case OutputChannels.RIGHT_CHANNEL:
                    first_channel = last_channel = 1;
                
                case OutputChannels.BOTH_CHANNELS:
                    first_channel = 0;
                    last_channel = 1;
                default:
                    first_channel = 0;
                    last_channel = 1;
            }
        }
        else
        {
            first_channel = last_channel = 0;
        }
        
        for (ch in 0...2)
        {
            for (j in 0...576)
            {
                Reflect.setField(prevblck, Std.string(ch), 0.0)[j];
            }
        }
        
        nonzero[0] = nonzero[1] = 576;
        
        br = new BitReserve();
        si = new IIISideInfoT();
    }
    
    /**
    * Notify decoder that a seek is being made.
	*/
    public function seek_notify() : Void
    {
        frame_start = 0;
        for (ch in 0...2)
        {
            for (j in 0...576)
            {
                Reflect.setField(prevblck, Std.string(ch), 0.0)[j];
            }
        }
        br = new BitReserve();
    }
    
    public function decodeFrame() : Void
    {
        decode();
    }
    
    /**
    * Decode one frame, filling the buffer with the output samples.
	*/
    
    // subband samples are buffered and passed to the
    // SynthesisFilter in one go.
    private var samples1 : Array<Dynamic> = new Array<Dynamic>(32);
    private var samples2 : Array<Dynamic> = new Array<Dynamic>(32);
    
    public function decode() : Void
    {
        var nSlots : Int = header.slots();
        var flush_main : Int;
        var gr : Int;
        var ch : Int;
        var ss : Int;
        var sb : Int;
        var sb18 : Int;
        var main_data_end : Int;
        var bytes_to_discard : Int;
        var i : Int;
        
        get_side_info();
        
        for (i in 0...nSlots)
        {
            br.hputbuf(stream.get_bits(8));
        }
        
        main_data_end = br.hsstell() >>> 3;  // of previous frame  
        
        if ((flush_main = as3hx.Compat.parseInt(br.hsstell() & 7)) != 0)
        {
            br.hgetbits(8 - flush_main);
            main_data_end++;
        }
        
        bytes_to_discard = as3hx.Compat.parseInt(frame_start - main_data_end - si.main_data_begin);
        
        frame_start += nSlots;
        
        if (bytes_to_discard < 0)
        {
            return;
        }
        
        if (main_data_end > 4096)
        {
            frame_start -= 4096;
            br.rewindNbytes(4096);
        }
        
        bytes_to_discard = bytes_to_discard;
        while (bytes_to_discard > 0)
        {
            br.hgetbits(8);
            bytes_to_discard--;
        }
        
        for (gr in 0...max_gr)
        {
            for (ch in 0...channels)
            {
                part2_start = br.hsstell();
                
                if (header.version() == Header.MPEG1)
                {
                    get_scale_factors(ch, gr);
                }
                else
                {
                    // MPEG-2 LSF, SZD: MPEG-2.5 LSF
                    get_LSF_scale_factors(ch, gr);
                }
                
                huffman_decode(ch, gr);
                // System.out.println("CheckSum HuffMan = " + CheckSumHuff);
                dequantize_sample(ro[ch], ch, gr);
            }
            
            stereo(gr);
            
            if ((which_channels == OutputChannels.DOWNMIX_CHANNELS) && (channels > 1))
            {
                do_downmix();
            }
            
            for (ch in first_channel...last_channel + 1)
            {
                reorder(lr[ch], ch, gr);
                antialias(ch, gr);
                //for (int hb = 0;hb<576;hb++) CheckSumOut1d = CheckSumOut1d + out_1d[hb];
                //System.out.println("CheckSumOut1d = "+CheckSumOut1d);
                
                hybrid(ch, gr);
                
                //for (int hb = 0;hb<576;hb++) CheckSumOut1d = CheckSumOut1d + out_1d[hb];
                //System.out.println("CheckSumOut1d = "+CheckSumOut1d);
                
                sb18 = 18;
                while (sb18 < 576)
                {
                    // Frequency inversion
                    ss = 1;
                    while (ss < SSLIMIT)
                    {
                        out_1d[sb18 + ss] = -out_1d[sb18 + ss];
                        ss += 2;
                    }
                    sb18 += 36;
                }
                
                if ((ch == 0) || (which_channels == OutputChannels.RIGHT_CHANNEL))
                {
                    for (ss in 0...SSLIMIT)
                    {
                        // Polyphase synthesis
                        sb = 0;
                        sb18 = 0;
                        while (sb18 < 576)
                        {
                            samples1[sb] = out_1d[sb18 + ss];
                            //filter1.input_sample(out_1d[sb18+ss], sb);
                            sb++;
                            sb18 += 18;
                        }
                        filter1.input_samples(samples1);
                        filter1.calculate_pcm_samples(buffer);
                    }
                }
                else
                {
                    for (ss in 0...SSLIMIT)
                    {
                        // Polyphase synthesis
                        sb = 0;
                        sb18 = 0;
                        while (sb18 < 576)
                        {
                            samples2[sb] = out_1d[sb18 + ss];
                            //filter2.input_sample(out_1d[sb18+ss], sb);
                            sb++;
                            sb18 += 18;
                        }
                        filter2.input_samples(samples2);
                        filter2.calculate_pcm_samples(buffer);
                    }
                }
            }
        }  // granule  
        
        
        // System.out.println("Counter = ................................."+counter);
        //if (counter <  609)
        //{
        counter++;
        buffer.write_buffer(1);
    }
    
    /**
	 * Reads the side info from the stream, assuming the entire.
	 * frame has been read already.
	 * Mono   : 136 bits (= 17 bytes)
     * Stereo : 256 bits (= 32 bytes)
	 */
    private function get_side_info() : Bool
    {
        var ch : Int;
        var gr : Int;
        if (header.version() == Header.MPEG1)
        {
            si.main_data_begin = stream.get_bits(9);
            if (channels == 1)
            {
                si.private_bits = stream.get_bits(5);
            }
            else
            {
                si.private_bits = stream.get_bits(3);
            }
            
            for (ch in 0...channels)
            {
                si.ch[ch].scfsi[0] = stream.get_bits(1);
                si.ch[ch].scfsi[1] = stream.get_bits(1);
                si.ch[ch].scfsi[2] = stream.get_bits(1);
                si.ch[ch].scfsi[3] = stream.get_bits(1);
            }
            
            for (gr in 0...2)
            {
                for (ch in 0...channels)
                {
                    si.ch[ch].gr[gr].part2_3_length = stream.get_bits(12);
                    si.ch[ch].gr[gr].big_values = stream.get_bits(9);
                    si.ch[ch].gr[gr].global_gain = stream.get_bits(8);
                    si.ch[ch].gr[gr].scalefac_compress = stream.get_bits(4);
                    si.ch[ch].gr[gr].window_switching_flag = stream.get_bits(1);
                    if ((si.ch[ch].gr[gr].window_switching_flag) != 0)
                    {
                        si.ch[ch].gr[gr].block_type = stream.get_bits(2);
                        si.ch[ch].gr[gr].mixed_block_flag = stream.get_bits(1);
                        
                        si.ch[ch].gr[gr].table_select[0] = stream.get_bits(5);
                        si.ch[ch].gr[gr].table_select[1] = stream.get_bits(5);
                        
                        si.ch[ch].gr[gr].subblock_gain[0] = stream.get_bits(3);
                        si.ch[ch].gr[gr].subblock_gain[1] = stream.get_bits(3);
                        si.ch[ch].gr[gr].subblock_gain[2] = stream.get_bits(3);
                        
                        // Set region_count parameters since they are implicit in this case.
                        
                        if (si.ch[ch].gr[gr].block_type == 0)
                        {
                            //	 Side info bad: block_type == 0 in split block
                            return false;
                        }
                        else
                        {
                            if (si.ch[ch].gr[gr].block_type == 2 && si.ch[ch].gr[gr].mixed_block_flag == 0)
                            {
                                si.ch[ch].gr[gr].region0_count = 8;
                            }
                            else
                            {
                                si.ch[ch].gr[gr].region0_count = 7;
                            }
                        }
                        si.ch[ch].gr[gr].region1_count = 20 -
                                si.ch[ch].gr[gr].region0_count;
                    }
                    else
                    {
                        si.ch[ch].gr[gr].table_select[0] = stream.get_bits(5);
                        si.ch[ch].gr[gr].table_select[1] = stream.get_bits(5);
                        si.ch[ch].gr[gr].table_select[2] = stream.get_bits(5);
                        si.ch[ch].gr[gr].region0_count = stream.get_bits(4);
                        si.ch[ch].gr[gr].region1_count = stream.get_bits(3);
                        si.ch[ch].gr[gr].block_type = 0;
                    }
                    si.ch[ch].gr[gr].preflag = stream.get_bits(1);
                    si.ch[ch].gr[gr].scalefac_scale = stream.get_bits(1);
                    si.ch[ch].gr[gr].count1table_select = stream.get_bits(1);
                }
            }
        }
        else
        {
            // MPEG-2 LSF, SZD: MPEG-2.5 LSF
            
            si.main_data_begin = stream.get_bits(8);
            if (channels == 1)
            {
                si.private_bits = stream.get_bits(1);
            }
            else
            {
                si.private_bits = stream.get_bits(2);
            }
            
            for (ch in 0...channels)
            {
                si.ch[ch].gr[0].part2_3_length = stream.get_bits(12);
                si.ch[ch].gr[0].big_values = stream.get_bits(9);
                si.ch[ch].gr[0].global_gain = stream.get_bits(8);
                si.ch[ch].gr[0].scalefac_compress = stream.get_bits(9);
                si.ch[ch].gr[0].window_switching_flag = stream.get_bits(1);
                
                if ((si.ch[ch].gr[0].window_switching_flag) != 0)
                {
                    si.ch[ch].gr[0].block_type = stream.get_bits(2);
                    si.ch[ch].gr[0].mixed_block_flag = stream.get_bits(1);
                    si.ch[ch].gr[0].table_select[0] = stream.get_bits(5);
                    si.ch[ch].gr[0].table_select[1] = stream.get_bits(5);
                    
                    si.ch[ch].gr[0].subblock_gain[0] = stream.get_bits(3);
                    si.ch[ch].gr[0].subblock_gain[1] = stream.get_bits(3);
                    si.ch[ch].gr[0].subblock_gain[2] = stream.get_bits(3);
                    
                    // Set region_count parameters since they are implicit in this case.
                    
                    if (si.ch[ch].gr[0].block_type == 0)
                    {
                        // Side info bad: block_type == 0 in split block
                        return false;
                    }
                    else
                    {
                        if (si.ch[ch].gr[0].block_type == 2 && si.ch[ch].gr[0].mixed_block_flag == 0)
                        {
                            si.ch[ch].gr[0].region0_count = 8;
                        }
                        else
                        {
                            si.ch[ch].gr[0].region0_count = 7;
                            si.ch[ch].gr[0].region1_count = 20 -
                                    si.ch[ch].gr[0].region0_count;
                        }
                    }
                }
                else
                {
                    si.ch[ch].gr[0].table_select[0] = stream.get_bits(5);
                    si.ch[ch].gr[0].table_select[1] = stream.get_bits(5);
                    si.ch[ch].gr[0].table_select[2] = stream.get_bits(5);
                    si.ch[ch].gr[0].region0_count = stream.get_bits(4);
                    si.ch[ch].gr[0].region1_count = stream.get_bits(3);
                    si.ch[ch].gr[0].block_type = 0;
                }
                
                si.ch[ch].gr[0].scalefac_scale = stream.get_bits(1);
                si.ch[ch].gr[0].count1table_select = stream.get_bits(1);
            }
        }  // if (header.version() == MPEG1)  
        return true;
    }
    
    /**
	 *
	 */
    private function get_scale_factors(ch : Int, gr : Int) : Void
    {
        var sfb : Int;
        var window : Int;
        var gr_info : GrInfoS = (si.ch[ch].gr[gr]);
        var scale_comp : Int = gr_info.scalefac_compress;
        var length0 : Int = slen[0][scale_comp];
        var length1 : Int = slen[1][scale_comp];
        
        if ((gr_info.window_switching_flag != 0) && (gr_info.block_type == 2))
        {
            if ((gr_info.mixed_block_flag) != 0)
            {
                // MIXED
                for (sfb in 0...8)
                {
                    scalefac[ch].l[sfb] = br.hgetbits(
                                    slen[0][gr_info.scalefac_compress]
                    );
                }
                for (sfb in 3...6)
                {
                    for (window in 0...3)
                    {
                        scalefac[ch].s[window][sfb] = br.hgetbits(
                                        slen[0][gr_info.scalefac_compress]
                    );
                    }
                }
                for (sfb in 6...12)
                {
                    for (window in 0...3)
                    {
                        scalefac[ch].s[window][sfb] = br.hgetbits(
                                        slen[1][gr_info.scalefac_compress]
                    );
                    }
                }
                for (sfb in 12...3)
                {
                    scalefac[ch].s[window][sfb] = 0;
                }
            }
            else
            {
                // SHORT
                
                scalefac[ch].s[0][0] = br.hgetbits(length0);
                scalefac[ch].s[1][0] = br.hgetbits(length0);
                scalefac[ch].s[2][0] = br.hgetbits(length0);
                scalefac[ch].s[0][1] = br.hgetbits(length0);
                scalefac[ch].s[1][1] = br.hgetbits(length0);
                scalefac[ch].s[2][1] = br.hgetbits(length0);
                scalefac[ch].s[0][2] = br.hgetbits(length0);
                scalefac[ch].s[1][2] = br.hgetbits(length0);
                scalefac[ch].s[2][2] = br.hgetbits(length0);
                scalefac[ch].s[0][3] = br.hgetbits(length0);
                scalefac[ch].s[1][3] = br.hgetbits(length0);
                scalefac[ch].s[2][3] = br.hgetbits(length0);
                scalefac[ch].s[0][4] = br.hgetbits(length0);
                scalefac[ch].s[1][4] = br.hgetbits(length0);
                scalefac[ch].s[2][4] = br.hgetbits(length0);
                scalefac[ch].s[0][5] = br.hgetbits(length0);
                scalefac[ch].s[1][5] = br.hgetbits(length0);
                scalefac[ch].s[2][5] = br.hgetbits(length0);
                scalefac[ch].s[0][6] = br.hgetbits(length1);
                scalefac[ch].s[1][6] = br.hgetbits(length1);
                scalefac[ch].s[2][6] = br.hgetbits(length1);
                scalefac[ch].s[0][7] = br.hgetbits(length1);
                scalefac[ch].s[1][7] = br.hgetbits(length1);
                scalefac[ch].s[2][7] = br.hgetbits(length1);
                scalefac[ch].s[0][8] = br.hgetbits(length1);
                scalefac[ch].s[1][8] = br.hgetbits(length1);
                scalefac[ch].s[2][8] = br.hgetbits(length1);
                scalefac[ch].s[0][9] = br.hgetbits(length1);
                scalefac[ch].s[1][9] = br.hgetbits(length1);
                scalefac[ch].s[2][9] = br.hgetbits(length1);
                scalefac[ch].s[0][10] = br.hgetbits(length1);
                scalefac[ch].s[1][10] = br.hgetbits(length1);
                scalefac[ch].s[2][10] = br.hgetbits(length1);
                scalefac[ch].s[0][11] = br.hgetbits(length1);
                scalefac[ch].s[1][11] = br.hgetbits(length1);
                scalefac[ch].s[2][11] = br.hgetbits(length1);
                scalefac[ch].s[0][12] = 0;
                scalefac[ch].s[1][12] = 0;
                scalefac[ch].s[2][12] = 0;
            }
        }
        else
        {
            // LONG types 0,1,3
            
            if ((si.ch[ch].scfsi[0] == 0) || (gr == 0))
            {
                scalefac[ch].l[0] = br.hgetbits(length0);
                scalefac[ch].l[1] = br.hgetbits(length0);
                scalefac[ch].l[2] = br.hgetbits(length0);
                scalefac[ch].l[3] = br.hgetbits(length0);
                scalefac[ch].l[4] = br.hgetbits(length0);
                scalefac[ch].l[5] = br.hgetbits(length0);
            }
            if ((si.ch[ch].scfsi[1] == 0) || (gr == 0))
            {
                scalefac[ch].l[6] = br.hgetbits(length0);
                scalefac[ch].l[7] = br.hgetbits(length0);
                scalefac[ch].l[8] = br.hgetbits(length0);
                scalefac[ch].l[9] = br.hgetbits(length0);
                scalefac[ch].l[10] = br.hgetbits(length0);
            }
            if ((si.ch[ch].scfsi[2] == 0) || (gr == 0))
            {
                scalefac[ch].l[11] = br.hgetbits(length1);
                scalefac[ch].l[12] = br.hgetbits(length1);
                scalefac[ch].l[13] = br.hgetbits(length1);
                scalefac[ch].l[14] = br.hgetbits(length1);
                scalefac[ch].l[15] = br.hgetbits(length1);
            }
            if ((si.ch[ch].scfsi[3] == 0) || (gr == 0))
            {
                scalefac[ch].l[16] = br.hgetbits(length1);
                scalefac[ch].l[17] = br.hgetbits(length1);
                scalefac[ch].l[18] = br.hgetbits(length1);
                scalefac[ch].l[19] = br.hgetbits(length1);
                scalefac[ch].l[20] = br.hgetbits(length1);
            }
            
            scalefac[ch].l[21] = 0;
            scalefac[ch].l[22] = 0;
        }
    }
    
    /**
	 *
	 */
    // MDM: new_slen is fully initialized before use, no need
    // to reallocate array.
    private var new_slen : Array<Dynamic> = new Array<Dynamic>(4);
    
    private function get_LSF_scale_data(ch : Int, gr : Int) : Void
    {
        var scalefac_comp : Int;
        var int_scalefac_comp : Int;
        var mode_ext : Int = header.mode_extension();
        var m : Int;
        var blocktypenumber : Int;
        var blocknumber : Int = 0;
        
        var gr_info : GrInfoS = (si.ch[ch].gr[gr]);
        
        scalefac_comp = gr_info.scalefac_compress;
        
        if (gr_info.block_type == 2)
        {
            if (gr_info.mixed_block_flag == 0)
            {
                blocktypenumber = 1;
            }
            else
            {
                if (gr_info.mixed_block_flag == 1)
                {
                    blocktypenumber = 2;
                }
                else
                {
                    blocktypenumber = 0;
                }
            }
        }
        else
        {
            blocktypenumber = 0;
        }
        
        if (!(((mode_ext == 1) || (mode_ext == 3)) && (ch == 1)))
        {
            if (scalefac_comp < 400)
            {
                new_slen[0] = (scalefac_comp >>> 4) / 5;
                new_slen[1] = (scalefac_comp >>> 4) % 5;
                new_slen[2] = (scalefac_comp & 0xF) >>> 2;
                new_slen[3] = (scalefac_comp & 3);
                si.ch[ch].gr[gr].preflag = 0;
                blocknumber = 0;
            }
            else
            {
                if (scalefac_comp < 500)
                {
                    new_slen[0] = ((scalefac_comp - 400) >>> 2) / 5;
                    new_slen[1] = ((scalefac_comp - 400) >>> 2) % 5;
                    new_slen[2] = as3hx.Compat.parseInt(scalefac_comp - 400) & 3;
                    new_slen[3] = 0;
                    si.ch[ch].gr[gr].preflag = 0;
                    blocknumber = 1;
                }
                else
                {
                    if (scalefac_comp < 512)
                    {
                        new_slen[0] = (scalefac_comp - 500) / 3;
                        new_slen[1] = (scalefac_comp - 500) % 3;
                        new_slen[2] = 0;
                        new_slen[3] = 0;
                        si.ch[ch].gr[gr].preflag = 1;
                        blocknumber = 2;
                    }
                }
            }
        }
        
        if (((mode_ext == 1) || (mode_ext == 3)) && (ch == 1))
        {
            int_scalefac_comp = scalefac_comp >>> 1;
            
            if (int_scalefac_comp < 180)
            {
                new_slen[0] = int_scalefac_comp / 36;
                new_slen[1] = (int_scalefac_comp % 36) / 6;
                new_slen[2] = (int_scalefac_comp % 36) % 6;
                new_slen[3] = 0;
                si.ch[ch].gr[gr].preflag = 0;
                blocknumber = 3;
            }
            else
            {
                if (int_scalefac_comp < 244)
                {
                    new_slen[0] = (as3hx.Compat.parseInt(int_scalefac_comp - 180) & 0x3F) >>> 4;
                    new_slen[1] = (as3hx.Compat.parseInt(int_scalefac_comp - 180) & 0xF) >>> 2;
                    new_slen[2] = as3hx.Compat.parseInt(int_scalefac_comp - 180) & 3;
                    new_slen[3] = 0;
                    si.ch[ch].gr[gr].preflag = 0;
                    blocknumber = 4;
                }
                else
                {
                    if (int_scalefac_comp < 255)
                    {
                        new_slen[0] = (int_scalefac_comp - 244) / 3;
                        new_slen[1] = (int_scalefac_comp - 244) % 3;
                        new_slen[2] = 0;
                        new_slen[3] = 0;
                        si.ch[ch].gr[gr].preflag = 0;
                        blocknumber = 5;
                    }
                }
            }
        }
        
        for (x in 0...45)
        {
            // why 45, not 54?
            Reflect.setField(scalefac_buffer, Std.string(x), 0);
        }
        
        m = 0;
        for (i in 0...4)
        {
            for (j in 0...nr_of_sfb_block[blocknumber][blocktypenumber][i])
            {
                scalefac_buffer[m] = ((new_slen[i] == 0)) ? 0 : 
                        br.hgetbits(new_slen[i]);
                m++;
            }
        }
    }
    
    /**
	 *
	 */
    private function get_LSF_scale_factors(ch : Int, gr : Int) : Void
    {
        var m : Int = 0;
        var sfb : Int;
        var window : Int;
        var gr_info : GrInfoS = (si.ch[ch].gr[gr]);
        
        get_LSF_scale_data(ch, gr);
        
        if ((gr_info.window_switching_flag != 0) && (gr_info.block_type == 2))
        {
            if (gr_info.mixed_block_flag != 0)
            {
                // MIXED
                for (sfb in 0...8)
                {
                    scalefac[ch].l[sfb] = scalefac_buffer[m];
                    m++;
                }
                for (sfb in 3...12)
                {
                    for (window in 0...3)
                    {
                        scalefac[ch].s[window][sfb] = scalefac_buffer[m];
                        m++;
                    }
                }
                for (window in 0...3)
                {
                    scalefac[ch].s[window][12] = 0;
                }
            }
            else
            {
                // SHORT
                
                for (sfb in 0...12)
                {
                    for (window in 0...3)
                    {
                        scalefac[ch].s[window][sfb] = scalefac_buffer[m];
                        m++;
                    }
                }
                
                for (window in 0...3)
                {
                    scalefac[ch].s[window][12] = 0;
                }
            }
        }
        else
        {
            // LONG types 0,1,3
            
            for (sfb in 0...21)
            {
                scalefac[ch].l[sfb] = scalefac_buffer[m];
                m++;
            }
            scalefac[ch].l[21] = 0;  // Jeff  
            scalefac[ch].l[22] = 0;
        }
    }
    
    /**
	 *
	 */
    private var x : Array<Dynamic> = [0];
    private var y : Array<Dynamic> = [0];
    private var v : Array<Dynamic> = [0];
    private var w : Array<Dynamic> = [0];
    private function huffman_decode(ch : Int, gr : Int) : Void
    {
        x[0] = 0;
        y[0] = 0;
        v[0] = 0;
        w[0] = 0;
        
        var part2_3_end : Int = as3hx.Compat.parseInt(part2_start + si.ch[ch].gr[gr].part2_3_length);
        var num_bits : Int;
        var region1Start : Int;
        var region2Start : Int;
        var index : Int;
        
        var buf : Int;
        var buf1 : Int;
        
        var h : Huffcodetab;
        
        // Find region boundary for short block case
        
        if (((si.ch[ch].gr[gr].window_switching_flag) != 0) &&
            (si.ch[ch].gr[gr].block_type == 2))
        {
            // Region2.
            //MS: Extrahandling for 8KHZ
            region1Start = ((sfreq == 8)) ? 72 : 36;  // sfb[9/3]*3=36 or in case 8KHZ = 72  
            region2Start = 576;
        }
        else
        {
            // Find region boundary for long block case
            
            buf = as3hx.Compat.parseInt(si.ch[ch].gr[gr].region0_count + 1);
            buf1 = as3hx.Compat.parseInt(buf + si.ch[ch].gr[gr].region1_count + 1);
            
            if (buf1 > sfBandIndex[sfreq].l.length - 1)
            {
                buf1 = as3hx.Compat.parseInt(sfBandIndex[sfreq].l.length - 1);
            }
            
            region1Start = sfBandIndex[sfreq].l[buf];
            region2Start = sfBandIndex[sfreq].l[buf1];
        }
        
        index = 0;
        // Read bigvalues area
        var i : Int = 0;
        while (i < (si.ch[ch].gr[gr].big_values << 1))
        {
            if (i < region1Start)
            {
                h = huffcodetab.ht[si.ch[ch].gr[gr].table_select[0]];
            }
            else
            {
                if (i < region2Start)
                {
                    h = huffcodetab.ht[si.ch[ch].gr[gr].table_select[1]];
                }
                else
                {
                    h = huffcodetab.ht[si.ch[ch].gr[gr].table_select[2]];
                }
            }
            
            huffcodetab.huffman_decoder(h, x, y, v, w, br);
            //if (index >= is_1d.length) System.out.println("i0="+i+"/"+(si.ch[ch].gr[gr].big_values<<1)+" Index="+index+" is_1d="+is_1d.length);
            
            is_1d[index++] = x[0];
            is_1d[index++] = y[0];
            
            CheckSumHuff = as3hx.Compat.parseInt(CheckSumHuff + x[0] + y[0]);
            i += 2;
        }
        
        // Read count1 area
        h = huffcodetab.ht[si.ch[ch].gr[gr].count1table_select + 32];
        num_bits = br.hsstell();
        
        while ((num_bits < part2_3_end) && (index < 576))
        {
            huffcodetab.huffman_decoder(h, x, y, v, w, br);
            
            is_1d[index++] = v[0];
            is_1d[index++] = w[0];
            is_1d[index++] = x[0];
            is_1d[index++] = y[0];
            CheckSumHuff = as3hx.Compat.parseInt(CheckSumHuff + v[0] + w[0] + x[0] + y[0]);
            // System.out.println("v = "+v[0]+" w = "+w[0]);
            // System.out.println("x = "+x[0]+" y = "+y[0]);
            num_bits = br.hsstell();
        }
        
        if (num_bits > part2_3_end)
        {
            br.rewindNbits(num_bits - part2_3_end);
            index -= 4;
        }
        
        num_bits = br.hsstell();
        
        // Dismiss stuffing bits
        if (num_bits < part2_3_end)
        {
            br.hgetbits(part2_3_end - num_bits);
        }
        
        // Zero out rest
        
        if (index < 576)
        {
            nonzero[ch] = index;
        }
        else
        {
            nonzero[ch] = 576;
        }
        
        if (index < 0)
        {
            index = 0;
        }
        
        // may not be necessary
        for (index in index...576)
        {
            is_1d[index] = 0;
        }
    }
    
    /**
	 *
	 */
    private function i_stereo_k_values(is_pos : Int, io_type : Int, i : Int) : Void
    {
        if (is_pos == 0)
        {
            k[0][i] = 1.0;
            k[1][i] = 1.0;
        }
        else
        {
            if ((is_pos & 1) != 0)
            {
                k[0][i] = io[io_type][(is_pos + 1) >>> 1];
                k[1][i] = 1.0;
            }
            else
            {
                k[0][i] = 1.0;
                k[1][i] = io[io_type][is_pos >>> 1];
            }
        }
    }
    
    /**
	 *
	 */
    private function dequantize_sample(xr : Array<Dynamic>, ch : Int, gr : Int) : Void
    {
        var gr_info : GrInfoS = (si.ch[ch].gr[gr]);
        var cb : Int = 0;
        var next_cb_boundary : Int;
        var cb_begin : Int = 0;
        var cb_width : Int = 0;
        var index : Int = 0;
        var t_index : Int;
        var j : Int;
        var g_gain : Float;
        var xr_1d : Array<Dynamic> = xr;
        
        var reste : Int;
        var quotien : Int;
        
        // choose correct scalefactor band per block type, initalize boundary
        
        if ((gr_info.window_switching_flag != 0) && (gr_info.block_type == 2))
        {
            if (gr_info.mixed_block_flag != 0)
            {
                next_cb_boundary = sfBandIndex[sfreq].l[1];
            }
            else
            {
                // LONG blocks: 0,1,3{
                    cb_width = sfBandIndex[sfreq].s[1];
                    next_cb_boundary = as3hx.Compat.parseInt((cb_width << 2) - cb_width);
                    cb_begin = 0;
                }
            }
        }
        else
        {
            next_cb_boundary = sfBandIndex[sfreq].l[1];
        }
        
        // Compute overall (global) scaling.
        
        g_gain = Math.pow(2.0, 0.25 * (gr_info.global_gain - 210.0));
        
        for (j in 0...nonzero[ch])
        {
            // Modif E.B 02/22/99
            reste = as3hx.Compat.parseInt(j % SSLIMIT);
            quotien = as3hx.Compat.parseInt((j - reste) / SSLIMIT);
            if (is_1d[j] == 0)
            {
                xr_1d[quotien][reste] = 0.0;
            }
            else
            {
                var abv : Int = is_1d[j];
                // Pow Array fix (11/17/04)
                if (abv < t_43.length)
                {
                    if (is_1d[j] > 0)
                    {
                        xr_1d[quotien][reste] = g_gain * t_43[abv];
                    }
                    else
                    {
                        if (-abv < t_43.length)
                        {
                            xr_1d[quotien][reste] = -g_gain * t_43[-abv];
                        }
                        else
                        {
                            xr_1d[quotien][reste] = -g_gain * Math.pow(-abv, d43);
                        }
                    }
                }
                else
                {
                    if (is_1d[j] > 0)
                    {
                        xr_1d[quotien][reste] = g_gain * Math.pow(abv, d43);
                    }
                    else
                    {
                        xr_1d[quotien][reste] = -g_gain * Math.pow(-abv, d43);
                    }
                }
            }
        }
        
        // apply formula per block type
        for (j in 0...nonzero[ch])
        {
            // Modif E.B 02/22/99
            reste = as3hx.Compat.parseInt(j % SSLIMIT);
            quotien = as3hx.Compat.parseInt((j - reste) / SSLIMIT);
            
            if (index == next_cb_boundary)
            {
                /* Adjust critical band boundary */
                if ((gr_info.window_switching_flag != 0) && (gr_info.block_type == 2))
                {
                    if (gr_info.mixed_block_flag != 0)
                    {
                        if (index == sfBandIndex[sfreq].l[8])
                        {
                            next_cb_boundary = sfBandIndex[sfreq].s[4];
                            next_cb_boundary = as3hx.Compat.parseInt((next_cb_boundary << 2) -
                                            next_cb_boundary);
                            cb = 3;
                            cb_width = as3hx.Compat.parseInt(sfBandIndex[sfreq].s[4] -
                                            sfBandIndex[sfreq].s[3]);
                            
                            cb_begin = sfBandIndex[sfreq].s[3];
                            cb_begin = as3hx.Compat.parseInt((cb_begin << 2) - cb_begin);
                        }
                        else
                        {
                            if (index < sfBandIndex[sfreq].l[8])
                            {
                                next_cb_boundary = sfBandIndex[sfreq].l[(++cb) + 1];
                            }
                            else
                            {
                                next_cb_boundary = sfBandIndex[sfreq].s[(++cb) + 1];
                                next_cb_boundary = as3hx.Compat.parseInt((next_cb_boundary << 2) -
                                                next_cb_boundary);
                                
                                cb_begin = sfBandIndex[sfreq].s[cb];
                                cb_width = as3hx.Compat.parseInt(sfBandIndex[sfreq].s[cb + 1] -
                                                cb_begin);
                                cb_begin = as3hx.Compat.parseInt((cb_begin << 2) - cb_begin);
                            }
                        }
                    }
                    else
                    {
                        next_cb_boundary = sfBandIndex[sfreq].s[(++cb) + 1];
                        next_cb_boundary = as3hx.Compat.parseInt((next_cb_boundary << 2) -
                                        next_cb_boundary);
                        
                        cb_begin = sfBandIndex[sfreq].s[cb];
                        cb_width = as3hx.Compat.parseInt(sfBandIndex[sfreq].s[cb + 1] -
                                        cb_begin);
                        cb_begin = as3hx.Compat.parseInt((cb_begin << 2) - cb_begin);
                    }
                }
                else
                {
                    // long blocks
                    
                    next_cb_boundary = sfBandIndex[sfreq].l[(++cb) + 1];
                }
            }
            
            // Do long/short dependent scaling operations
            var idx : Int;
            if ((gr_info.window_switching_flag != 0) &&
                (((gr_info.block_type == 2) && (gr_info.mixed_block_flag == 0)) ||
                ((gr_info.block_type == 2) && (gr_info.mixed_block_flag != 0) && (j >= 36))))
            {
                t_index = as3hx.Compat.parseInt((index - cb_begin) / cb_width);
                /*            xr[sb][ss] *= pow(2.0, ((-2.0 * gr_info.subblock_gain[t_index])
	                                    -(0.5 * (1.0 + gr_info.scalefac_scale)
	                                      * scalefac[ch].s[t_index][cb]))); */
                idx = scalefac[ch].s[t_index][cb]
                        << gr_info.scalefac_scale;
                idx += (gr_info.subblock_gain[t_index] << 2);
                
                xr_1d[quotien][reste] *= two_to_negative_half_pow[idx];
            }
            else
            {
                // LONG block types 0,1,3 & 1st 2 subbands of switched blocks
                /*				xr[sb][ss] *= pow(2.0, -0.5 * (1.0+gr_info.scalefac_scale)
														 * (scalefac[ch].l[cb]
														 + gr_info.preflag * pretab[cb])); */
                idx = scalefac[ch].l[cb];
                
                if (gr_info.preflag != 0)
                {
                    idx += pretab[cb];
                }
                
                idx = idx << gr_info.scalefac_scale;
                xr_1d[quotien][reste] *= two_to_negative_half_pow[idx];
            }
            index++;
        }
        
        for (j in nonzero[ch]...576)
        {
            // Modif E.B 02/22/99
            reste = as3hx.Compat.parseInt(j % SSLIMIT);
            quotien = as3hx.Compat.parseInt((j - reste) / SSLIMIT);
            if (reste < 0)
            {
                reste = 0;
            }
            if (quotien < 0)
            {
                quotien = 0;
            }
            xr_1d[quotien][reste] = 0.0;
        }
        
        return;
    }
    
    /**
	 *
	 */
    private function reorder(xr : Array<Dynamic>, ch : Int, gr : Int) : Void
    {
        var gr_info : GrInfoS = (si.ch[ch].gr[gr]);
        var freq : Int;
        var freq3 : Int;
        var index : Int;
        var sfb : Int;
        var sfb_start : Int;
        var sfb_lines : Int;
        var src_line : Int;
        var des_line : Int;
        var xr_1d : Array<Dynamic> = xr;
        
        var reste : Int;
        var quotien : Int;
        
        if ((gr_info.window_switching_flag != 0) && (gr_info.block_type == 2))
        {
            for (index in 0...576)
            {
                out_1d[index] = 0.0;
            }
            
            if (gr_info.mixed_block_flag != 0)
            {
                // NO REORDER FOR LOW 2 SUBBANDS
                for (index in 0...36)
                {
                    // Modif E.B 02/22/99
                    reste = as3hx.Compat.parseInt(index % SSLIMIT);
                    quotien = as3hx.Compat.parseInt((index - reste) / SSLIMIT);
                    out_1d[index] = xr_1d[quotien][reste];
                }
                // REORDERING FOR REST SWITCHED SHORT
                /*for( sfb=3,sfb_start=sfBandIndex[sfreq].s[3],
						 sfb_lines=sfBandIndex[sfreq].s[4] - sfb_start;
						 sfb < 13; sfb++,sfb_start = sfBandIndex[sfreq].s[sfb],
						 sfb_lines = sfBandIndex[sfreq].s[sfb+1] - sfb_start )
						 {*/
                for (sfb in 3...13)
                {
                    //System.out.println("sfreq="+sfreq+" sfb="+sfb+" sfBandIndex="+sfBandIndex.length+" sfBandIndex[sfreq].s="+sfBandIndex[sfreq].s.length);
                    sfb_start = sfBandIndex[sfreq].s[sfb];
                    sfb_lines = as3hx.Compat.parseInt(sfBandIndex[sfreq].s[sfb + 1] - sfb_start);
                    
                    var sfb_start3 : Int = as3hx.Compat.parseInt((sfb_start << 2) - sfb_start);
                    
                    freq = 0;
freq3 = 0;
                    while (freq < sfb_lines)
                    {
                        src_line = as3hx.Compat.parseInt(sfb_start3 + freq);
                        des_line = as3hx.Compat.parseInt(sfb_start3 + freq3);
                        // Modif E.B 02/22/99
                        reste = as3hx.Compat.parseInt(src_line % SSLIMIT);
                        quotien = as3hx.Compat.parseInt((src_line - reste) / SSLIMIT);
                        
                        out_1d[des_line] = xr_1d[quotien][reste];
                        src_line += sfb_lines;
                        des_line++;
                        
                        reste = as3hx.Compat.parseInt(src_line % SSLIMIT);
                        quotien = as3hx.Compat.parseInt((src_line - reste) / SSLIMIT);
                        
                        out_1d[des_line] = xr_1d[quotien][reste];
                        src_line += sfb_lines;
                        des_line++;
                        
                        reste = as3hx.Compat.parseInt(src_line % SSLIMIT);
                        quotien = as3hx.Compat.parseInt((src_line - reste) / SSLIMIT);
                        
                        out_1d[des_line] = xr_1d[quotien][reste];
                        
                        freq++;
                        freq3 += 3;
                    }
                }
            }
            else
            {
                // pure short
                for (index in 0...576)
                {
                    var j : Int = reorder_table[sfreq][index];
                    reste = as3hx.Compat.parseInt(j % SSLIMIT);
                    quotien = as3hx.Compat.parseInt((j - reste) / SSLIMIT);
                    out_1d[index] = xr_1d[quotien][reste];
                }
            }
        }
        else
        {
            // long blocks
            for (index in 0...576)
            {
                // Modif E.B 02/22/99
                reste = as3hx.Compat.parseInt(index % SSLIMIT);
                quotien = as3hx.Compat.parseInt((index - reste) / SSLIMIT);
                out_1d[index] = xr_1d[quotien][reste];
            }
        }
    }
    
    /**
	 *
	 */
    
    public var is_pos : Array<Dynamic> = new Array<Dynamic>(576);
    public var is_ratio : Array<Dynamic> = new Array<Dynamic>(576);
    
    private function stereo(gr : Int) : Void
    {
        var sb : Int;
        var ss : Int;
        
        if (channels == 1)
        {
            // mono , bypass xr[0][][] to lr[0][][]
            
            for (sb in 0...SBLIMIT)
            {
                ss = 0;
                while (ss < SSLIMIT)
                {
                    lr[0][sb][ss] = ro[0][sb][ss];
                    lr[0][sb][ss + 1] = ro[0][sb][ss + 1];
                    lr[0][sb][ss + 2] = ro[0][sb][ss + 2];
                    ss += 3;
                }
            }
        }
        else
        {
            var sfbcnt : Int;
            var gr_info : GrInfoS = (si.ch[0].gr[gr]);
            var mode_ext : Int = header.mode_extension();
            var sfb : Int;
            var i : Int;
            var lines : Int;
            var temp : Int;
            var temp2 : Int;
            
            var ms_stereo : Bool = ((header.mode() == Header.JOINT_STEREO) && ((mode_ext & 0x2) != 0));
            var i_stereo : Bool = ((header.mode() == Header.JOINT_STEREO) && ((mode_ext & 0x1) != 0));
            var lsf : Bool = header.version() == Header.MPEG2_LSF || header.version() == Header.MPEG25_LSF;  // SZD  
            
            var io_type : Int = as3hx.Compat.parseInt(gr_info.scalefac_compress & 1);
            
            // initialization
            
            for (i in 0...576)
            {
                is_pos[i] = 7;
                
                is_ratio[i] = 0.0;
            }
            var j : Int;
            if (i_stereo)
            {
                if ((gr_info.window_switching_flag != 0) && (gr_info.block_type == 2))
                {
                    if (gr_info.mixed_block_flag != 0)
                    {
                        var max_sfb : Int = 0;
                        
                        for (j in 0...3)
                        {
                            sfbcnt = 2;
                            sfb = 12;
                            while (sfb >= 3)
                            {
                                i = sfBandIndex[sfreq].s[sfb];
                                lines = as3hx.Compat.parseInt(sfBandIndex[sfreq].s[sfb + 1] - i);
                                i = as3hx.Compat.parseInt((i << 2) - i + (j + 1) * lines - 1);
                                
                                while (lines > 0)
                                {
                                    if (ro[1][i / 18][i % 18] != 0.0)
                                    {
                                        // MDM: in java, array access is very slow.
                                        // Is quicker to compute div and mod values.
                                        //if (ro[1][ss_div[i]][ss_mod[i]] != 0.0f) {
                                        sfbcnt = sfb;
                                        sfb = -10;
                                        lines = -10;
                                    }
                                    
                                    lines--;
                                    i--;
                                }
                                sfb--;
                            }  // for (sfb=12 ...  
                            sfb = as3hx.Compat.parseInt(sfbcnt + 1);
                            
                            if (sfb > max_sfb)
                            {
                                max_sfb = sfb;
                            }
                            
                            while (sfb < 12)
                            {
                                temp = sfBandIndex[sfreq].s[sfb];
                                sb = as3hx.Compat.parseInt(sfBandIndex[sfreq].s[sfb + 1] - temp);
                                i = as3hx.Compat.parseInt((temp << 2) - temp + j * sb);
                                
                                sb = sb;
                                while (sb > 0)
                                {
                                    is_pos[i] = scalefac[1].s[j][sfb];
                                    if (is_pos[i] != 7)
                                    {
                                        if (lsf)
                                        {
                                            i_stereo_k_values(is_pos[i], io_type, i);
                                        }
                                        else
                                        {
                                            is_ratio[i] = TAN12[is_pos[i]];
                                        }
                                    }
                                    
                                    i++;
                                    sb--;
                                }  // for (; sb>0...  
                                sfb++;
                            }  // while (sfb < 12)  
                            sfb = sfBandIndex[sfreq].s[10];
                            sb = as3hx.Compat.parseInt(sfBandIndex[sfreq].s[11] - sfb);
                            sfb = as3hx.Compat.parseInt((sfb << 2) - sfb + j * sb);
                            temp = sfBandIndex[sfreq].s[11];
                            sb = as3hx.Compat.parseInt(sfBandIndex[sfreq].s[12] - temp);
                            i = as3hx.Compat.parseInt((temp << 2) - temp + j * sb);
                            
                            sb = sb;
                            while (sb > 0)
                            {
                                is_pos[i] = is_pos[sfb];
                                
                                if (lsf)
                                {
                                    k[0][i] = k[0][sfb];
                                    k[1][i] = k[1][sfb];
                                }
                                else
                                {
                                    is_ratio[i] = is_ratio[sfb];
                                }
                                i++;
                                sb--;
                            }
                        }
                        if (max_sfb <= 3)
                        {
                            i = 2;
                            ss = 17;
                            sb = -1;
                            while (i >= 0)
                            {
                                if (ro[1][i][ss] != 0.0)
                                {
                                    sb = as3hx.Compat.parseInt((i << 4) + (i << 1) + ss);
                                    i = -1;
                                }
                                else
                                {
                                    ss--;
                                    if (ss < 0)
                                    {
                                        i--;
                                        ss = 17;
                                    }
                                }
                            }  // while (i>=0)  
                            i = 0;
                            while (sfBandIndex[sfreq].l[i] <= sb)
                            {
                                i++;
                            }
                            sfb = i;
                            i = sfBandIndex[sfreq].l[i];
                            for (sfb in sfb...8)
                            {
                                sb = as3hx.Compat.parseInt(sfBandIndex[sfreq].l[sfb + 1] - sfBandIndex[sfreq].l[sfb]);
                                sb = sb;
                                while (sb > 0)
                                {
                                    is_pos[i] = scalefac[1].l[sfb];
                                    if (is_pos[i] != 7)
                                    {
                                        if (lsf)
                                        {
                                            i_stereo_k_values(is_pos[i], io_type, i);
                                        }
                                        else
                                        {
                                            is_ratio[i] = TAN12[is_pos[i]];
                                        }
                                    }
                                    i++;
                                    sb--;
                                }
                            }
                        }
                    }
                    else
                    {
                        // if (gr_info.mixed_block_flag)
                        for (j in 0...3)
                        {
                            sfbcnt = -1;
                            sfb = 12;
                            while (sfb >= 0)
                            {
                                temp = sfBandIndex[sfreq].s[sfb];
                                lines = as3hx.Compat.parseInt(sfBandIndex[sfreq].s[sfb + 1] - temp);
                                i = as3hx.Compat.parseInt((temp << 2) - temp + (j + 1) * lines - 1);
                                
                                while (lines > 0)
                                {
                                    if (ro[1][i / 18][i % 18] != 0.0)
                                    {
                                        // MDM: in java, array access is very slow.
                                        // Is quicker to compute div and mod values.
                                        //if (ro[1][ss_div[i]][ss_mod[i]] != 0.0f) {
                                        sfbcnt = sfb;
                                        sfb = -10;
                                        lines = -10;
                                    }
                                    lines--;
                                    i--;
                                }
                                sfb--;
                            }  // for (sfb=12 ...  
                            sfb = as3hx.Compat.parseInt(sfbcnt + 1);
                            while (sfb < 12)
                            {
                                temp = sfBandIndex[sfreq].s[sfb];
                                sb = as3hx.Compat.parseInt(sfBandIndex[sfreq].s[sfb + 1] - temp);
                                i = as3hx.Compat.parseInt((temp << 2) - temp + j * sb);
                                sb = sb;
                                while (sb > 0)
                                {
                                    is_pos[i] = scalefac[1].s[j][sfb];
                                    if (is_pos[i] != 7)
                                    {
                                        if (lsf)
                                        {
                                            i_stereo_k_values(is_pos[i], io_type, i);
                                        }
                                        else
                                        {
                                            is_ratio[i] = TAN12[is_pos[i]];
                                        }
                                    }
                                    i++;
                                    sb--;
                                }  // for (; sb>0 ...  
                                sfb++;
                            }  // while (sfb<12)  
                            
                            temp = sfBandIndex[sfreq].s[10];
                            temp2 = sfBandIndex[sfreq].s[11];
                            sb = as3hx.Compat.parseInt(temp2 - temp);
                            sfb = as3hx.Compat.parseInt((temp << 2) - temp + j * sb);
                            sb = as3hx.Compat.parseInt(sfBandIndex[sfreq].s[12] - temp2);
                            i = as3hx.Compat.parseInt((temp2 << 2) - temp2 + j * sb);
                            
                            sb = sb;
                            while (sb > 0)
                            {
                                is_pos[i] = is_pos[sfb];
                                
                                if (lsf)
                                {
                                    k[0][i] = k[0][sfb];
                                    k[1][i] = k[1][sfb];
                                }
                                else
                                {
                                    is_ratio[i] = is_ratio[sfb];
                                }
                                i++;
                                sb--;
                            }
                        }
                    }
                }
                else
                {
                    // if (gr_info.window_switching_flag ...
                    i = 31;
                    ss = 17;
                    sb = 0;
                    while (i >= 0)
                    {
                        if (ro[1][i][ss] != 0.0)
                        {
                            sb = as3hx.Compat.parseInt((i << 4) + (i << 1) + ss);
                            i = -1;
                        }
                        else
                        {
                            ss--;
                            if (ss < 0)
                            {
                                i--;
                                ss = 17;
                            }
                        }
                    }
                    i = 0;
                    while (sfBandIndex[sfreq].l[i] <= sb)
                    {
                        i++;
                    }
                    
                    sfb = i;
                    i = sfBandIndex[sfreq].l[i];
                    for (sfb in sfb...21)
                    {
                        sb = as3hx.Compat.parseInt(sfBandIndex[sfreq].l[sfb + 1] - sfBandIndex[sfreq].l[sfb]);
                        sb = sb;
                        while (sb > 0)
                        {
                            is_pos[i] = scalefac[1].l[sfb];
                            if (is_pos[i] != 7)
                            {
                                if (lsf)
                                {
                                    i_stereo_k_values(is_pos[i], io_type, i);
                                }
                                else
                                {
                                    is_ratio[i] = TAN12[is_pos[i]];
                                }
                            }
                            i++;
                            sb--;
                        }
                    }
                    sfb = sfBandIndex[sfreq].l[20];
                    sb = as3hx.Compat.parseInt(576 - sfBandIndex[sfreq].l[21]);
                    while ((sb > 0) && (i < 576))
                    {
                        is_pos[i] = is_pos[sfb];  // error here : i >=576  
                        
                        if (lsf)
                        {
                            k[0][i] = k[0][sfb];
                            k[1][i] = k[1][sfb];
                        }
                        else
                        {
                            is_ratio[i] = is_ratio[sfb];
                        }
                        i++;
                        sb--;
                    }
                }
            }  // if (i_stereo)  
            
            i = 0;
            for (sb in 0...SBLIMIT)
            {
                for (ss in 0...SSLIMIT)
                {
                    if (is_pos[i] == 7)
                    {
                        if (ms_stereo)
                        {
                            lr[0][sb][ss] = (ro[0][sb][ss] + ro[1][sb][ss]) * 0.707106781;
                            lr[1][sb][ss] = (ro[0][sb][ss] - ro[1][sb][ss]) * 0.707106781;
                        }
                        else
                        {
                            lr[0][sb][ss] = ro[0][sb][ss];
                            lr[1][sb][ss] = ro[1][sb][ss];
                        }
                    }
                    else
                    {
                        if (i_stereo)
                        {
                            if (lsf)
                            {
                                lr[0][sb][ss] = ro[0][sb][ss] * k[0][i];
                                lr[1][sb][ss] = ro[0][sb][ss] * k[1][i];
                            }
                            else
                            {
                                lr[1][sb][ss] = ro[0][sb][ss] / (1 + is_ratio[i]);
                                lr[0][sb][ss] = lr[1][sb][ss] * is_ratio[i];
                            }
                        }
                    }
                    /*				else {
						System.out.println("Error in stereo processing\n");
					} */
                    i++;
                }
            }
        }
    }
    
    /**
	 *
	 */
    private function antialias(ch : Int, gr : Int) : Void
    {
        var sb18 : Int;
        var ss : Int;
        var sb18lim : Int;
        var gr_info : GrInfoS = (si.ch[ch].gr[gr]);
        // 31 alias-reduction operations between each pair of sub-bands
        // with 8 butterflies between each pair
        
        if ((gr_info.window_switching_flag != 0) && (gr_info.block_type == 2) &&
            !(gr_info.mixed_block_flag != 0))
        {
            return;
        }
        
        if ((gr_info.window_switching_flag != 0) && (gr_info.mixed_block_flag != 0) &&
            (gr_info.block_type == 2))
        {
            sb18lim = 18;
        }
        else
        {
            sb18lim = 558;
        }
        
        sb18 = 0;
        while (sb18 < sb18lim)
        {
            for (ss in 0...8)
            {
                var src_idx1 : Int = as3hx.Compat.parseInt(sb18 + 17 - ss);
                var src_idx2 : Int = as3hx.Compat.parseInt(sb18 + 18 + ss);
                var bu : Float = out_1d[src_idx1];
                var bd : Float = out_1d[src_idx2];
                out_1d[src_idx1] = (bu * cs[ss]) - (bd * ca[ss]);
                out_1d[src_idx2] = (bd * cs[ss]) + (bu * ca[ss]);
            }
            sb18 += 18;
        }
    }
    
    /**
	 *
	 */
    
    // MDM: tsOutCopy and rawout do not need initializing, so the arrays
    // can be reused.
    private var tsOutCopy : Array<Dynamic> = new Array<Dynamic>(18);
    private var rawout : Array<Dynamic> = new Array<Dynamic>(36);
    
    private function hybrid(ch : Int, gr : Int) : Void
    {
        var bt : Int;
        var sb18 : Int;
        var gr_info : GrInfoS = (si.ch[ch].gr[gr]);
        var tsOut : Array<Dynamic>;
        
        var prvblk : Array<Dynamic>;
        var cc : Int;
        sb18 = 0;
        while (sb18 < 576)
        {
            bt = (((gr_info.window_switching_flag != 0) && (gr_info.mixed_block_flag != 0) &&
                    (sb18 < 36))) ? 0 : gr_info.block_type;
            
            tsOut = out_1d;
            // Modif E.B 02/22/99
            for (cc in 0...18)
            {
                tsOutCopy[cc] = tsOut[cc + sb18];
            }
            
            inv_mdct(tsOutCopy, rawout, bt);
            
            
            for (cc in 0...18)
            {
                tsOut[cc + sb18] = tsOutCopy[cc];
            }
            // Fin Modif
            
            // overlap addition
            prvblk = prevblck;
            
            tsOut[0 + sb18] = rawout[0] + prvblk[ch][sb18 + 0];
            prvblk[ch][sb18 + 0] = rawout[18];
            tsOut[1 + sb18] = rawout[1] + prvblk[ch][sb18 + 1];
            prvblk[ch][sb18 + 1] = rawout[19];
            tsOut[2 + sb18] = rawout[2] + prvblk[ch][sb18 + 2];
            prvblk[ch][sb18 + 2] = rawout[20];
            tsOut[3 + sb18] = rawout[3] + prvblk[ch][sb18 + 3];
            prvblk[ch][sb18 + 3] = rawout[21];
            tsOut[4 + sb18] = rawout[4] + prvblk[ch][sb18 + 4];
            prvblk[ch][sb18 + 4] = rawout[22];
            tsOut[5 + sb18] = rawout[5] + prvblk[ch][sb18 + 5];
            prvblk[ch][sb18 + 5] = rawout[23];
            tsOut[6 + sb18] = rawout[6] + prvblk[ch][sb18 + 6];
            prvblk[ch][sb18 + 6] = rawout[24];
            tsOut[7 + sb18] = rawout[7] + prvblk[ch][sb18 + 7];
            prvblk[ch][sb18 + 7] = rawout[25];
            tsOut[8 + sb18] = rawout[8] + prvblk[ch][sb18 + 8];
            prvblk[ch][sb18 + 8] = rawout[26];
            tsOut[9 + sb18] = rawout[9] + prvblk[ch][sb18 + 9];
            prvblk[ch][sb18 + 9] = rawout[27];
            tsOut[10 + sb18] = rawout[10] + prvblk[ch][sb18 + 10];
            prvblk[ch][sb18 + 10] = rawout[28];
            tsOut[11 + sb18] = rawout[11] + prvblk[ch][sb18 + 11];
            prvblk[ch][sb18 + 11] = rawout[29];
            tsOut[12 + sb18] = rawout[12] + prvblk[ch][sb18 + 12];
            prvblk[ch][sb18 + 12] = rawout[30];
            tsOut[13 + sb18] = rawout[13] + prvblk[ch][sb18 + 13];
            prvblk[ch][sb18 + 13] = rawout[31];
            tsOut[14 + sb18] = rawout[14] + prvblk[ch][sb18 + 14];
            prvblk[ch][sb18 + 14] = rawout[32];
            tsOut[15 + sb18] = rawout[15] + prvblk[ch][sb18 + 15];
            prvblk[ch][sb18 + 15] = rawout[33];
            tsOut[16 + sb18] = rawout[16] + prvblk[ch][sb18 + 16];
            prvblk[ch][sb18 + 16] = rawout[34];
            tsOut[17 + sb18] = rawout[17] + prvblk[ch][sb18 + 17];
            prvblk[ch][sb18 + 17] = rawout[35];
            sb18 += 18;
        }
    }
    
    /**
	 *
	 */
    private function do_downmix() : Void
    {
        for (sb in 0...SSLIMIT)
        {
            var ss : Int = 0;
            while (ss < SSLIMIT)
            {
                lr[0][sb][ss] = (lr[0][sb][ss] + lr[1][sb][ss]) * 0.5;
                lr[0][sb][ss + 1] = (lr[0][sb][ss + 1] + lr[1][sb][ss + 1]) * 0.5;
                lr[0][sb][ss + 2] = (lr[0][sb][ss + 2] + lr[1][sb][ss + 2]) * 0.5;
                ss += 3;
            }
        }
    }
    
    /**
	 * Fast INV_MDCT.
	 */
    
    public function inv_mdct(inB : Array<Dynamic>, out : Array<Dynamic>, block_type : Int) : Void
    {
        var win_bt : Array<Dynamic>;
        var i : Int;
        
        var tmpf_0 : Float;
        var tmpf_1 : Float;
        var tmpf_2 : Float;
        var tmpf_3 : Float;
        var tmpf_4 : Float;
        var tmpf_5 : Float;
        var tmpf_6 : Float;
        var tmpf_7 : Float;
        var tmpf_8 : Float;
        var tmpf_9 : Float;
        var tmpf_10 : Float;
        var tmpf_11 : Float;
        var tmpf_12 : Float;
        var tmpf_13 : Float;
        var tmpf_14 : Float;
        var tmpf_15 : Float;
        var tmpf_16 : Float;
        var tmpf_17 : Float;
        
        tmpf_0 = tmpf_1 = tmpf_2 = tmpf_3 = tmpf_4 = tmpf_5 = tmpf_6 = tmpf_7 = tmpf_8 = tmpf_9 =
                                                                                        tmpf_10 = tmpf_11 = tmpf_12 = tmpf_13 = tmpf_14 = tmpf_15 = tmpf_16 = tmpf_17 = 0.0;
        
        
        
        if (block_type == 2)
        {
            /*
	 *
	 *		Under MicrosoftVM 2922, This causes a GPF, or
	 *		At best, an ArrayIndexOutOfBoundsExceptin.
			for(int p=0;p<36;p+=9)
		   {
		   	  out[p]   = out[p+1] = out[p+2] = out[p+3] =
		      out[p+4] = out[p+5] = out[p+6] = out[p+7] =
		      out[p+8] = 0.0f;
		   }
	*/
            out[0] = 0;
            out[1] = 0;
            out[2] = 0;
            out[3] = 0;
            out[4] = 0;
            out[5] = 0;
            out[6] = 0;
            out[7] = 0;
            out[8] = 0;
            out[9] = 0;
            out[10] = 0;
            out[11] = 0;
            out[12] = 0;
            out[13] = 0;
            out[14] = 0;
            out[15] = 0;
            out[16] = 0;
            out[17] = 0;
            out[18] = 0;
            out[19] = 0;
            out[20] = 0;
            out[21] = 0;
            out[22] = 0;
            out[23] = 0;
            out[24] = 0;
            out[25] = 0;
            out[26] = 0;
            out[27] = 0;
            out[28] = 0;
            out[29] = 0;
            out[30] = 0;
            out[31] = 0;
            out[32] = 0;
            out[33] = 0;
            out[34] = 0;
            out[35] = 0;
            
            var six_i : Int = 0;
            
            for (i in 0...3)
            {
                // 12 point IMDCT
                // Begin 12 point IDCT
                // Input aliasing for 12 pt IDCT
                inB[15 + i] += inB[12 + i];inB[12 + i] += inB[9 + i];inB[9 + i] += inB[6 + i];
                inB[6 + i] += inB[3 + i];inB[3 + i] += inB[0 + i];
                
                // Input aliasing on odd indices (for 6 point IDCT)
                inB[15 + i] += inB[9 + i];inB[9 + i] += inB[3 + i];
                
                // 3 point IDCT on even indices
                var pp1 : Float;
                var pp2 : Float;
                var sum : Float;
                pp2 = inB[12 + i] * 0.500000000;
                pp1 = inB[6 + i] * 0.866025403;
                sum = inB[0 + i] + pp2;
                tmpf_1 = inB[0 + i] - inB[12 + i];
                tmpf_0 = sum + pp1;
                tmpf_2 = sum - pp1;
                
                // End 3 point IDCT on even indices
                // 3 point IDCT on odd indices (for 6 point IDCT)
                pp2 = inB[15 + i] * 0.500000000;
                pp1 = inB[9 + i] * 0.866025403;
                sum = inB[3 + i] + pp2;
                tmpf_4 = inB[3 + i] - inB[15 + i];
                tmpf_5 = sum + pp1;
                tmpf_3 = sum - pp1;
                // End 3 point IDCT on odd indices
                // Twiddle factors on odd indices (for 6 point IDCT)
                
                tmpf_3 *= 1.931851653;
                tmpf_4 *= 0.707106781;
                tmpf_5 *= 0.517638090;
                
                // Output butterflies on 2 3 point IDCT's (for 6 point IDCT)
                var save : Float = tmpf_0;
                tmpf_0 += tmpf_5;
                tmpf_5 = save - tmpf_5;
                save = tmpf_1;
                tmpf_1 += tmpf_4;
                tmpf_4 = save - tmpf_4;
                save = tmpf_2;
                tmpf_2 += tmpf_3;
                tmpf_3 = save - tmpf_3;
                
                // End 6 point IDCT
                // Twiddle factors on indices (for 12 point IDCT)
                
                tmpf_0 *= 0.504314480;
                tmpf_1 *= 0.541196100;
                tmpf_2 *= 0.630236207;
                tmpf_3 *= 0.821339815;
                tmpf_4 *= 1.306562965;
                tmpf_5 *= 3.830648788;
                
                // End 12 point IDCT
                
                // Shift to 12 point modified IDCT, multiply by window type 2
                tmpf_8 = -tmpf_0 * 0.793353340;
                tmpf_9 = -tmpf_0 * 0.608761429;
                tmpf_7 = -tmpf_1 * 0.923879532;
                tmpf_10 = -tmpf_1 * 0.382683432;
                tmpf_6 = -tmpf_2 * 0.991444861;
                tmpf_11 = -tmpf_2 * 0.130526192;
                
                tmpf_0 = tmpf_3;
                tmpf_1 = tmpf_4 * 0.382683432;
                tmpf_2 = tmpf_5 * 0.608761429;
                
                tmpf_3 = -tmpf_5 * 0.793353340;
                tmpf_4 = -tmpf_4 * 0.923879532;
                tmpf_5 = -tmpf_0 * 0.991444861;
                
                tmpf_0 *= 0.130526192;
                
                out[six_i + 6] += tmpf_0;
                out[six_i + 7] += tmpf_1;
                out[six_i + 8] += tmpf_2;
                out[six_i + 9] += tmpf_3;
                out[six_i + 10] += tmpf_4;
                out[six_i + 11] += tmpf_5;
                out[six_i + 12] += tmpf_6;
                out[six_i + 13] += tmpf_7;
                out[six_i + 14] += tmpf_8;
                out[six_i + 15] += tmpf_9;
                out[six_i + 16] += tmpf_10;
                out[six_i + 17] += tmpf_11;
                
                six_i += 6;
            }
        }
        else
        {
            // 36 point IDCT
            // input aliasing for 36 point IDCT
            inB[17] += inB[16];inB[16] += inB[15];inB[15] += inB[14];inB[14] += inB[13];
            inB[13] += inB[12];inB[12] += inB[11];inB[11] += inB[10];inB[10] += inB[9];
            inB[9] += inB[8];inB[8] += inB[7];inB[7] += inB[6];inB[6] += inB[5];
            inB[5] += inB[4];inB[4] += inB[3];inB[3] += inB[2];inB[2] += inB[1];
            inB[1] += inB[0];
            
            // 18 point IDCT for odd indices
            // input aliasing for 18 point IDCT
            inB[17] += inB[15];inB[15] += inB[13];inB[13] += inB[11];inB[11] += inB[9];
            inB[9] += inB[7];inB[7] += inB[5];inB[5] += inB[3];inB[3] += inB[1];
            
            var tmp0 : Float;
            var tmp1 : Float;
            var tmp2 : Float;
            var tmp3 : Float;
            var tmp4 : Float;
            var tmp0_ : Float;
            var tmp1_ : Float;
            var tmp2_ : Float;
            var tmp3_ : Float;
            var tmp0o : Float;
            var tmp1o : Float;
            var tmp2o : Float;
            var tmp3o : Float;
            var tmp4o : Float;
            var tmp0_o : Float;
            var tmp1_o : Float;
            var tmp2_o : Float;
            var tmp3_o : Float;
            
            // Fast 9 Point Inverse Discrete Cosine Transform
            //
            // By  Francois-Raymond Boyer
            //         mailto:boyerf@iro.umontreal.ca
            //         http://www.iro.umontreal.ca/~boyerf
            //
            // The code has been optimized for Intel processors
            //  (takes a lot of time to convert float to and from iternal FPU representation)
            //
            // It is a simple "factorization" of the IDCT matrix.
            
            // 9 point IDCT on even indices
            
            // 5 points on odd indices (not realy an IDCT)
            var i00 : Float = inB[0] + inB[0];
            var iip12 : Float = i00 + inB[12];
            
            tmp0 = iip12 + inB[4] * 1.8793852415718 + inB[8] * 1.532088886238 + inB[16] * 0.34729635533386;
            tmp1 = i00 + inB[4] - inB[8] - inB[12] - inB[12] - inB[16];
            tmp2 = iip12 - inB[4] * 0.34729635533386 - inB[8] * 1.8793852415718 + inB[16] * 1.532088886238;
            tmp3 = iip12 - inB[4] * 1.532088886238 + inB[8] * 0.34729635533386 - inB[16] * 1.8793852415718;
            tmp4 = inB[0] - inB[4] + inB[8] - inB[12] + inB[16];
            
            // 4 points on even indices
            var i66_ : Float = inB[6] * 1.732050808;  // Sqrt[3]  
            
            tmp0_ = inB[2] * 1.9696155060244 + i66_ + inB[10] * 1.2855752193731 + inB[14] * 0.68404028665134;
            tmp1_ = (inB[2] - inB[10] - inB[14]) * 1.732050808;
            tmp2_ = inB[2] * 1.2855752193731 - i66_ - inB[10] * 0.68404028665134 + inB[14] * 1.9696155060244;
            tmp3_ = inB[2] * 0.68404028665134 - i66_ + inB[10] * 1.9696155060244 - inB[14] * 1.2855752193731;
            
            // 9 point IDCT on odd indices
            // 5 points on odd indices (not realy an IDCT)
            var i0 : Float = inB[0 + 1] + inB[0 + 1];
            var i0p12 : Float = i0 + inB[12 + 1];
            
            tmp0o = i0p12 + inB[4 + 1] * 1.8793852415718 + inB[8 + 1] * 1.532088886238 + inB[16 + 1] * 0.34729635533386;
            tmp1o = i0 + inB[4 + 1] - inB[8 + 1] - inB[12 + 1] - inB[12 + 1] - inB[16 + 1];
            tmp2o = i0p12 - inB[4 + 1] * 0.34729635533386 - inB[8 + 1] * 1.8793852415718 + inB[16 + 1] * 1.532088886238;
            tmp3o = i0p12 - inB[4 + 1] * 1.532088886238 + inB[8 + 1] * 0.34729635533386 - inB[16 + 1] * 1.8793852415718;
            tmp4o = (inB[0 + 1] - inB[4 + 1] + inB[8 + 1] - inB[12 + 1] + inB[16 + 1]) * 0.707106781;  // Twiddled  
            
            // 4 points on even indices
            var i6_ : Float = inB[6 + 1] * 1.732050808;  // Sqrt[3]  
            
            tmp0_o = inB[2 + 1] * 1.9696155060244 + i6_ + inB[10 + 1] * 1.2855752193731 + inB[14 + 1] * 0.68404028665134;
            tmp1_o = (inB[2 + 1] - inB[10 + 1] - inB[14 + 1]) * 1.732050808;
            tmp2_o = inB[2 + 1] * 1.2855752193731 - i6_ - inB[10 + 1] * 0.68404028665134 + inB[14 + 1] * 1.9696155060244;
            tmp3_o = inB[2 + 1] * 0.68404028665134 - i6_ + inB[10 + 1] * 1.9696155060244 - inB[14 + 1] * 1.2855752193731;
            
            // Twiddle factors on odd indices
            // and
            // Butterflies on 9 point IDCT's
            // and
            // twiddle factors for 36 point IDCT
            
            var e : Float;
            var o : Float;
            e = tmp0 + tmp0_;o = (tmp0o + tmp0_o) * 0.501909918;tmpf_0 = e + o;tmpf_17 = e - o;
            e = tmp1 + tmp1_;o = (tmp1o + tmp1_o) * 0.517638090;tmpf_1 = e + o;tmpf_16 = e - o;
            e = tmp2 + tmp2_;o = (tmp2o + tmp2_o) * 0.551688959;tmpf_2 = e + o;tmpf_15 = e - o;
            e = tmp3 + tmp3_;o = (tmp3o + tmp3_o) * 0.610387294;tmpf_3 = e + o;tmpf_14 = e - o;
            tmpf_4 = tmp4 + tmp4o;tmpf_13 = tmp4 - tmp4o;
            e = tmp3 - tmp3_;o = (tmp3o - tmp3_o) * 0.871723397;tmpf_5 = e + o;tmpf_12 = e - o;
            e = tmp2 - tmp2_;o = (tmp2o - tmp2_o) * 1.183100792;tmpf_6 = e + o;tmpf_11 = e - o;
            e = tmp1 - tmp1_;o = (tmp1o - tmp1_o) * 1.931851653;tmpf_7 = e + o;tmpf_10 = e - o;
            e = tmp0 - tmp0_;o = (tmp0o - tmp0_o) * 5.736856623;tmpf_8 = e + o;tmpf_9 = e - o;
            
            // end 36 point IDCT */
            // shift to modified IDCT
            win_bt = win[block_type];
            
            out[0] = -tmpf_9 * win_bt[0];
            out[1] = -tmpf_10 * win_bt[1];
            out[2] = -tmpf_11 * win_bt[2];
            out[3] = -tmpf_12 * win_bt[3];
            out[4] = -tmpf_13 * win_bt[4];
            out[5] = -tmpf_14 * win_bt[5];
            out[6] = -tmpf_15 * win_bt[6];
            out[7] = -tmpf_16 * win_bt[7];
            out[8] = -tmpf_17 * win_bt[8];
            out[9] = tmpf_17 * win_bt[9];
            out[10] = tmpf_16 * win_bt[10];
            out[11] = tmpf_15 * win_bt[11];
            out[12] = tmpf_14 * win_bt[12];
            out[13] = tmpf_13 * win_bt[13];
            out[14] = tmpf_12 * win_bt[14];
            out[15] = tmpf_11 * win_bt[15];
            out[16] = tmpf_10 * win_bt[16];
            out[17] = tmpf_9 * win_bt[17];
            out[18] = tmpf_8 * win_bt[18];
            out[19] = tmpf_7 * win_bt[19];
            out[20] = tmpf_6 * win_bt[20];
            out[21] = tmpf_5 * win_bt[21];
            out[22] = tmpf_4 * win_bt[22];
            out[23] = tmpf_3 * win_bt[23];
            out[24] = tmpf_2 * win_bt[24];
            out[25] = tmpf_1 * win_bt[25];
            out[26] = tmpf_0 * win_bt[26];
            out[27] = tmpf_0 * win_bt[27];
            out[28] = tmpf_1 * win_bt[28];
            out[29] = tmpf_2 * win_bt[29];
            out[30] = tmpf_3 * win_bt[30];
            out[31] = tmpf_4 * win_bt[31];
            out[32] = tmpf_5 * win_bt[32];
            out[33] = tmpf_6 * win_bt[33];
            out[34] = tmpf_7 * win_bt[34];
            out[35] = tmpf_8 * win_bt[35];
        }
    }
    
    private var counter : Int = 0;
    private static inline var SSLIMIT : Int = 18;
    private static inline var SBLIMIT : Int = 32;
    // Size of the table of whole numbers raised to 4/3 power.
    // This may be adjusted for performance without any problems.
    //public static final int 	POW_TABLE_LIMIT=512;
    
    /************************************************************/
    /*                            L3TABLE                       */
    /************************************************************/
    
    //class III_scalefac_t
    //{
    //    public temporaire2[]    tab;
    //   	/**
    //   	 * Dummy Constructor
    //   	 */
    //   	public III_scalefac_t()
    //   	{
    //   		tab = new temporaire2[2];
    //	}
    //}
    
    private static var slen : Array<Dynamic> = 
        [
        [0, 0, 0, 0, 3, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4], 
        [0, 1, 2, 3, 0, 1, 2, 3, 1, 2, 3, 1, 2, 3, 2, 3]
    ];
    
    public static var pretab : Array<Dynamic> = 
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 3, 3, 3, 2, 0];
    
    private var sfBandIndex : Array<Dynamic>;  // Init in the constructor.  
    
    public static var two_to_negative_half_pow : Array<Dynamic> = 
        [1.0000000000e + 00, 7.0710678119e-01, 5.0000000000e-01, 3.5355339059e-01, 
        2.5000000000e-01, 1.7677669530e-01, 1.2500000000e-01, 8.8388347648e-02, 
        6.2500000000e-02, 4.4194173824e-02, 3.1250000000e-02, 2.2097086912e-02, 
        1.5625000000e-02, 1.1048543456e-02, 7.8125000000e-03, 5.5242717280e-03, 
        3.9062500000e-03, 2.7621358640e-03, 1.9531250000e-03, 1.3810679320e-03, 
        9.7656250000e-04, 6.9053396600e-04, 4.8828125000e-04, 3.4526698300e-04, 
        2.4414062500e-04, 1.7263349150e-04, 1.2207031250e-04, 8.6316745750e-05, 
        6.1035156250e-05, 4.3158372875e-05, 3.0517578125e-05, 2.1579186438e-05, 
        1.5258789062e-05, 1.0789593219e-05, 7.6293945312e-06, 5.3947966094e-06, 
        3.8146972656e-06, 2.6973983047e-06, 1.9073486328e-06, 1.3486991523e-06, 
        9.5367431641e-07, 6.7434957617e-07, 4.7683715820e-07, 3.3717478809e-07, 
        2.3841857910e-07, 1.6858739404e-07, 1.1920928955e-07, 8.4293697022e-08, 
        5.9604644775e-08, 4.2146848511e-08, 2.9802322388e-08, 2.1073424255e-08, 
        1.4901161194e-08, 1.0536712128e-08, 7.4505805969e-09, 5.2683560639e-09, 
        3.7252902985e-09, 2.6341780319e-09, 1.8626451492e-09, 1.3170890160e-09, 
        9.3132257462e-10, 6.5854450798e-10, 4.6566128731e-10, 3.2927225399e-10
    ];
    
    
    public static var t_43 : Array<Dynamic> = create_t_43();
    
    private static function create_t_43() : Array<Dynamic>
    {
        var t43 : Array<Dynamic> = new Array<Dynamic>(8192);
        var d43 : Float = (4.0 / 3.0);
        
        for (i in 0...8192)
        {
            t43[i] = Math.pow(i, d43);
        }
        return t43;
    }
    
    public static var io : Array<Dynamic> = 
        [
        [1.0000000000e + 00, 8.4089641526e-01, 7.0710678119e-01, 5.9460355751e-01, 
        5.0000000001e-01, 4.2044820763e-01, 3.5355339060e-01, 2.9730177876e-01, 
        2.5000000001e-01, 2.1022410382e-01, 1.7677669530e-01, 1.4865088938e-01, 
        1.2500000000e-01, 1.0511205191e-01, 8.8388347652e-02, 7.4325444691e-02, 
        6.2500000003e-02, 5.2556025956e-02, 4.4194173826e-02, 3.7162722346e-02, 
        3.1250000002e-02, 2.6278012978e-02, 2.2097086913e-02, 1.8581361173e-02, 
        1.5625000001e-02, 1.3139006489e-02, 1.1048543457e-02, 9.2906805866e-03, 
        7.8125000006e-03, 6.5695032447e-03, 5.5242717285e-03, 4.6453402934e-03
    ], 
        [1.0000000000e + 00, 7.0710678119e-01, 5.0000000000e-01, 3.5355339060e-01, 
        2.5000000000e-01, 1.7677669530e-01, 1.2500000000e-01, 8.8388347650e-02, 
        6.2500000001e-02, 4.4194173825e-02, 3.1250000001e-02, 2.2097086913e-02, 
        1.5625000000e-02, 1.1048543456e-02, 7.8125000002e-03, 5.5242717282e-03, 
        3.9062500001e-03, 2.7621358641e-03, 1.9531250001e-03, 1.3810679321e-03, 
        9.7656250004e-04, 6.9053396603e-04, 4.8828125002e-04, 3.4526698302e-04, 
        2.4414062501e-04, 1.7263349151e-04, 1.2207031251e-04, 8.6316745755e-05, 
        6.1035156254e-05, 4.3158372878e-05, 3.0517578127e-05, 2.1579186439e-05
    ]
    ];
    
    
    
    public static var TAN12 : Array<Dynamic> = 
        [
        0.0, 0.26794919, 0.57735027, 1.0, 
        1.73205081, 3.73205081, 9.9999999e10, -3.73205081, 
        -1.73205081, -1.0, -0.57735027, -0.26794919, 
        0.0, 0.26794919, 0.57735027, 1.0
    ];
    
    // REVIEW: in java, the array lookup may well be slower than
    // the actual calculation
    // 576 / 18
    /*
	private static final int ss_div[] =
	{
		 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
		 1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,
		 2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
		 3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,
		 4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,
		 5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,
		 6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,
		 7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,  7,
		 8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,  8,
		 9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,  9,
		10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
		11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
		12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
		13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
		14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
		15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
		16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16,
		17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17,
		18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18,
		19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19,
		20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20,
		21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21,
		22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22,
		23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
		24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
		25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
		26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26,
		27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
		28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28,
		29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29,
		30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30,
		31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31
	};

	// 576 % 18
	private static final int ss_mod[] =
	{
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17,
		 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17
	};
*/
    /*final*/private static var reorder_table : Array<Dynamic>;  // SZD: will be generated on demand  
    
    /**
	 * Loads the data for the reorder
	 */
    /*private static int[][] loadReorderTable()	// SZD: table will be generated
	{
		try
		{
			Class elemType = int[][].class.getComponentType();
			Object o = JavaLayerUtils.deserializeArrayResource("l3reorder.ser", elemType, 6);
			return (int[][])o;
		}
		catch (IOException ex)
		{
			throw new ExceptionInInitializerError(ex);
		}
	}*/
    
    private function reorder2(scalefac_band : Array<Dynamic>) : Array<Dynamic>
    {
        // SZD: converted from LAME
        var j : Int = 0;
        var ix : Array<Dynamic> = new Array<Dynamic>(576);
        for (sfb in 0...13)
        {
            var start : Int = scalefac_band[sfb];
            var end : Int = scalefac_band[sfb + 1];
            for (window in 0...3)
            {
                for (i in start...end)
                {
                    ix[3 * i + window] = j++;
                }
            }
        }
        return ix;
    }
    
    /*static final int reorder_table_data[][]; =
	{
	 {  0,  4,  8,  1,  5,  9,  2,  6, 10,  3,  7, 11, 12, 16, 20, 13,
	   17, 21, 14, 18, 22, 15, 19, 23, 24, 28, 32, 25, 29, 33, 26, 30,
	   34, 27, 31, 35, 36, 42, 48, 37, 43, 49, 38, 44, 50, 39, 45, 51,
	   40, 46, 52, 41, 47, 53, 54, 60, 66, 55, 61, 67, 56, 62, 68, 57,
	   63, 69, 58, 64, 70, 59, 65, 71, 72, 80, 88, 73, 81, 89, 74, 82,
	   90, 75, 83, 91, 76, 84, 92, 77, 85, 93, 78, 86, 94, 79, 87, 95,
	   96,106,116, 97,107,117, 98,108,118, 99,109,119,100,110,120,101,
	  111,121,102,112,122,103,113,123,104,114,124,105,115,125,126,140,
	  154,127,141,155,128,142,156,129,143,157,130,144,158,131,145,159,
	  132,146,160,133,147,161,134,148,162,135,149,163,136,150,164,137,
	  151,165,138,152,166,139,153,167,168,186,204,169,187,205,170,188,
	  206,171,189,207,172,190,208,173,191,209,174,192,210,175,193,211,
	  176,194,212,177,195,213,178,196,214,179,197,215,180,198,216,181,
	  199,217,182,200,218,183,201,219,184,202,220,185,203,221,222,248,
	  274,223,249,275,224,250,276,225,251,277,226,252,278,227,253,279,
	  228,254,280,229,255,281,230,256,282,231,257,283,232,258,284,233,
	  259,285,234,260,286,235,261,287,236,262,288,237,263,289,238,264,
	  290,239,265,291,240,266,292,241,267,293,242,268,294,243,269,295,
	  244,270,296,245,271,297,246,272,298,247,273,299,300,332,364,301,
	  333,365,302,334,366,303,335,367,304,336,368,305,337,369,306,338,
	  370,307,339,371,308,340,372,309,341,373,310,342,374,311,343,375,
	  312,344,376,313,345,377,314,346,378,315,347,379,316,348,380,317,
	  349,381,318,350,382,319,351,383,320,352,384,321,353,385,322,354,
	  386,323,355,387,324,356,388,325,357,389,326,358,390,327,359,391,
	  328,360,392,329,361,393,330,362,394,331,363,395,396,438,480,397,
	  439,481,398,440,482,399,441,483,400,442,484,401,443,485,402,444,
	  486,403,445,487,404,446,488,405,447,489,406,448,490,407,449,491,
	  408,450,492,409,451,493,410,452,494,411,453,495,412,454,496,413,
	  455,497,414,456,498,415,457,499,416,458,500,417,459,501,418,460,
	  502,419,461,503,420,462,504,421,463,505,422,464,506,423,465,507,
	  424,466,508,425,467,509,426,468,510,427,469,511,428,470,512,429,
	  471,513,430,472,514,431,473,515,432,474,516,433,475,517,434,476,
	  518,435,477,519,436,478,520,437,479,521,522,540,558,523,541,559,
	  524,542,560,525,543,561,526,544,562,527,545,563,528,546,564,529,
	  547,565,530,548,566,531,549,567,532,550,568,533,551,569,534,552,
	  570,535,553,571,536,554,572,537,555,573,538,556,574,539,557,575},
	 {  0,  4,  8,  1,  5,  9,  2,  6, 10,  3,  7, 11, 12, 16, 20, 13,
	   17, 21, 14, 18, 22, 15, 19, 23, 24, 28, 32, 25, 29, 33, 26, 30,
	   34, 27, 31, 35, 36, 42, 48, 37, 43, 49, 38, 44, 50, 39, 45, 51,
	   40, 46, 52, 41, 47, 53, 54, 62, 70, 55, 63, 71, 56, 64, 72, 57,
	   65, 73, 58, 66, 74, 59, 67, 75, 60, 68, 76, 61, 69, 77, 78, 88,
	   98, 79, 89, 99, 80, 90,100, 81, 91,101, 82, 92,102, 83, 93,103,
	   84, 94,104, 85, 95,105, 86, 96,106, 87, 97,107,108,120,132,109,
	  121,133,110,122,134,111,123,135,112,124,136,113,125,137,114,126,
	  138,115,127,139,116,128,140,117,129,141,118,130,142,119,131,143,
	  144,158,172,145,159,173,146,160,174,147,161,175,148,162,176,149,
	  163,177,150,164,178,151,165,179,152,166,180,153,167,181,154,168,
	  182,155,169,183,156,170,184,157,171,185,186,204,222,187,205,223,
	  188,206,224,189,207,225,190,208,226,191,209,227,192,210,228,193,
	  211,229,194,212,230,195,213,231,196,214,232,197,215,233,198,216,
	  234,199,217,235,200,218,236,201,219,237,202,220,238,203,221,239,
	  240,264,288,241,265,289,242,266,290,243,267,291,244,268,292,245,
	  269,293,246,270,294,247,271,295,248,272,296,249,273,297,250,274,
	  298,251,275,299,252,276,300,253,277,301,254,278,302,255,279,303,
	  256,280,304,257,281,305,258,282,306,259,283,307,260,284,308,261,
	  285,309,262,286,310,263,287,311,312,344,376,313,345,377,314,346,
	  378,315,347,379,316,348,380,317,349,381,318,350,382,319,351,383,
	  320,352,384,321,353,385,322,354,386,323,355,387,324,356,388,325,
	  357,389,326,358,390,327,359,391,328,360,392,329,361,393,330,362,
	  394,331,363,395,332,364,396,333,365,397,334,366,398,335,367,399,
	  336,368,400,337,369,401,338,370,402,339,371,403,340,372,404,341,
	  373,405,342,374,406,343,375,407,408,452,496,409,453,497,410,454,
	  498,411,455,499,412,456,500,413,457,501,414,458,502,415,459,503,
	  416,460,504,417,461,505,418,462,506,419,463,507,420,464,508,421,
	  465,509,422,466,510,423,467,511,424,468,512,425,469,513,426,470,
	  514,427,471,515,428,472,516,429,473,517,430,474,518,431,475,519,
	  432,476,520,433,477,521,434,478,522,435,479,523,436,480,524,437,
	  481,525,438,482,526,439,483,527,440,484,528,441,485,529,442,486,
	  530,443,487,531,444,488,532,445,489,533,446,490,534,447,491,535,
	  448,492,536,449,493,537,450,494,538,451,495,539,540,552,564,541,
	  553,565,542,554,566,543,555,567,544,556,568,545,557,569,546,558,
	  570,547,559,571,548,560,572,549,561,573,550,562,574,551,563,575},
	 {  0,  4,  8,  1,  5,  9,  2,  6, 10,  3,  7, 11, 12, 16, 20, 13,
	   17, 21, 14, 18, 22, 15, 19, 23, 24, 28, 32, 25, 29, 33, 26, 30,
	   34, 27, 31, 35, 36, 42, 48, 37, 43, 49, 38, 44, 50, 39, 45, 51,
	   40, 46, 52, 41, 47, 53, 54, 62, 70, 55, 63, 71, 56, 64, 72, 57,
	   65, 73, 58, 66, 74, 59, 67, 75, 60, 68, 76, 61, 69, 77, 78, 88,
	   98, 79, 89, 99, 80, 90,100, 81, 91,101, 82, 92,102, 83, 93,103,
	   84, 94,104, 85, 95,105, 86, 96,106, 87, 97,107,108,120,132,109,
	  121,133,110,122,134,111,123,135,112,124,136,113,125,137,114,126,
	  138,115,127,139,116,128,140,117,129,141,118,130,142,119,131,143,
	  144,158,172,145,159,173,146,160,174,147,161,175,148,162,176,149,
	  163,177,150,164,178,151,165,179,152,166,180,153,167,181,154,168,
	  182,155,169,183,156,170,184,157,171,185,186,204,222,187,205,223,
	  188,206,224,189,207,225,190,208,226,191,209,227,192,210,228,193,
	  211,229,194,212,230,195,213,231,196,214,232,197,215,233,198,216,
	  234,199,217,235,200,218,236,201,219,237,202,220,238,203,221,239,
	  240,264,288,241,265,289,242,266,290,243,267,291,244,268,292,245,
	  269,293,246,270,294,247,271,295,248,272,296,249,273,297,250,274,
	  298,251,275,299,252,276,300,253,277,301,254,278,302,255,279,303,
	  256,280,304,257,281,305,258,282,306,259,283,307,260,284,308,261,
	  285,309,262,286,310,263,287,311,312,342,372,313,343,373,314,344,
	  374,315,345,375,316,346,376,317,347,377,318,348,378,319,349,379,
	  320,350,380,321,351,381,322,352,382,323,353,383,324,354,384,325,
	  355,385,326,356,386,327,357,387,328,358,388,329,359,389,330,360,
	  390,331,361,391,332,362,392,333,363,393,334,364,394,335,365,395,
	  336,366,396,337,367,397,338,368,398,339,369,399,340,370,400,341,
	  371,401,402,442,482,403,443,483,404,444,484,405,445,485,406,446,
	  486,407,447,487,408,448,488,409,449,489,410,450,490,411,451,491,
	  412,452,492,413,453,493,414,454,494,415,455,495,416,456,496,417,
	  457,497,418,458,498,419,459,499,420,460,500,421,461,501,422,462,
	  502,423,463,503,424,464,504,425,465,505,426,466,506,427,467,507,
	  428,468,508,429,469,509,430,470,510,431,471,511,432,472,512,433,
	  473,513,434,474,514,435,475,515,436,476,516,437,477,517,438,478,
	  518,439,479,519,440,480,520,441,481,521,522,540,558,523,541,559,
	  524,542,560,525,543,561,526,544,562,527,545,563,528,546,564,529,
	  547,565,530,548,566,531,549,567,532,550,568,533,551,569,534,552,
	  570,535,553,571,536,554,572,537,555,573,538,556,574,539,557,575},
	 {  0,  4,  8,  1,  5,  9,  2,  6, 10,  3,  7, 11, 12, 16, 20, 13,
	   17, 21, 14, 18, 22, 15, 19, 23, 24, 28, 32, 25, 29, 33, 26, 30,
	   34, 27, 31, 35, 36, 40, 44, 37, 41, 45, 38, 42, 46, 39, 43, 47,
	   48, 54, 60, 49, 55, 61, 50, 56, 62, 51, 57, 63, 52, 58, 64, 53,
	   59, 65, 66, 74, 82, 67, 75, 83, 68, 76, 84, 69, 77, 85, 70, 78,
	   86, 71, 79, 87, 72, 80, 88, 73, 81, 89, 90,100,110, 91,101,111,
	   92,102,112, 93,103,113, 94,104,114, 95,105,115, 96,106,116, 97,
	  107,117, 98,108,118, 99,109,119,120,132,144,121,133,145,122,134,
	  146,123,135,147,124,136,148,125,137,149,126,138,150,127,139,151,
	  128,140,152,129,141,153,130,142,154,131,143,155,156,170,184,157,
	  171,185,158,172,186,159,173,187,160,174,188,161,175,189,162,176,
	  190,163,177,191,164,178,192,165,179,193,166,180,194,167,181,195,
	  168,182,196,169,183,197,198,216,234,199,217,235,200,218,236,201,
	  219,237,202,220,238,203,221,239,204,222,240,205,223,241,206,224,
	  242,207,225,243,208,226,244,209,227,245,210,228,246,211,229,247,
	  212,230,248,213,231,249,214,232,250,215,233,251,252,274,296,253,
	  275,297,254,276,298,255,277,299,256,278,300,257,279,301,258,280,
	  302,259,281,303,260,282,304,261,283,305,262,284,306,263,285,307,
	  264,286,308,265,287,309,266,288,310,267,289,311,268,290,312,269,
	  291,313,270,292,314,271,293,315,272,294,316,273,295,317,318,348,
	  378,319,349,379,320,350,380,321,351,381,322,352,382,323,353,383,
	  324,354,384,325,355,385,326,356,386,327,357,387,328,358,388,329,
	  359,389,330,360,390,331,361,391,332,362,392,333,363,393,334,364,
	  394,335,365,395,336,366,396,337,367,397,338,368,398,339,369,399,
	  340,370,400,341,371,401,342,372,402,343,373,403,344,374,404,345,
	  375,405,346,376,406,347,377,407,408,464,520,409,465,521,410,466,
	  522,411,467,523,412,468,524,413,469,525,414,470,526,415,471,527,
	  416,472,528,417,473,529,418,474,530,419,475,531,420,476,532,421,
	  477,533,422,478,534,423,479,535,424,480,536,425,481,537,426,482,
	  538,427,483,539,428,484,540,429,485,541,430,486,542,431,487,543,
	  432,488,544,433,489,545,434,490,546,435,491,547,436,492,548,437,
	  493,549,438,494,550,439,495,551,440,496,552,441,497,553,442,498,
	  554,443,499,555,444,500,556,445,501,557,446,502,558,447,503,559,
	  448,504,560,449,505,561,450,506,562,451,507,563,452,508,564,453,
	  509,565,454,510,566,455,511,567,456,512,568,457,513,569,458,514,
	  570,459,515,571,460,516,572,461,517,573,462,518,574,463,519,575},
	 {  0,  4,  8,  1,  5,  9,  2,  6, 10,  3,  7, 11, 12, 16, 20, 13,
	   17, 21, 14, 18, 22, 15, 19, 23, 24, 28, 32, 25, 29, 33, 26, 30,
	   34, 27, 31, 35, 36, 40, 44, 37, 41, 45, 38, 42, 46, 39, 43, 47,
	   48, 54, 60, 49, 55, 61, 50, 56, 62, 51, 57, 63, 52, 58, 64, 53,
	   59, 65, 66, 72, 78, 67, 73, 79, 68, 74, 80, 69, 75, 81, 70, 76,
	   82, 71, 77, 83, 84, 94,104, 85, 95,105, 86, 96,106, 87, 97,107,
	   88, 98,108, 89, 99,109, 90,100,110, 91,101,111, 92,102,112, 93,
	  103,113,114,126,138,115,127,139,116,128,140,117,129,141,118,130,
	  142,119,131,143,120,132,144,121,133,145,122,134,146,123,135,147,
	  124,136,148,125,137,149,150,164,178,151,165,179,152,166,180,153,
	  167,181,154,168,182,155,169,183,156,170,184,157,171,185,158,172,
	  186,159,173,187,160,174,188,161,175,189,162,176,190,163,177,191,
	  192,208,224,193,209,225,194,210,226,195,211,227,196,212,228,197,
	  213,229,198,214,230,199,215,231,200,216,232,201,217,233,202,218,
	  234,203,219,235,204,220,236,205,221,237,206,222,238,207,223,239,
	  240,260,280,241,261,281,242,262,282,243,263,283,244,264,284,245,
	  265,285,246,266,286,247,267,287,248,268,288,249,269,289,250,270,
	  290,251,271,291,252,272,292,253,273,293,254,274,294,255,275,295,
	  256,276,296,257,277,297,258,278,298,259,279,299,300,326,352,301,
	  327,353,302,328,354,303,329,355,304,330,356,305,331,357,306,332,
	  358,307,333,359,308,334,360,309,335,361,310,336,362,311,337,363,
	  312,338,364,313,339,365,314,340,366,315,341,367,316,342,368,317,
	  343,369,318,344,370,319,345,371,320,346,372,321,347,373,322,348,
	  374,323,349,375,324,350,376,325,351,377,378,444,510,379,445,511,
	  380,446,512,381,447,513,382,448,514,383,449,515,384,450,516,385,
	  451,517,386,452,518,387,453,519,388,454,520,389,455,521,390,456,
	  522,391,457,523,392,458,524,393,459,525,394,460,526,395,461,527,
	  396,462,528,397,463,529,398,464,530,399,465,531,400,466,532,401,
	  467,533,402,468,534,403,469,535,404,470,536,405,471,537,406,472,
	  538,407,473,539,408,474,540,409,475,541,410,476,542,411,477,543,
	  412,478,544,413,479,545,414,480,546,415,481,547,416,482,548,417,
	  483,549,418,484,550,419,485,551,420,486,552,421,487,553,422,488,
	  554,423,489,555,424,490,556,425,491,557,426,492,558,427,493,559,
	  428,494,560,429,495,561,430,496,562,431,497,563,432,498,564,433,
	  499,565,434,500,566,435,501,567,436,502,568,437,503,569,438,504,
	  570,439,505,571,440,506,572,441,507,573,442,508,574,443,509,575},
	 {  0,  4,  8,  1,  5,  9,  2,  6, 10,  3,  7, 11, 12, 16, 20, 13,
	   17, 21, 14, 18, 22, 15, 19, 23, 24, 28, 32, 25, 29, 33, 26, 30,
	   34, 27, 31, 35, 36, 40, 44, 37, 41, 45, 38, 42, 46, 39, 43, 47,
	   48, 54, 60, 49, 55, 61, 50, 56, 62, 51, 57, 63, 52, 58, 64, 53,
	   59, 65, 66, 74, 82, 67, 75, 83, 68, 76, 84, 69, 77, 85, 70, 78,
	   86, 71, 79, 87, 72, 80, 88, 73, 81, 89, 90,102,114, 91,103,115,
	   92,104,116, 93,105,117, 94,106,118, 95,107,119, 96,108,120, 97,
	  109,121, 98,110,122, 99,111,123,100,112,124,101,113,125,126,142,
	  158,127,143,159,128,144,160,129,145,161,130,146,162,131,147,163,
	  132,148,164,133,149,165,134,150,166,135,151,167,136,152,168,137,
	  153,169,138,154,170,139,155,171,140,156,172,141,157,173,174,194,
	  214,175,195,215,176,196,216,177,197,217,178,198,218,179,199,219,
	  180,200,220,181,201,221,182,202,222,183,203,223,184,204,224,185,
	  205,225,186,206,226,187,207,227,188,208,228,189,209,229,190,210,
	  230,191,211,231,192,212,232,193,213,233,234,260,286,235,261,287,
	  236,262,288,237,263,289,238,264,290,239,265,291,240,266,292,241,
	  267,293,242,268,294,243,269,295,244,270,296,245,271,297,246,272,
	  298,247,273,299,248,274,300,249,275,301,250,276,302,251,277,303,
	  252,278,304,253,279,305,254,280,306,255,281,307,256,282,308,257,
	  283,309,258,284,310,259,285,311,312,346,380,313,347,381,314,348,
	  382,315,349,383,316,350,384,317,351,385,318,352,386,319,353,387,
	  320,354,388,321,355,389,322,356,390,323,357,391,324,358,392,325,
	  359,393,326,360,394,327,361,395,328,362,396,329,363,397,330,364,
	  398,331,365,399,332,366,400,333,367,401,334,368,402,335,369,403,
	  336,370,404,337,371,405,338,372,406,339,373,407,340,374,408,341,
	  375,409,342,376,410,343,377,411,344,378,412,345,379,413,414,456,
	  498,415,457,499,416,458,500,417,459,501,418,460,502,419,461,503,
	  420,462,504,421,463,505,422,464,506,423,465,507,424,466,508,425,
	  467,509,426,468,510,427,469,511,428,470,512,429,471,513,430,472,
	  514,431,473,515,432,474,516,433,475,517,434,476,518,435,477,519,
	  436,478,520,437,479,521,438,480,522,439,481,523,440,482,524,441,
	  483,525,442,484,526,443,485,527,444,486,528,445,487,529,446,488,
	  530,447,489,531,448,490,532,449,491,533,450,492,534,451,493,535,
	  452,494,536,453,495,537,454,496,538,455,497,539,540,552,564,541,
	  553,565,542,554,566,543,555,567,544,556,568,545,557,569,546,558,
	  570,547,559,571,548,560,572,549,561,573,550,562,574,551,563,575}
	};
*/
    
    private static var cs : Array<Dynamic> = 
        [
        0.857492925712, 0.881741997318, 0.949628649103, 0.983314592492, 
        0.995517816065, 0.999160558175, 0.999899195243, 0.999993155067
    ];
    
    private static var ca : Array<Dynamic> = 
        [
        -0.5144957554270, -0.4717319685650, -0.3133774542040, -0.1819131996110, 
        -0.0945741925262, -0.0409655828852, -0.0141985685725, -0.00369997467375
    ];
    
    /************************************************************/
    /*                       END OF L3TABLE                     */
    /************************************************************/
    
    /************************************************************/
    /*                            L3TYPE                        */
    /************************************************************/
    
    
    /***************************************************************/
    /*                          END OF L3TYPE                      */
    /***************************************************************/
    
    /***************************************************************/
    /*                             INV_MDCT                        */
    /***************************************************************/
    public static var win : Array<Dynamic> = 
        [
        [-1.6141214951e-02, -5.3603178919e-02, -1.0070713296e-01, -1.6280817573e-01, 
        -4.9999999679e-01, -3.8388735032e-01, -6.2061144372e-01, -1.1659756083e + 00, 
        -3.8720752656e + 00, -4.2256286556e + 00, -1.5195289984e + 00, -9.7416483388e-01, 
        -7.3744074053e-01, -1.2071067773e + 00, -5.1636156596e-01, -4.5426052317e-01, 
        -4.0715656898e-01, -3.6969460527e-01, -3.3876269197e-01, -3.1242222492e-01, 
        -2.8939587111e-01, -2.6880081906e-01, -5.0000000266e-01, -2.3251417468e-01, 
        -2.1596714708e-01, -2.0004979098e-01, -1.8449493497e-01, -1.6905846094e-01, 
        -1.5350360518e-01, -1.3758624925e-01, -1.2103922149e-01, -2.0710679058e-01, 
        -8.4752577594e-02, -6.4157525656e-02, -4.1131172614e-02, -1.4790705759e-02
    ], 
        
        [-1.6141214951e-02, -5.3603178919e-02, -1.0070713296e-01, -1.6280817573e-01, 
        -4.9999999679e-01, -3.8388735032e-01, -6.2061144372e-01, -1.1659756083e + 00, 
        -3.8720752656e + 00, -4.2256286556e + 00, -1.5195289984e + 00, -9.7416483388e-01, 
        -7.3744074053e-01, -1.2071067773e + 00, -5.1636156596e-01, -4.5426052317e-01, 
        -4.0715656898e-01, -3.6969460527e-01, -3.3908542600e-01, -3.1511810350e-01, 
        -2.9642226150e-01, -2.8184548650e-01, -5.4119610000e-01, -2.6213228100e-01, 
        -2.5387916537e-01, -2.3296291359e-01, -1.9852728987e-01, -1.5233534808e-01, 
        -9.6496400054e-02, -3.3423828516e-02, 0.0000000000e + 00, 0.0000000000e + 00, 
        0.0000000000e + 00, 0.0000000000e + 00, 0.0000000000e + 00, 0.0000000000e + 00
    ], 
        
        [-4.8300800645e-02, -1.5715656932e-01, -2.8325045177e-01, -4.2953747763e-01, 
        -1.2071067795e + 00, -8.2426483178e-01, -1.1451749106e + 00, -1.7695290101e + 00, 
        -4.5470225061e + 00, -3.4890531002e + 00, -7.3296292804e-01, -1.5076514758e-01, 
        0.0000000000e + 00, 0.0000000000e + 00, 0.0000000000e + 00, 0.0000000000e + 00, 
        0.0000000000e + 00, 0.0000000000e + 00, 0.0000000000e + 00, 0.0000000000e + 00, 
        0.0000000000e + 00, 0.0000000000e + 00, 0.0000000000e + 00, 0.0000000000e + 00, 
        0.0000000000e + 00, 0.0000000000e + 00, 0.0000000000e + 00, 0.0000000000e + 00, 
        0.0000000000e + 00, 0.0000000000e + 00, 0.0000000000e + 00, 0.0000000000e + 00, 
        0.0000000000e + 00, 0.0000000000e + 00, 0.0000000000e + 00, 0.0000000000e + 00
    ], 
        
        [0.0000000000e + 00, 0.0000000000e + 00, 0.0000000000e + 00, 0.0000000000e + 00, 
        0.0000000000e + 00, 0.0000000000e + 00, -1.5076513660e-01, -7.3296291107e-01, 
        -3.4890530566e + 00, -4.5470224727e + 00, -1.7695290031e + 00, -1.1451749092e + 00, 
        -8.3137738100e-01, -1.3065629650e + 00, -5.4142014250e-01, -4.6528974900e-01, 
        -4.1066990750e-01, -3.7004680800e-01, -3.3876269197e-01, -3.1242222492e-01, 
        -2.8939587111e-01, -2.6880081906e-01, -5.0000000266e-01, -2.3251417468e-01, 
        -2.1596714708e-01, -2.0004979098e-01, -1.8449493497e-01, -1.6905846094e-01, 
        -1.5350360518e-01, -1.3758624925e-01, -1.2103922149e-01, -2.0710679058e-01, 
        -8.4752577594e-02, -6.4157525656e-02, -4.1131172614e-02, -1.4790705759e-02
    ]
    ];
    /***************************************************************/
    /*                         END OF INV_MDCT                     */
    /***************************************************************/
    
    public var sftable : Sftable;
    
    public static var nr_of_sfb_block : Array<Dynamic> = 
        [[[6, 5, 5, 5], [9, 9, 9, 9], [6, 9, 9, 9]], 
        [[6, 5, 7, 3], [9, 9, 12, 6], [6, 9, 12, 6]], 
        [[11, 10, 0, 0], [18, 18, 0, 0], [15, 18, 0, 0]], 
        [[7, 7, 7, 0], [12, 12, 12, 0], [6, 15, 12, 0]], 
        [[6, 6, 6, 3], [12, 9, 9, 6], [6, 12, 9, 6]], 
        [[8, 8, 5, 0], [15, 12, 9, 0], [6, 18, 9, 0]]
    ];
}


