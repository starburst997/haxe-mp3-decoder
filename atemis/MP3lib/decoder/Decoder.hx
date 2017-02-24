/*
 * 06/01/07  	Ported to ActionScript 3. By Jean-Denis Boivin 
 *			 	(jeandenis.boivin@gmail.com) From Team-AtemiS.com
 *
 * 11/19/04		1.0 moved to LGPL.
 *
 * 01/12/99		Initial version.	mdm@techie.com
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

import flash.errors.Error;

/**
	 * The <code>Decoder</code> class encapsulates the details of
	 * decoding an MPEG audio frame. 
	 * 
	 * @author	MDM	
	 * @version 0.0.7 12/12/99
	 * @since	0.0.5
	 */
class Decoder
{
    private static var DEFAULT_PARAMS : Params = new Params();
    
    private static inline var DECODER_ERROR : Int = 0;
    
    public static var UNKNOWN_ERROR : Int = DECODER_ERROR + 0;
    
    /**
		 * Layer not supported by the decoder. 
		 */
    public static var UNSUPPORTED_LAYER : Int = DECODER_ERROR + 1;
    
    /**
		 * The Bistream from which the MPEG audio frames are read.
		 */
    //private Bitstream				stream;
    
    /**
		 * The Obuffer instance that will receive the decoded
		 * PCM samples.
		 */
    private var output : Obuffer;
    
    /**
		 * Synthesis filter for the left channel.
		 */
    private var filter1 : SynthesisFilter;
    
    /**
		 * Sythesis filter for the right channel.
		 */
    private var filter2 : SynthesisFilter;
    
    /**
		 * The decoder used to decode layer III frames.
		 */
    private var l3decoder : LayerIIIDecoder;
    //private var						l2decoder:LayerIIDecoder;
    private var l1decoder : LayerIDecoder;
    
    private var outputFrequency : Int;
    private var outputChannels : Int;
    
    private var equalizer : Equalizer = new Equalizer();
    
    private var params : Params;
    
    private var initialized : Bool;
    
    
    /**
		 * Creates a new <code>Decoder</code> instance with default 
		 * parameters.
		 */
    
    /**
		 * Creates a new <code>Decoder</code> instance with default 
		 * parameters.
		 * 
		 * @param params	The <code>Params</code> instance that describes
		 *					the customizable aspects of the decoder.  
		 */
    public function new(params0 : Params = null)
    {
        if (params0 == null)
        {
            params0 = DEFAULT_PARAMS;
        }
        
        params = params0;
        
        var eq : Equalizer = params.getInitialEqualizerSettings();
        if (eq != null)
        {
            equalizer.setFrom(eq);
        }
    }
    
    public static function getDefaultParams() : Params
    {
        return try cast(DEFAULT_PARAMS.clone(), Params) catch(e:Dynamic) null;
    }
    
    public function setEqualizer(eq : Equalizer) : Void
    {
        if (eq == null)
        {
            eq = Equalizer.PASS_THRU_EQ;
        }
        
        equalizer.setFrom(eq);
        
        var factors : Array<Dynamic> = equalizer.getBandFactors();
        
        if (filter1 != null)
        {
            filter1.setEQ(factors);
        }
        
        if (filter2 != null)
        {
            filter2.setEQ(factors);
        }
    }
    
    /**
		 * Decodes one frame from an MPEG audio bitstream.
		 * 
		 * @param header		The header describing the frame to decode.
		 * @param bitstream		The bistream that provides the bits for te body of the frame. 
		 * 
		 * @return A SampleBuffer containing the decoded samples.
		 */
    public function decodeFrame(header : Header, stream : Bitstream) : Obuffer
    {
        if (!initialized)
        {
            initialize(header);
        }
        
        var layer : Int = header.layer();
        
        output.clear_buffer();
        
        var decoder : FrameDecoder = retrieveDecoder(header, stream, layer);
        
        decoder.decodeFrame();
        
        output.write_buffer(1);
        
        return output;
    }
    
