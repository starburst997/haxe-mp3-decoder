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
		 * Class for layer I subbands in joint stereo mode.
		 */
/*static*/class SubbandLayer1IntensityStereo extends SubbandLayer1
{
    private var channel2_scalefactor : Float;
    
    /**
		   * Constructor
		   */
    @:allow(atemis.mP3lib.decoder)
    private function new(subbandnumber : Int)
    {
        super(subbandnumber);
    }
    
    /**
		   *
		   */
    override public function read_allocation(stream : Bitstream, header : Header, crc : Crc16) : Void
    {
        super.read_allocation(stream, header, crc);
    }
    
    /**
		   *
		   */
    override public function read_scalefactor(stream : Bitstream, header : Header) : Void
    {
        if (allocation != 0)
        {
            scalefactor = scalefactors[stream.get_bits(6)];
            channel2_scalefactor = scalefactors[stream.get_bits(6)];
        }
    }
    
    /**
		   *
		   */
    override public function read_sampledata(stream : Bitstream) : Bool
    {
        return super.read_sampledata(stream);
    }
    
    /**
		   *
		   */
    override public function put_next_sample(channels : Int, filter1 : SynthesisFilter, filter2 : SynthesisFilter) : Bool
    {
        var sample1 : Float;
        var sample2 : Float;
        if (allocation != 0)
        {
            sample = sample * factor + offset;  // requantization  
            if (channels == OutputChannels.BOTH_CHANNELS)
            {
                sample1 = sample * scalefactor;
                sample2 = sample * channel2_scalefactor;
                filter1.input_sample(sample1, subbandnumber);
                filter2.input_sample(sample2, subbandnumber);
            }
            else
            {
                if (channels == OutputChannels.LEFT_CHANNEL)
                {
                    sample1 = sample * scalefactor;
                    filter1.input_sample(sample1, subbandnumber);
                }
                else
                {
                    sample2 = sample * channel2_scalefactor;
                    filter1.input_sample(sample2, subbandnumber);
                }
            }
        }
        return true;
    }
}

