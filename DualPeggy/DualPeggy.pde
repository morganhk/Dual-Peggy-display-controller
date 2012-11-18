/**
 * Controlling 2 Peggys for a performance
 * 2012-11-18
 * Contact: https://github.com/morganhk
 *
 * Based on Bounce Example - http://processing.org/learning/topics/bounce.html
 * Based on http://planetclegg.com/projects/QC-Peggy.html for the communications part
 * 
 * Note: For speed, disable GRID. 
 * For use with two Peggys using TWI, make sure to set the two serial ports appropriately and enable SERIAL
 *
 * 
**/ 
import processing.serial.*;


// SETUP
boolean GRID = true;        // Displays the black grid to simluate the LED resultion
boolean SERIAL = false;      // Enable or Disable Serial communication
String peggy1Serial = "/dev/tty.usbserial-A7004E4E";
String peggy2Serial = "/dev/tty.usbserial-A7004E4F";

//INIT
Serial peggy1Port;
Serial peggy2Port;
PImage peggyImage = new PImage(25,25);
byte [] peggyHeader = new byte[] { (byte)0xde, (byte)0xad, (byte)0xbe,(byte)0xef,1,0 };
byte [] peggyFrame = new byte[13*25];

//Ball bouncing -- can be removed later
int size = 60;       // Width of the shape
float xpos, ypos;    // Starting position of shape    
float xspeed = 5.8;  // Speed of the shape
float yspeed = 5.2;  // Speed of the shape
int xdirection = 1;  // Left or Right
int ydirection = 1;  // Top to Bottom


// SETUP loop
void setup() 
{
  size(250, 500);    // Grid is one screen on top of the other 25px*25px (scaled up 10 times)
  noStroke();
  frameRate(30);    // Tested at up to 60 fps
  smooth();
  
  if(SERIAL){
    peggy1Port = new Serial(this, peggy1Serial, 115200);
    peggy2Port = new Serial(this, peggy2Serial, 115200);
  }
  
  
  // Set the starting position of the shape -- can be removed later
  xpos = width/2;
  ypos = height/2;
  
}

// DRAW loop
void draw() 
{
  
  // Bouncing ball -- can be removed later
  background(10);
  xpos = xpos + ( xspeed * xdirection );
  ypos = ypos + ( yspeed * ydirection );
  if (xpos > width-size || xpos < 0) xdirection *= -1;
  if (ypos > height-size || ypos < 0) ydirection *= -1;
  ellipse(xpos+size/2, ypos+size/2, size, size);


  //!\\//!\\//!\\//!\\//!\\//!\\//!\\//!\\//!\\
  //!\\Keep at the end of the draw routine//!\\
  //!\\//!\\//!\\//!\\//!\\//!\\//!\\//!\\//!\\
  //Send screen to Peggy
  if(SERIAL){
    //Top screen
    renderToPeggy(grabDisplay(0),0);
    //Bottom screen
    renderToPeggy(grabDisplay(width * (height/2)),1);
  }
  if(GRID)drawOverlayGrid();
  
  
}








/********************************************* HELPERS ********************************************/
void drawOverlayGrid(){
    //Added, to make it look more like a Grid
    for (int i = 0; i < 26; i++) {
      stroke(0);
      strokeWeight(6);
      line(0, i*10, width, i*10);
      line(0, i*10+height/2, width, i*10+height/2); 
      line(i*10, 0, i*10, height); 
  }
  
}

// This function copies the content of the display into a PImage
// Zone =0 for first image and =width * (height/2) for the second
PImage grabDisplay(int zone)
{
  PImage img = createImage(width, height/2, ARGB);
  loadPixels();
  arraycopy(pixels, 0, img.pixels, 0, width * (height/2));
  return img;
}

// "render a PImage to the Peggy by transmitting it serially.  
// If it is not already sized to 25x25, this method will 
// create a downsized version to send..."
// -- from http://planetclegg.com/projects/QC-Peggy.html
// added support for 2 peggys
void renderToPeggy(PImage srcImg, int display)
{
  int idx = 0;
  
  PImage destImg = peggyImage;
  if (srcImg.width != 25 || srcImg.height != 25)
    destImg.copy(srcImg,0,0,srcImg.width,srcImg.height,0,0,destImg.width,destImg.height);
  else
    destImg = srcImg;
    
  // iterate over the image, pull out pixels and 
  // build an array to serialize to the peggy
  for (int y =0; y < 25; y++)
  {
    byte val = 0;
    for (int x=0; x < 25; x++)
    {
      color c = destImg.get(x,y);
      int br = ((int)brightness(c))>>4;
      if (x % 2 ==0)
        val = (byte)br;
      else
      {
        val = (byte) ((br<<4)|val);
        peggyFrame[idx++]= val;
      }
    }
    peggyFrame[idx++]= val;  // write that one last leftover half-byte
  }
  
  // send the header, followed by the frame
  if (display == 0){
    peggy1Port.write(peggyHeader);
    peggy1Port.write(peggyFrame);
  }else{ 
    peggy2Port.write(peggyHeader);
    peggy2Port.write(peggyFrame);
  }
}
