/**
 *
 *	MP3Event class
 *	
 *	@author		Jean-Denis Boivin aka Starburst - www.team-atemis.com
 *	@version	1.0
 * 	@date 		2007-06-08
 * 	@link		http://www.team-atemis.com/atemis-demo
 * 
 * 	AUTHORS ******************************************************************************
 * 
 *	authorName : 	Jean-Denis Boivin - www.team-atemis.com
 * 	contribution : 	Everything
 * 	date :			2007-06-08
 * 
 * 	DESCRIPTION **************************************************************************
 * 
 * 	Events for the Player
 *
 *	LICENSE ******************************************************************************
 * 
 * 	This class is under copyright.
 * 	Please, keep this header and the list of all authors
 * 
 */
/////////////////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 2007 Team-AtemiS and its licensors.
//  All Rights Reserved. The following is Source Code and is subject to all
//  restrictions on such code as contained in the End User License Agreement
//  accompanying this product.
//
/////////////////////////////////////////////////////////////////////////////////
package atemis.mP3lib.events;

import flash.events.Event;
import flash.utils.ByteArray;

/**
	 * Events for the Player
	 */
class MP3Event extends Event
{
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------
    
    /**
	 	 *  Constructor.
	 	 */
    public function new(type : String, MP3Data : ByteArray, bubbles : Bool = false, cancelable : Bool = false)
    {
        super(type, bubbles, cancelable);
        
        this.MP3Data = MP3Data;
    }
    
    //--------------------------------------------------------------------------
    //
    //  Variables
    //
    //--------------------------------------------------------------------------
    
    /**
	 	 *  Dispatch when a MP3 has been fully decoded.
	 	 */
    public static inline var DECODED : String = "decoded";
    
    /**
	 	 *  The ByteArray that represent the MP3's PCM Data
	 	 */
    public var MP3Data : ByteArray;
}

