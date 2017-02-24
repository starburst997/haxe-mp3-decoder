/*
 * 06/01/07  Ported to ActionScript 3. By Jean-Denis Boivin 
 *			 (jeandenis.boivin@gmail.com) From Team-AtemiS.com
 *
 * 11/19/04  1.0 moved to LGPL.
 * 
 * 11/17/04	 Uncomplete frames discarded. E.B, javalayer@javazoom.net 
 *
 * 12/05/03	 ID3v2 tag returned. E.B, javalayer@javazoom.net 
 *
 * 12/12/99	 Based on Ibitstream. Exceptions thrown on errors,
 *			 Temporary removed seek functionality. mdm@techie.com
 *
 * 02/12/99 : Java Conversion by E.B , javalayer@javazoom.net
 *
 * 04/14/97 : Added function prototypes for new syncing and seeking
 * mechanisms. Also made this file portable. Changes made by Jeff Tsay
 *
 *  @(#) ibitstream.h 1.5, last edit: 6/15/94 16:55:34
 *  @(#) Copyright (C) 1993, 1994 Tobias Bading (bading@cs.tu-berlin.de)
 *  @(#) Berlin University of Technology
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
	 * The <code>Bistream</code> class is responsible for parsing
	 * an MPEG audio bitstream.
	 *
	 * <b>REVIEW:</b> much of the parsing currently occurs in the
	 * various decoders. This should be moved into this class and associated
	 * inner classes.
	 */
