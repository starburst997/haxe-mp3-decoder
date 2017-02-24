/* 
 * 06/01/07  Ported to ActionScript 3. By Jean-Denis Boivin 
 *			 (jeandenis.boivin@gmail.com) From Team-AtemiS.com
 *
 * 11/19/04  1.0 moved to LGPL.
 *
 * 12/12/99  Added appendSamples() method for efficiency. MDM.
 *
 * 15/02/99 ,Java Conversion by E.B ,ebsp@iname.com, JavaLayer
 *
 *   Declarations for output buffer, includes operating system
 *   implementation of the virtual Obuffer. Optional routines
 *   enabling seeks and stops added by Jeff Tsay. 
 *
 *  @(#) obuffer.h 1.8, last edit: 6/15/94 16:51:56
 *  @(#) Copyright (C) 1993, 1994 Tobias Bading (bading@cs.tu-berlin.de)
 *  @(#) Berlin University of Technology
 *
 *  Idea and first implementation for u-law output with fast downsampling by
 *  Jim Boucher (jboucher@flash.bu.edu)
 *
 *  LinuxObuffer class written by
 *  Louis P. Kruger (lpkruger@phoenix.princeton.edu)
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
	 * Base Class for audio output.
	 */
class Obuffer
{
    public static var OBUFFERSIZE : Int = 2 * 1152;  // max. 2 * 1152 samples per frame  
    public static inline var MAXCHANNELS : Int = 2;  // max. number of channels  
    
    /**
	   * Takes a 16 Bit PCM sample.
	   */
    public function append(channel : Int, value : Int) : Void
    {
    }
    
    /**
	   * Accepts 32 new PCM samples. 
	   */
    public function appendSamples(channel : Int, f : Array<Dynamic>) : Void
    {
        var s : Int;
        var i : Int = 0;
        while (i < 32)
        {
            s = clip(f[i++]);
            append(channel, s);
        }
    }
    
    /**
	   * Clip Sample to 16 Bits
	   */
    private function clip(sample : Float) : Int
    {
        return (((sample > 32767.0)) ? 32767 : 
        (((sample < -32768.0)) ? -32768 : 
        sample));
    }
    
    /**
	   * Write the samples to the file or directly to the audio hardware.
	   */
    public function write_buffer(val : Int) : Void
    {
    }
    public function close() : Void
    {
    }
    
    /**
	   * Clears all data in the buffer (for seeking).
	   */
    public function clear_buffer() : Void
    {
    }
    
    /**
	   * Notify the buffer that the user has stopped the stream.
	   */
    public function set_stop_flag() : Void
    {
    }

    public function new()
    {
    }
}

