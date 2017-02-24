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
/**
		 * The <code>Params</code> class presents the customizable
		 * aspects of the decoder. 
		 * <p>
		 * Instances of this class are not thread safe. 
		 */
class Params
{
    private var outputChannels : OutputChannels = OutputChannels.BOTH;
    
    private var equalizer : Equalizer = new Equalizer();
    
    public function new()
    {
    }
    
    public function clone() : Dynamic
    {
        return this;
    }
    
    public function setOutputChannels(out : OutputChannels) : Void
    {
        if (out == null)
        {
            throw new Error("out");
        }
        
        outputChannels = out;
    }
    
    public function getOutputChannels() : OutputChannels
    {
        return outputChannels;
    }
    
    /**
			 * Retrieves the equalizer settings that the decoder's equalizer
			 * will be initialized from.
			 * <p>
			 * The <code>Equalizer</code> instance returned 
			 * cannot be changed in real time to affect the 
			 * decoder output as it is used only to initialize the decoders
			 * EQ settings. To affect the decoder's output in realtime,
			 * use the Equalizer returned from the getEqualizer() method on
			 * the decoder. 
			 * 
			 * @return	The <code>Equalizer</code> used to initialize the
			 *			EQ settings of the decoder. 
			 */
    public function getInitialEqualizerSettings() : Equalizer
    {
        return equalizer;
    }
}

