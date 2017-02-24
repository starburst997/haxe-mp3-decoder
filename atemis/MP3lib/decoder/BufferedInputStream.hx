/*
 * 06/01/07 	By Jean-Denis Boivin 
 *				(jeandenis.boivin@gmail.com) From Team-AtemiS.com
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

import flash.errors.Error;

/**
	 * Recreate Java's PushbackInputStream function into ActionScript 3
	 */
@:final class BufferedInputStream extends FilterInputStream
{
    
    private static inline var DEFAULT_BUFFER_SIZE : Int = 2048;
    
    private var buf : Array<Dynamic>;
    
    private var pos : Int;
    
    private var count : Int;
    
    private var bufferSize : Int;
    
    /**
	   * Constructor
	   */
    
    public function new(inB : InputStream, size : Int = DEFAULT_BUFFER_SIZE)
    {
        super(inB);
        if (size <= 0)
        {
            throw new Error("bad size");
        }
        buf = new Array<Dynamic>(size);
        // initialize pos & count to bufferSize, to prevent refill from
        // allocating a new buffer (if the caller starts out by calling mark()).
        pos = count = bufferSize = size;
    }
}

