// Read data from MAX31855 chip on Adafruit breakout boards
// Code developed by Electric Imp Forum members rivers,
// mjkuwp94, Brown, as well as Hugo, peter, and others.
// Modified for use by Joel Wehr.
//      pins:
//      imp 1 CLK
//      imp 2 UNASSIGNED
//      imp 5 UNASSIGNED
//      imp 7 UNASSIGNED
//      imp 8 CS
//      imp 9 DO

//Configure Pins
hardware.spi189.configure(MSB_FIRST | CLOCK_IDLE_LOW , 1000);
hardware.pin8.configure(DIGITAL_OUT); //chip select

local temp32 <- 0;
farenheit <- 0;
celcius <- 0;


//Define functions
function readChip189(){

        //Get SPI data 
    hardware.pin8.write(0); //pull CS low to start the transmission of temp data  
  	//0[31..24],1[23..16],2[15..8],3[7..0]
        temp32=hardware.spi189.readblob(4);//SPI read is totally completed here
    hardware.pin8.write(1); // pull CS high
        // Begin converting Binary data for chip 1
    local tc = 0;
    if ((temp32[1] & 1) ==1){
      
        //Error bit is set
		
		local errorcode = (temp32[3] & 7);// 7 is B00000111
		local TCErrCount = 0;
		if (errorcode>0){
			
			//One or more of the three error bits is set
			//B00000001 open circuit
			//B00000010 short to ground
			//B00000100 short to VCC
			
			switch (errorcode){
            
            case 1:
			    
                server.log("TC open circuit");
			    break;
			
			case 2:
            
                server.log("TC short to ground");
			    break;
            
            case 3:
            
                server.log("TC open circuit and short to ground")
                break;
			
			case 4:
            
                server.log("TC short to VCC");
			    break;
			
			default:
            
                //Bad coding error if you get here
			    break;
			}
			
			TCErrCount+=1;
			//if there is a fault return this number, or another number of your choice
			 tc= 67108864; 
		}
	    else
        {
             server.log("error in SPI read");
        }
        
	} 
	else //No Error code raised
	{
		local highbyte =(temp32[0]<<6); //move 8 bits to the left 6 places
		
        //move to the right two places, lowing two bits that were not related
		local lowbyte = (temp32[1]>>2);		
		tc = highbyte | lowbyte; //now have right-justifed 14 bits but the 14th digit is the sign
         
		//Shifting the bits to make sure negative numbers are handled
        
        //get the sign indicator into position 31 of the signed 32-bit integer
		
        //Then, scale the number back down, the right-shift operator of squirrel/impOS
        //seems to handle the sign bit
        
        tc = ((tc<<18)>>18); 
        // Convert to Celcius
		    celcius = (1.0* tc/4.0);
        // Convert to Farenheit
        farenheit = (((celcius*9)/5)+32);
        server.log("Celcius: " + celcius);
        server.log("Farenheit: " + farenheit);
	}
}

// Configure with the server
imp.configure("MAX31855", [], []);
