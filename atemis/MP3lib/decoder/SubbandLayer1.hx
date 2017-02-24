/*
 * 06/01/07  	Ported to ActionScript 3. By Jean-Denis Boivin
 *			 	(jeandenis.boivin@gmail.com) From Team-AtemiS.com
 *
 * 11/19/04		1.0 moved to LGPL.
 *
 * 12/12/99		Initial version. Adapted from javalayer.java
 *				and Subband*.java. mdm@techie.com
 *
 * 02/28/99		Initial version : javalayer.java by E.B
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
		 * Class for layer I subbands in single channel mode.
		 * Used for single channel mode
		 * and in derived class for intensity stereo mode
		 */
/*static*/class SubbandLayer1 extends Subband
{
    
    // Factors and offsets for sample requantization
    public static var table_factor : Array<Dynamic> = [
        0.0, (1.0 / 2.0) * (4.0 / 3.0), (1.0 / 4.0) * (8.0 / 7.0), (1.0 / 8.0) * (16.0 / 15.0), 
        (1.0 / 16.0) * (32.0 / 31.0), (1.0 / 32.0) * (64.0 / 63.0), (1.0 / 64.0) * (128.0 / 127.0), 
        (1.0 / 128.0) * (256.0 / 255.0), (1.0 / 256.0) * (512.0 / 511.0), 
        (1.0 / 512.0) * (1024.0 / 1023.0), (1.0 / 1024.0) * (2048.0 / 2047.0), 
        (1.0 / 2048.0) * (4096.0 / 4095.0), (1.0 / 4096.0) * (8192.0 / 8191.0), 
        (1.0 / 8192.0) * (16384.0 / 16383.0), (1.0 / 16384.0) * (32768.0 / 32767.0)
    ];
    
    public static var table_offset : Array<Dynamic> = [
        0.0, ((1.0 / 2.0) - 1.0) * (4.0 / 3.0), ((1.0 / 4.0) - 1.0) * (8.0 / 7.0), ((1.0 / 8.0) - 1.0) * (16.0 / 15.0), 
        ((1.0 / 16.0) - 1.0) * (32.0 / 31.0), ((1.0 / 32.0) - 1.0) * (64.0 / 63.0), ((1.0 / 64.0) - 1.0) * (128.0 / 127.0), 
        ((1.0 / 128.0) - 1.0) * (256.0 / 255.0), ((1.0 / 256.0) - 1.0) * (512.0 / 511.0), 
        ((1.0 / 512.0) - 1.0) * (1024.0 / 1023.0), ((1.0 / 1024.0) - 1.0) * (2048.0 / 2047.0), 
        ((1.0 / 2048.0) - 1.0) * (4096.0 / 4095.0), ((1.0 / 4096.0) - 1.0) * (8192.0 / 8191.0), 
        ((1.0 / 8192.0) - 1.0) * (16384.0 / 16383.0), ((1.0 / 16384.0) - 1.0) * (32768.0 / 32767.0)
    ];
    
    private var subbandnumber : Int;
    private var samplenumber : Int;
    private var allocation : Int;
    private var scalefactor : Float;
    private var samplelength : Int;
    private var sample : Float;
    private var factor : Float;private var offset : Float;
    
    /**
		   * Construtor.
		   */
    @:allow(atemis.mP3lib.decoder)
    private function new(subbandnumber : Int)
    {
        super();
        this.subbandnumber = subbandnumber;
        samplenumber = 0;
    }
    
    /**
		   *
		   */
    override public function read_allocation(stream : Bitstream, header : Header, crc : Crc16) : Void
    {
        allocation = stream.get_bits(4);
        //if ((allocation = stream.get_bits (4)) == 15) ;
        //	 cerr << "WARNING: stream contains an illegal allocation!\n";
        // MPEG-stream is corrupted!
        if (crc != null)
        {
            crc.add_bits(allocation, 4);
        }
        if (allocation != 0)
        {
            samplelength = as3hx.Compat.parseInt(allocation + 1);
            factor = table_factor[allocation];
            offset = table_offset[allocation];
        }
    }
    
    /**
		   *
		   */
    override public function read_scalefactor(stream : Bitstream, header : Header) : Void
    {
        if (allocation != 0)
        {
            scalefactor = scalefactors[stream.get_bits(6)];
        }
    }
    
    /**
		   *
		   */
    override public function read_sampledata(stream : Bitstream) : Bool
    {
        if (allocation != 0)
        {
            sample =  /*(float)*/  (stream.get_bits(samplelength));
        }
        if (++samplenumber == 12)
        {
            samplenumber = 0;
            return true;
        }
        return false;
    }
    
    /**
		   *
		   */
    override public function put_next_sample(channels : Int, filter1 : SynthesisFilter, filter2 : SynthesisFilter) : Bool
    {
        if ((allocation != 0) && (channels != OutputChannels.RIGHT_CHANNEL))
        {
            var scaled_sample : Float = (sample * factor + offset) * scalefactor;
            filter1.input_sample(scaled_sample, subbandnumber);
        }
        return true;
    }
}

