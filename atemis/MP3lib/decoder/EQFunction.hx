/*
 * 06/01/07  	Ported to ActionScript 3. By Jean-Denis Boivin 
 *			 	(jeandenis.boivin@gmail.com) From Team-AtemiS.com
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


/**
	 * The <code>Equalizer</code> class can be used to specify
	 * equalization settings for the MPEG audio decoder. 
	 * <p>
	 * The equalizer consists of 32 band-pass filters. 
	 * Each band of the equalizer can take on a fractional value between 
	 * -1.0 and +1.0.
	 * At -1.0, the input signal is attenuated by 6dB, at +1.0 the signal is
	 * amplified by 6dB. 
	 * 
	 * @see Decoder
	 * 
	 * @author MDM
	 */
class EQFunction
{
    /**
		 * Returns the setting of a band in the equalizer. 
		 * 
		 * @param band	The index of the band to retrieve the setting
		 *				for. 
		 * 
		 * @return		the setting of the specified band. This is a value between
		 *				-1 and +1.
		 */
    public function getBand(band : Int) : Float
    {
        return 0.0;
    }

    @:allow(atemis.mP3lib.decoder)
    private function new()
    {
    }
}

