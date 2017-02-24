/* 
 * 06/01/07  Ported to ActionScript 3. By Jean-Denis Boivin 
 *			 (jeandenis.boivin@gmail.com) From Team-AtemiS.com
 *
 * 11/19/04	 1.0 moved to LGPL.
 * 
 * 12/12/99  Initial Version based on FileObuffer.	mdm@techie.com.
 * 
 * FileObuffer:
 * 15/02/99  Java Conversion by E.B ,javalayer@javazoom.net
 *
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
	 * The <code>SampleBuffer</code> class implements an output buffer
	 * that provides storage for a fixed size block of samples. 
	 */
class SampleBuffer extends Obuffer
{
    private var buffer : Array<Dynamic>;
    private var bufferp : Array<Dynamic>;
    private var channels : Int;
    private var frequency : Int;
    
    /**
	   * Constructor
	   */
    public function new(sample_frequency : Int, number_of_channels : Int)
    {
        super();
        buffer = new Array<Dynamic>(OBUFFERSIZE);
        bufferp = new Array<Dynamic>(MAXCHANNELS);
        channels = number_of_channels;
        frequency = sample_frequency;
        
        for (i in 0...number_of_channels)
        {
            bufferp[i] = i;
        }
    }
    
    public function getChannelCount() : Int
    {
        return this.channels;
    }
    
    public function getSampleFrequency() : Int
    {
        return this.frequency;
    }
    
    public function getBuffer() : Array<Dynamic>
    {
        return this.buffer;
    }
    
    public function getBufferLength() : Int
    {
        return bufferp[0];
    }
    
    /**
	   * Takes a 16 Bit PCM sample.
	   */
    override public function append(channel : Int, value : Int) : Void
    {
        Reflect.setField(buffer, Std.string(bufferp[channel]), value);
        bufferp[channel] += channels;
    }
    
    override public function appendSamples(channel : Int, f : Array<Dynamic>) : Void
    {
        //trace(f);
        var pos : Int = bufferp[channel];
        var s : Int;
        var fs : Float;
        var i : Int = 0;
        while (i < 32)
        {
            fs = f[i++];
            fs = ((fs > 32767.0) ? 32767.0 : (fs < -(32767.0) ? -32767.0 : fs));
            
            s = as3hx.Compat.parseInt(fs);
            buffer[pos] = s;
            pos += channels;
        }
        
        bufferp[channel] = pos;
    }
    
    
    /**
	   * Write the samples to the file (Random Acces).
	   */
    override public function write_buffer(val : Int) : Void
    {
        //for (int i = 0; i < channels; ++i)
        //	bufferp[i] = (short)i;
        
        
    }
    
    override public function close() : Void
    {
    }
    
    /**
	   *
	   */
    override public function clear_buffer() : Void
    {
        for (i in 0...channels)
        {
            bufferp[i] = i;
        }
    }
    
    /**
	   *
	   */
    override public function set_stop_flag() : Void
    {
    }
}

