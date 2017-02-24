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
import flash.utils.ByteArray;

/**
	 * Recreate Java's PushbackInputStream function into ActionScript 3
	 */
class InputStream extends ByteArray
{
    
    private var marked : Int = 0;private var limit : Int = 0;
    
    /**
	   * Constructor
	   */
    public function new()
    {
        super();
    }
    
    /**
	 	 *  Marks the current position in this input stream. A subsequent call to the reset method repositions this stream at the last marked position so that subsequent reads re-read the same bytes. 
		 *
		 *	The readlimit arguments tells this input stream to allow that many bytes to be read before the mark position gets invalidated. 
		 *
		 *	The general contract of mark is that, if the method markSupported returns true, the stream somehow remembers all the bytes read after the call to mark and stands ready to supply those same bytes again if and whenever the method reset is called. However, the stream is not required to remember any data at all if more than readlimit bytes are read from the stream before reset is called. 
		 *	
		 *	The mark method of InputStream does nothing.
	 	 */
    public function mark(readlimit : Int) : Void
    {
        marked = position;
        limit = readlimit;
    }
    
    /**
	 	 *  Repositions this stream to the position at the time the mark method was last called on this input stream.
	 	 */
    public function reset() : Void
    {
        if (position <= marked + limit)
        {
            position = marked;
        }
        else
        {
            throw new Error("reset failed");
        }
    }
    
    /**
	 	 *  Reads up to len bytes of data from the input stream into an array of bytes. An attempt is made to read as many as len bytes, but a smaller number may be read. The number of bytes actually read is returned as an integer. 
		 *
		 *	This method blocks until input data is available, end of file is detected, or an exception is thrown.
	 	 */
    public function read(b : Array<Dynamic>, off : Int, len : Int) : Int
    {
        if (b == null)
        {
            throw new Error("Null pointer");
        }
        else
        {
            if ((off < 0) || (off > b.length) || (len < 0) ||
                ((off + len) > b.length) || ((off + len) < 0))
            {
                throw new Error("Out of Bound");
            }
            else
            {
                if (len == 0)
                {
                    return 0;
                }
            }
        }
        
        var c : Int = readUnsignedByte();
        if (c == -1)
        {
            return -1;
        }
        b[off] = c;
        
        var i : Int = 1;
        try
        {
            for (i in 1...len)
            {
                c = readUnsignedByte();
                if (c == -1)
                {
                    break;
                }
                if (b != null)
                {
                    b[off + i] = c;
                }
            }
        }
        catch (ee : Error)
        {
        }
        
        return i;
    }
    
    public function close() : Void
    {
    }
}