@:final class Bitstream
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
		 * Synchronization control constant for the initial
		 * synchronization to the start of a frame.
		 */
    public static var INITIAL_SYNC : Int = 0;
    
    /**
		 * Synchronization control constant for non-initial frame
		 * synchronizations.
		 */
    public static var STRICT_SYNC : Int = 1;
    
    // max. 1730 bytes per frame: 144 * 384kbit/s / 32000 Hz + 2 Bytes CRC
    /**
		 * Maximum size of the frame buffer.
		 */
    private static inline var BUFFER_INT_SIZE : Int = 433;
    
    /**
		 * The frame buffer that holds the data for the current frame.
		 */
    private var framebuffer : Array<Dynamic> = new Array<Dynamic>(BUFFER_INT_SIZE);
    
    /**
		 * Number of valid bytes in the frame buffer.
		 */
    private var framesize : Int;
    
    /**
		 * The bytes read from the stream.
		 */
    private var frame_bytes : Array<Dynamic> = new Array<Dynamic>(BUFFER_INT_SIZE * 4);
    
    /**
		 * Index into <code>framebuffer</code> where the next bits are
		 * retrieved.
		 */
    private var wordpointer : Int;
    
    /**
		 * Number (0-31, from MSB to LSB) of next bit for get_bits()
		 */
    private var bitindex : Int;
    
    /**
		 * The current specified syncword
		 */
    private var syncword : Int;
    
    /**
		 * Audio header position in stream.
		 */
    private var header_posz : Int = 0;
    
    /**
		 *
		 */
    private var single_ch_mode : Bool;
    //private int 			current_frame_number;
    //private int				last_frame_number;
    
    private var bitmask : Array<Dynamic> = [0,   // dummy  
        0x00000001, 0x00000003, 0x00000007, 0x0000000F, 
        0x0000001F, 0x0000003F, 0x0000007F, 0x000000FF, 
        0x000001FF, 0x000003FF, 0x000007FF, 0x00000FFF, 
        0x00001FFF, 0x00003FFF, 0x00007FFF, 0x0000FFFF, 
        0x0001FFFF
    ];
    
    private var source : PushbackInputStream;
    
    private var header : Header = new Header();
    
    private var syncbuf : Array<Dynamic> = new Array<Dynamic>(4);
    
    private var crc : Array<Dynamic> = new Array<Dynamic>(1);
    
    private var rawid3v2 : Array<Dynamic> = null;
    
    private var firstframe : Bool = true;
    
    
    /**
		 * Construct a IBitstream that reads data from a
		 * given InputStream.
		 *
		 * @param in	The InputStream to read from.
		 */
    public function new(inB : InputStream)
    {
        if (inB == null)
        {
            throw new Error("inB");
        }
        inB = new BufferedInputStream(inB);
        loadID3v2(inB);
        firstframe = true;
        //source = new PushbackInputStream(inB, 1024);
        source = new PushbackInputStream(inB, BUFFER_INT_SIZE * 4);
        
        closeFrame();
    }
    
    /**
		 * Return position of the first audio header.
		 * @return size of ID3v2 tag frames.
		 */
    public function header_pos() : Int
    {
        return header_posz;
    }
    
    /**
		 * Load ID3v2 frames.
		 * @param in MP3 InputStream.
		 * @author JavaZOOM
		 */
    private function loadID3v2(inB : InputStream) : Void
    {
        var size : Int = -1;
        try
        {
            // Read ID3v2 header (10 bytes).
            inB.mark(10);
            size = readID3v2Header(inB);
            header_posz = size;
        }
        catch (e : Error)
        {
        }
        finally;{
            try
            {
                // Unread ID3v2 header (10 bytes).
                inB.reset();
            }
            catch (e : Error)
            {
            }
        }
        // Load ID3v2 tags.
        try
        {
            if (size > 0)
            {
                rawid3v2 = new Array<Dynamic>(size);
                inB.read(rawid3v2, 0, rawid3v2.length);
            }
        }
        catch (e : Error)
        {
        }
    }
    
    /**
		 * Parse ID3v2 tag header to find out size of ID3v2 frames. 
		 * @param in MP3 InputStream
		 * @return size of ID3v2 frames + header
		 * @throws IOException
		 * @author JavaZOOM
		 */
    private function readID3v2Header(inB : InputStream) : Int
    {
        var id3header : Array<Dynamic> = new Array<Dynamic>(4);
        var size : Int = -10;
        inB.read(id3header, 0, 3);
        // Look for ID3v2
        if ((id3header[0] == ("I").charCodeAt()) && (id3header[1] == ("D").charCodeAt()) && (id3header[2] == ("3").charCodeAt()))
        {
            inB.read(id3header, 0, 3);
            var majorVersion : Int = id3header[0];
            var revision : Int = id3header[1];
            inB.read(id3header, 0, 4);
            size =  /*(int)*/  (id3header[0] << 21) + (id3header[1] << 14) + (id3header[2] << 7) + (id3header[3]);
        }
        return as3hx.Compat.parseInt(size + 10);
    }
    
    /**
		 * Return raw ID3v2 frames + header.
		 * @return ID3v2 InputStream or null if ID3v2 frames are not available.
		 */
    public function getRawID3v2() : InputStream
    {
        if (rawid3v2 == null)
        {
            return null;
        }
        else
        {
            var bain : ByteArrayInputStream = new ByteArrayInputStream(rawid3v2);
            return bain;
        }
    }
    
    /**
		 * Close the Bitstream.
		 * @throws BitstreamException
		 */
    public function close() : Void
    {
        try
        {
            source.close();
        }
        catch (ex : Error)
        {
            throw new BitstreamException(STREAM_ERROR, ex);
        }
    }
    
    /**
		 * Reads and parses the next frame from the input source.
		 * @return the Header describing details of the frame read,
		 *	or null if the end of the stream has been reached.
		 */
    public function readFrame() : Header
    {
        var result : Header = null;
        try
        {
            result = readNextFrame();
            // E.B, Parse VBR (if any) first frame.
            if (firstframe == true)
            {
                result.parseVBR(frame_bytes);
                firstframe = false;
            }
        }
        catch (ex : BitstreamException)
        {
            if ((ex.getErrorCode() == INVALIDFRAME))
            {
                // Try to skip this frame.
                //System.out.println("INVALIDFRAME");
                try
                {
                    closeFrame();
                    result = readNextFrame();
                }
                catch (e : BitstreamException)
                {
                    if ((e.getErrorCode() != STREAM_EOF))
                    {
                        // wrap original exception so stack trace is maintained.
                        throw new BitstreamException(e.getErrorCode(), e);
                    }
                }
            }
            else
            {
                if ((ex.getErrorCode() != STREAM_EOF))
                {
                    // wrap original exception so stack trace is maintained.
                    throw new BitstreamException(ex.getErrorCode(), ex);
                }
            }
        }
        return result;
    }
    
    /**
		 * Read next MP3 frame.
		 * @return MP3 frame header.
		 * @throws BitstreamException
		 */
    private function readNextFrame() : Header
    {
        if (framesize == -1)
        {
            nextFrame();
        }
        return header;
    }
    
    
    /**
		 * Read next MP3 frame.
		 * @throws BitstreamException
		 */
    private function nextFrame() : Void
    {
        // entire frame is read by the header class.
        header.read_header(this, crc);
    }
    
    /**
		 * Unreads the bytes read from the frame.
		 * @throws BitstreamException
		 */
    // REVIEW: add new error codes for this.
    public function unreadFrame() : Void
    {
        if (wordpointer == -1 && bitindex == -1 && (framesize > 0))
        {
            try
            {
                source.unread(frame_bytes, 0, framesize);
            }
            catch (ex : Error)
            {
                throw new BitstreamException(STREAM_ERROR);
            }
        }
    }
    
    /**
		 * Close MP3 frame.
		 */
    public function closeFrame() : Void
    {
        framesize = -1;
        wordpointer = -1;
        bitindex = -1;
    }
    
    /**
		 * Determines if the next 4 bytes of the stream represent a
		 * frame header.
		 */
    public function isSyncCurrentPosition(syncmode : Int) : Bool
    {
        var read : Int = readBytes(syncbuf, 0, 4);
        var headerstring : Int = as3hx.Compat.parseInt((as3hx.Compat.parseInt(syncbuf[0] << 24) & 0xFF000000) | (as3hx.Compat.parseInt(syncbuf[1] << 16) & 0x00FF0000) | (as3hx.Compat.parseInt(syncbuf[2] << 8) & 0x0000FF00)) | as3hx.Compat.parseInt(as3hx.Compat.parseInt(syncbuf[3] << 0) & 0x000000FF);
        
        try
        {
            source.unread(syncbuf, 0, read);
        }
        catch (ex : Error)
        {
        }
        
        var sync : Bool = false;
        switch (read)
        {
            case 0:
                sync = true;
            case 4:
                sync = isSyncMark(headerstring, syncmode, syncword);
        }
        
        return sync;
    }
    
    
    // REVIEW: this class should provide inner classes to
    // parse the frame contents. Eventually, readBits will
    // be removed.
    public function readBits(n : Int) : Int
    {
        return get_bits(n);
    }
    
    public function readCheckedBits(n : Int) : Int
    {
        // REVIEW: implement CRC check.
        return get_bits(n);
    }
    
    private function newBitstreamException(errorcode : Int) : BitstreamException
    {
        return new BitstreamException(errorcode, null);
    }
    
    /**
	   * Get next 32 bits from bitstream.
	   * They are stored in the headerstring.
	   * syncmod allows Synchro flag ID
	   * The returned value is False at the end of stream.
	   */
    
    public function syncHeader(syncmode : Int) : Int
    {
        var sync : Bool;
        var i : Int = 1;
        var headerstring : Int;
        // read additional 2 bytes
        var bytesRead : Int = readBytes(syncbuf, 0, 3);
        
        if (bytesRead != 3)
        {
            throw new BitstreamException(STREAM_EOF, null);
        }
        
        headerstring = as3hx.Compat.parseInt((as3hx.Compat.parseInt(syncbuf[0] << 16) & 0x00FF0000) | (as3hx.Compat.parseInt(syncbuf[1] << 8) & 0x0000FF00)) | as3hx.Compat.parseInt(as3hx.Compat.parseInt(syncbuf[2] << 0) & 0x000000FF);
        
        do
        {
            headerstring <<= 8;
            
            if (readBytes(syncbuf, 3, 1) != 1)
            {
                throw new BitstreamException(STREAM_EOF, null);
            }
            
            headerstring = headerstring | as3hx.Compat.parseInt(syncbuf[3] & 0x000000FF);
            
            sync = isSyncMark(headerstring, syncmode, syncword);
        }
        while ((!sync));
        //current_frame_number++;
        //if (last_frame_number < current_frame_number) last_frame_number = current_frame_number;
        
        return headerstring;
    }
    
    public function isSyncMark(headerstring : Int, syncmode : Int, word : Int) : Bool
    {
        var sync : Bool = false;
        
        if (syncmode == INITIAL_SYNC)
        {
            //sync =  ((headerstring & 0xFFF00000) == 0xFFF00000);
            sync = (as3hx.Compat.parseInt(headerstring & 0xFFE00000) == 0xFFE00000);
        }
        else
        {
            sync = (as3hx.Compat.parseInt(headerstring & 0xFFF80C00) == word) &&
                    ((as3hx.Compat.parseInt(headerstring & 0x000000C0) == 0x000000C0) == single_ch_mode);
        }
        
        // filter out invalid sample rate
        if (sync)
        {
            sync = (as3hx.Compat.parseInt(as3hx.Compat.parseInt(headerstring >>> 10) & 3) != 3);
        }
        // filter out invalid layer
        if (sync)
        {
            sync = (as3hx.Compat.parseInt(as3hx.Compat.parseInt(headerstring >>> 17) & 3) != 0);
        }
        // filter out invalid version
        if (sync)
        {
            sync = (as3hx.Compat.parseInt(as3hx.Compat.parseInt(headerstring >>> 19) & 3) != 1);
        }
        
        return sync;
    }
    
    /**
		 * Reads the data for the next frame. The frame is not parsed
		 * until parse frame is called.
		 */
    public function read_frame_data(bytesize : Int) : Int
    {
        var numread : Int = 0;
        numread = readFully(frame_bytes, 0, bytesize);
        framesize = bytesize;
        wordpointer = -1;
        bitindex = -1;
        return numread;
    }
    
    /**
	   * Parses the data previously read with read_frame_data().
	   */
    public function parse_frame() : Void
    {
        // Convert Bytes read to int
        var b : Int = 0;
        var byteread : Array<Dynamic> = frame_bytes;
        var bytesize : Int = framesize;
        
        // Check ID3v1 TAG (True only if last frame).
        //for (int t=0;t<(byteread.length)-2;t++)
        //{
        //	if ((byteread[t]=='T') && (byteread[t+1]=='A') && (byteread[t+2]=='G'))
        //	{
        //		System.out.println("ID3v1 detected at offset "+t);
        //		throw newBitstreamException(INVALIDFRAME, null);
        //	}
        //}
        
        var k : Int = 0;
        while (k < bytesize)
        {
            var convert : Int = 0;
            var b0 : Int = 0;
            var b1 : Int = 0;
            var b2 : Int = 0;
            var b3 : Int = 0;
            b0 = byteread[k];
            if (k + 1 < bytesize)
            {
                b1 = byteread[k + 1];
            }
            if (k + 2 < bytesize)
            {
                b2 = byteread[k + 2];
            }
            if (k + 3 < bytesize)
            {
                b3 = byteread[k + 3];
            }
            framebuffer[b++] = (as3hx.Compat.parseInt(b0 << 24) & 0xFF000000) | (as3hx.Compat.parseInt(b1 << 16) & 0x00FF0000) | (as3hx.Compat.parseInt(b2 << 8) & 0x0000FF00) | (b3 & 0x000000FF);
            k = as3hx.Compat.parseInt(k + 4);
        }
        wordpointer = 0;
        bitindex = 0;
    }
    
    /**
	   * Read bits from buffer into the lower bits of an unsigned int.
	   * The LSB contains the latest read bit of the stream.
	   * (1 <= number_of_bits <= 16)
	   */
    public function get_bits(number_of_bits : Int) : Int
    {
        var returnvalue : Int = 0;
        var sum : Int = as3hx.Compat.parseInt(bitindex + number_of_bits);
        
        // E.B
        // There is a problem here, wordpointer could be -1 ?!
        if (wordpointer < 0)
        {
            wordpointer = 0;
        }
        // E.B : End.
        
        if (sum <= 32)
        {
            // all bits contained in *wordpointer
            returnvalue = as3hx.Compat.parseInt(framebuffer[wordpointer] >>> (32 - sum)) & bitmask[number_of_bits];
            // returnvalue = (wordpointer[0] >> (32 - sum)) & bitmask[number_of_bits];
            if ((bitindex += number_of_bits) == 32)
            {
                bitindex = 0;
                wordpointer++;
            }
            return returnvalue;
        }
        
        // E.B : Check that ?
        //((short[])&returnvalue)[0] = ((short[])wordpointer + 1)[0];
        //wordpointer++; // Added by me!
        //((short[])&returnvalue + 1)[0] = ((short[])wordpointer)[0];
        var Right : Int = as3hx.Compat.parseInt(framebuffer[wordpointer] & 0x0000FFFF);
        wordpointer++;
        var Left : Int = as3hx.Compat.parseInt(framebuffer[wordpointer] & 0xFFFF0000);
        returnvalue = as3hx.Compat.parseInt(as3hx.Compat.parseInt(Right << 16) & 0xFFFF0000) | as3hx.Compat.parseInt(as3hx.Compat.parseInt(Left >>> 16) & 0x0000FFFF);
        
        returnvalue >>>= 48 - sum;  // returnvalue >>= 16 - (number_of_bits - (32 - bitindex))  
        returnvalue = returnvalue & bitmask[number_of_bits];
        bitindex = as3hx.Compat.parseInt(sum - 32);
        return returnvalue;
    }
    
    /**
		 * Set the word we want to sync the header to.
		 * In Big-Endian byte order
		 */
    public function set_syncword(syncword0 : Int) : Void
    {
        syncword = syncword0 & 0xFFFFFF3F;
        single_ch_mode = ((syncword0 & 0x000000C0) == 0x000000C0);
    }
    /**
		 * Reads the exact number of bytes from the source
		 * input stream into a byte array.
		 *
		 * @param b		The byte array to read the specified number
		 *				of bytes into.
		 * @param offs	The index in the array where the first byte
		 *				read should be stored.
		 * @param len	the number of bytes to read.
		 *
		 * @exception BitstreamException is thrown if the specified
		 *		number of bytes could not be read from the stream.
		 */
    private function readFully(b : Array<Dynamic>, offs : Int, len : Int) : Int
    {
        var nRead : Int = 0;
        try
        {
            while (len > 0)
            {
                var bytesread : Int = source.read(b, offs, len);
                if (bytesread == -1)
                {
                    while (len-- > 0)
                    {
                        b[offs++] = 0;
                    }
                    break;
                }
                nRead = as3hx.Compat.parseInt(nRead + bytesread);
                offs += bytesread;
                len -= bytesread;
            }
        }
        catch (ex : Error)
        {
            throw new BitstreamException(STREAM_ERROR, ex);
        }
        return nRead;
    }
    
    /**
		 * Simlar to readFully, but doesn't throw exception when
		 * EOF is reached.
		 */
    private function readBytes(b : Array<Dynamic>, offs : Int, len : Int) : Int
    {
        var totalBytesRead : Int = 0;
        try
        {
            while (len > 0)
            {
                var bytesread : Int = source.read(b, offs, len);
                if (bytesread == -1)
                {
                    break;
                }
                totalBytesRead += bytesread;
                offs += bytesread;
                len -= bytesread;
            }
        }
        catch (ex : Error)
        {
            throw new BitstreamException(STREAM_ERROR, ex);
        }
        return totalBytesRead;
    }
}