    /**
		 * Changes the output buffer. This will take effect the next time
		 * decodeFrame() is called. 
		 */
    public function setOutputBuffer(out : Obuffer) : Void
    {
        output = out;
    }
    
    /**
		 * Retrieves the sample frequency of the PCM samples output
		 * by this decoder. This typically corresponds to the sample
		 * rate encoded in the MPEG audio stream.
		 * 
		 * @param the sample rate (in Hz) of the samples written to the
		 *		output buffer when decoding. 
		 */
    public function getOutputFrequency() : Int
    {
        return outputFrequency;
    }
    
    /**
		 * Retrieves the number of channels of PCM samples output by
		 * this decoder. This usually corresponds to the number of
		 * channels in the MPEG audio stream, although it may differ.
		 * 
		 * @return The number of output channels in the decoded samples: 1 
		 *		for mono, or 2 for stereo.
		 *		
		 */
    public function getOutputChannels() : Int
    {
        return outputChannels;
    }
    
    /**
		 * Retrieves the maximum number of samples that will be written to
		 * the output buffer when one frame is decoded. This can be used to
		 * help calculate the size of other buffers whose size is based upon 
		 * the number of samples written to the output buffer. NB: this is
		 * an upper bound and fewer samples may actually be written, depending
		 * upon the sample rate and number of channels.
		 * 
		 * @return The maximum number of samples that are written to the 
		 *		output buffer when decoding a single frame of MPEG audio.
		 */
    public function getOutputBlockSize() : Int
    {
        return Obuffer.OBUFFERSIZE;
    }
    
    
    private function newDecoderException(errorcode : Int, throwable : Error = null) : Error
    {
        return new Error("Error " + errorcode);
    }
    
    private function retrieveDecoder(header : Header, stream : Bitstream, layer : Int) : FrameDecoder
    {
        var decoder : FrameDecoder = null;
        
        // REVIEW: allow channel output selection type
        // (LEFT, RIGHT, BOTH, DOWNMIX)
        switch (layer)
        {
            case 3:
                if (l3decoder == null)
                {
                    l3decoder = new LayerIIIDecoder(stream, 
                            header, filter1, filter2, 
                            output, OutputChannels.BOTH_CHANNELS);
                }
                
                decoder = l3decoder;
            /*case 2:
				if (l2decoder==null)
				{
					l2decoder = new LayerIIDecoder();
					l2decoder.create(stream, 
						header, filter1, filter2, 
						output, OutputChannels.BOTH_CHANNELS);				
				}
				decoder = l2decoder;
				break;*/
            case 1:
                if (l1decoder == null)
                {
                    l1decoder = new LayerIDecoder();
                    l1decoder.create(stream, 
                            header, filter1, filter2, 
                            output, OutputChannels.BOTH_CHANNELS
                );
                }
                decoder = l1decoder;
        }
        
        if (decoder == null)
        {
            throw new Error("Decoder " + UNSUPPORTED_LAYER);
        }
        
        return decoder;
    }
    
    private function initialize(header : Header) : Void
    {
        // REVIEW: allow customizable scale factor
        var scalefactor : Float = 32700.0;
        
        var mode : Int = header.mode();
        var layer : Int = header.layer();
        var channels : Int = (mode == Header.SINGLE_CHANNEL) ? 1 : 2;
        
        
        // set up output buffer if not set up by client.
        if (output == null)
        {
            output = new SampleBuffer(header.frequency(), channels);
        }
        
        var factors : Array<Dynamic> = equalizer.getBandFactors();
        filter1 = new SynthesisFilter(0, scalefactor, factors);
        
        // REVIEW: allow mono output for stereo
        if (channels == 2)
        {
            filter2 = new SynthesisFilter(1, scalefactor, factors);
        }
        
        outputChannels = channels;
        outputFrequency = header.frequency();
        
        initialized = true;
    }
}


