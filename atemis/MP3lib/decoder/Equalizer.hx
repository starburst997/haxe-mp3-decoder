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
@:final class Equalizer
{
    /**
		 * Equalizer setting to denote that a given band will not be
		 * present in the output signal.
		 */
    public static var BAND_NOT_PRESENT : Float = Math.NEGATIVE_INFINITY;

    public static var PASS_THRU_EQ : Equalizer = new Equalizer();

    private static inline var BANDS : Int = 32;

    private var settings : Array<Dynamic> = new Array<Dynamic>(BANDS);

    /**
		 * Creates a new <code>Equalizer</code> instance.
		 */

    //	private Equalizer(float b1, float b2, float b3, float b4, float b5,
    //					 float b6, float b7, float b8, float b9, float b10, float b11,
    //					 float b12, float b13, float b14, float b15, float b16,
    //					 float b17, float b18, float b19, float b20);

    public function new(arg : Dynamic = null)
    {
        if (Std.is(arg, EQFunction))
        {
            setFrom(try cast(arg, EQFunction) catch(e:Dynamic) null);
        }
        else
        {
            if (Std.is(arg, Array))
            {
                setFrom(try cast(arg, Array<Dynamic>) catch(e:Dynamic) null);
            }
        }
    }

    public function setFrom(arg : Dynamic) : Void
    {
        if (Std.is(arg, EQFunction))
        {
            setFrom2(try cast(arg, EQFunction) catch(e:Dynamic) null);
        }
        else
        {
            if (Std.is(arg, Equalizer))
            {
                setFrom3(try cast(arg, Equalizer) catch(e:Dynamic) null);
            }
            else
            {
                if (Std.is(arg, Array))
                {
                    setFrom1(try cast(arg, Array<Dynamic>) catch(e:Dynamic) null);
                }
            }
        }
    }

    public function setFrom1(eq : Array<Dynamic>) : Void
    {
        reset();
        var max : Int = ((eq.length > BANDS)) ? BANDS : eq.length;

        for (i in 0...max)
        {
            settings[i] = limit(eq[i]);
        }
    }

    public function setFrom2(eq : EQFunction) : Void
    {
        reset();
        var max : Int = BANDS;

        for (i in 0...max)
        {
            settings[i] = limit(eq.getBand(i));
        }
    }

    /**
		 * Sets the bands of this equalizer to the value the bands of
		 * another equalizer. Bands that are not present in both equalizers are ignored.
		 */
    public function setFrom3(eq : Equalizer) : Void
    {
        if (eq != this)
        {
            setFrom(eq.settings);
        }
    }


    /**
		 * Sets all bands to 0.0
		 */
    public function reset() : Void
    {
        for (i in 0...BANDS)
        {
            settings[i] = 0.0;
        }
    }


    /**
		 * Retrieves the number of bands present in this equalizer.
		 */
    public function getBandCount() : Int
    {
        return settings.length;
    }

    public function setBand(band : Int, neweq : Float) : Float
    {
        var eq : Float = 0.0;

        if ((band >= 0) && (band < BANDS))
        {
            eq = settings[band];
            settings[band] = limit(neweq);
        }

        return eq;
    }



    /**
		 * Retrieves the eq setting for a given band.
		 */
    public function getBand(band : Int) : Float
    {
        var eq : Float = 0.0;

        if ((band >= 0) && (band < BANDS))
        {
            eq = settings[band];
        }

        return eq;
    }

    private function limit(eq : Float) : Float
    {
        if (eq == BAND_NOT_PRESENT)
        {
            return eq;
        }
        if (eq > 1.0)
        {
            return 1.0;
        }
        if (eq < -1.0)
        {
            return -1.0;
        }

        return eq;
    }

    /**
		 * Retrieves an array of floats whose values represent a
		 * scaling factor that can be applied to linear samples
		 * in each band to provide the equalization represented by
		 * this instance.
		 *
		 * @return	an array of factors that can be applied to the
		 *			subbands.
		 */
    public function getBandFactors() : Array<Dynamic>
    {
        var factors : Array<Dynamic> = new Array<Dynamic>(BANDS);
        for (i in 0...BANDS)
        {
            factors[i] = getBandFactor(settings[i]);
        }

        return factors;
    }

    /**
		 * Converts an equalizer band setting to a sample factor.
		 * The factor is determined by the function f = 2^n where
		 * n is the equalizer band setting in the range [-1.0,1.0].
		 *
		 */
    public function getBandFactor(eq : Float) : Float
    {
        if (eq == BAND_NOT_PRESENT)
        {
            return 0.0;
        }

        var f : Float = Math.pow(2.0, eq);
        return f;
    }
}

