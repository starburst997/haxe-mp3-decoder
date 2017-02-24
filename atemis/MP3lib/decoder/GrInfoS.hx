/*
 * 06/01/07  Ported to ActionScript 3. By Jean-Denis Boivin 
 *			 (jeandenis.boivin@gmail.com) From Team-AtemiS.com
 *
 * 11/19/04	 1.0 moved to LGPL.
 * 
 * 18/06/01  Michael Scheerer,  Fixed bugs which causes
 *           negative indexes in method huffmann_decode and in method 
 *           dequanisize_sample.
 *
 * 16/07/01  Michael Scheerer, Catched a bug in method
 *           huffmann_decode, which causes an outOfIndexException.
 *           Cause : Indexnumber of 24 at SfBandIndex,
 *           which has only a length of 22. I have simply and dirty 
 *           fixed the index to <= 22, because I'm not really be able
 *           to fix the bug. The Indexnumber is taken from the MP3 
 *           file and the origin Ma-Player with the same code works 
 *           well.      
 * 
 * 02/19/99  Java Conversion by E.B, javalayer@javazoom.net
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
 * Class Implementing Layer 3 Decoder.
 *
 * @since 0.0
 */
class GrInfoS
{
    public var part2_3_length : Int = 0;
    public var big_values : Int = 0;
    public var global_gain : Int = 0;
    public var scalefac_compress : Int = 0;
    public var window_switching_flag : Int = 0;
    public var block_type : Int = 0;
    public var mixed_block_flag : Int = 0;
    public var table_select : Array<Dynamic>;
    public var subblock_gain : Array<Dynamic>;
    public var region0_count : Int = 0;
    public var region1_count : Int = 0;
    public var preflag : Int = 0;
    public var scalefac_scale : Int = 0;
    public var count1table_select : Int = 0;
    
    /**
		 * Dummy Constructor
		 */
    @:allow(atemis.mP3lib.decoder)
    private function new()
    {
        table_select = new Array<Dynamic>(3);
        subblock_gain = new Array<Dynamic>(3);
    }
}


