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


/**
	 * Recreate Java's PushbackInputStream function into ActionScript 3
	 */
@:final class ByteArrayInputStream extends InputStream
{
    
    private var buf : Array<Dynamic>;
    
    private var pos : Int;
    
    private var count : Int;
    
    /**
	   * Constructor
	   */
    public function new(buf : Array<Dynamic>)
    {
        super();
        this.buf = buf;
        this.pos = 0;
        this.count = buf.length;
    }
}

