/*
 * 06/01/07 	Ported to ActionScript 3. By Jean-Denis Boivin 
 *				(jeandenis.boivin@gmail.com) From Team-AtemiS.com
 *
 * 11/19/04		1.0 moved to LGPL.
 *
 * 12/12/99		Initial version.	mdm@techie.com
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
	 * Instances of <code>BitstreamException</code> are thrown 
	 * when operations on a <code>Bitstream</code> fail. 
	 * <p>
	 * The exception provides details of the exception condition 
	 * in two ways:
	 * <ol><li>
	 *		as an error-code describing the nature of the error
	 * </li><br></br><li>
	 *		as the <code>Throwable</code> instance, if any, that was thrown
	 *		indicating that an exceptional condition has occurred. 
	 * </li></ol></p>
	 * 
	 * @since 0.0.6
	 * @author MDM	12/12/99
	 */
class BitstreamException extends JavaLayerException
{
    public static inline var BITSTREAM_ERROR : Int = 0;
    /**
		 * An undeterminable error occurred. 
		 */
    public static var UNKNOWN_ERROR : Int = BITSTREAM_ERROR + 0;
    
    /**
		 * The header describes an unknown sample rate.
		 */
    public static var UNKNOWN_SAMPLE_RATE : Int = BITSTREAM_ERROR + 1;
    
    /**
		 * A problem occurred reading from the stream.
		 */
    public static var STREAM_ERROR : Int = BITSTREAM_ERROR + 2;
    
    /**
		 * The end of the stream was reached prematurely. 
		 */
    public static var UNEXPECTED_EOF : Int = BITSTREAM_ERROR + 3;
    
    /**
		 * The end of the stream was reached. 
		 */
    public static var STREAM_EOF : Int = BITSTREAM_ERROR + 4;
    
    /**
		 * Frame data are missing. 
		 */
    public static var INVALIDFRAME : Int = BITSTREAM_ERROR + 5;
    
    /**
		 * 
		 */
    public static inline var BITSTREAM_LAST : Int = 0x1ff;
    
    private var errorcode : Int = UNKNOWN_ERROR;
    
    public function new(errorcode : Dynamic, t : Error = null)
    {
        super();
        if (Std.is(errorcode, Int))
        {
            super(getErrorString(as3hx.Compat.parseInt(errorcode)), t);
            this.errorcode = as3hx.Compat.parseInt(errorcode);
        }
        else
        {
            if (Std.is(errorcode, String))
            {
                throw new Error(Std.string(errorcode));
            }
        }
    }
    
    public function getErrorCode() : Int
    {
        return errorcode;
    }
    
    
    public static function getErrorString(errorcode : Int) : String
    {
        // REVIEW: use resource bundle to map error codes
        // to locale-sensitive strings.
        var a : Array<Dynamic> = new Array<Dynamic>();
        return "Bitstream errorcode " + Std.string(errorcode);
    }
}

