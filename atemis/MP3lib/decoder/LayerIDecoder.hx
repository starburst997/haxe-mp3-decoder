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
	 * Implements decoding of MPEG Audio Layer I frames. 
	 */
class LayerIDecoder implements FrameDecoder
{
    private var stream : Bitstream;
    private var header : Header;
    private var filter1 : SynthesisFilter;private var filter2 : SynthesisFilter;
    private var buffer : Obuffer;
    private var which_channels : Int;
    private var mode : Int;
    
    private var num_subbands : Int;
    private var subbands : Array<Dynamic>;
    private var crc : Crc16 = null;  // new Crc16[1] to enable CRC checking.  
    
    @:allow(atemis.mP3lib.decoder)
    private function new()
    {
        crc = new Crc16();
    }
    
    public function create(stream0 : Bitstream, header0 : Header,
            filtera : SynthesisFilter, filterb : SynthesisFilter,
            buffer0 : Obuffer, which_ch0 : Int) : Void
    {
        stream = stream0;
        header = header0;
        filter1 = filtera;
        filter2 = filterb;
        buffer = buffer0;
        which_channels = which_ch0;
    }
    
    
    
    public function decodeFrame() : Void
    {
        num_subbands = header.number_of_subbands();
        subbands = new Array<Dynamic>(32);
        mode = header.mode();
        
        createSubbands();
        
        readAllocation();
        readScaleFactorSelection();
        
        if ((crc != null) || header.checksum_ok())
        {
            readScaleFactors();
            
            readSampleData();
        }
    }
    
    private function createSubbands() : Void
    {
        var i : Int;
        if (mode == Header.SINGLE_CHANNEL)
        {
            for (i in 0...num_subbands)
            {
                subbands[i] = new SubbandLayer1(i);
            }
        }
        else
        {
            if (mode == Header.JOINT_STEREO)
            {
                for (i in 0...header.intensity_stereo_bound())
                {
                    subbands[i] = new SubbandLayer1Stereo(i);
                }
                for (i in i...num_subbands)
                {
                    subbands[i] = new SubbandLayer1IntensityStereo(i);
                }
            }
            else
            {
                for (i in 0...num_subbands)
                {
                    subbands[i] = new SubbandLayer1Stereo(i);
                }
            }
        }
    }
    
    private function readAllocation() : Void
    {
        // start to read audio data:
        for (i in 0...num_subbands)
        {
            subbands[i].read_allocation(stream, header, crc);
        }
    }
    
    private function readScaleFactorSelection() : Void
    {  // scale factor selection not present for layer I.  
        
    }
    
    private function readScaleFactors() : Void
    {
        for (i in 0...num_subbands)
        {
            subbands[i].read_scalefactor(stream, header);
        }
    }
    
    private function readSampleData() : Void
    {
        var read_ready : Bool = false;
        var write_ready : Bool = false;
        var mode : Int = header.mode();
        var i : Int;
        do
        {
            for (i in 0...num_subbands)
            {
                read_ready = subbands[i].read_sampledata(stream);
            }
            do
            {
                for (i in 0...num_subbands)
                {
                    write_ready = subbands[i].put_next_sample(which_channels, filter1, filter2);
                }
                
                filter1.calculate_pcm_samples(buffer);
                if ((which_channels == OutputChannels.BOTH_CHANNELS) && (mode != Header.SINGLE_CHANNEL))
                {
                    filter2.calculate_pcm_samples(buffer);
                }
            }
            while ((!write_ready));
        }
        while ((!read_ready));
    }
}

