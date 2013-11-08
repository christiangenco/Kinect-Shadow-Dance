import fullscreen.*;
import japplemenubar.*;
import org.openkinect.*;
import org.openkinect.processing.*;
import processing.video.*;

ShadowTracker tracker;

// Kinect Library object
Kinect kinect;

// Full screen
FullScreen fs; 

int width=640, height=480;
int kw = 640, kh = 480;

int FRAME_MEMORY = 200;
boolean[][] record = new boolean[FRAME_MEMORY][];
int frame = 0;
int display_frame = 0;

MovieMaker mm;
Movie playback, bowVideo;
void setup() {
  size(width,height,P2D);
  
  kinect = new Kinect(this);  
  tracker = new ShadowTracker();
  
  textFont(loadFont("Serif-20.vlw"), 20); 
  
  frameRate(30);
  
  // Create the fullscreen object
  fs = new FullScreen(this); 
  
  // enter fullscreen mode
  fs.enter();
  
  mm = new MovieMaker(this, width, height, "playback.mov", 30, MovieMaker.H263, MovieMaker.HIGH);
}

int shadow_color = color(0,0,0), bgcolor = color(255,255,255);

PImage translateImage(boolean[] raw_data){
  if(raw_data == null) return new PImage();
  
  PImage image = new PImage(kw,kh,PConstants.RGB);
  for(int x = 0; x < kw; x++) {
    for(int y = 0; y < kh; y++) {
      pixel_index = x+y*kw;
      if(raw_data[pixel_index]){
        image.pixels[pixel_index] = shadow_color;
      }else{
        image.pixels[pixel_index] = bgcolor;
      }
    }
  }
  return image;
}

/* 
// maintain a longer tail with less lag
boolean memoryMode = false;
PImage memory = new PImage(kw,kh,PConstants.RGB);
PImage rememberImage(boolean[] raw_data){
  for(int x = 0; x < kw; x++) {
    for(int y = 0; y < kh; y++) {
      pixel_index = x+y*kw;
      if(raw_data[pixel_index]) 
        memory.pixels[pixel_index] = 0;
        // shadow_color;
    }
  }
  memory.updatePixels();
  return memory;
}
void resetMemory(){
  for(int i=0;i<kw*kh;i++) memory.pixels[i] = -1;
}
*/


boolean[] mirror(boolean[] frame){
  boolean[] mirror = new boolean[kw*kh];
  int pixel_index=0, mirrored_index=0;
  for(int x = 0; x < kw; x++) {
    for(int y = 0; y < kh; y++) {
      pixel_index = x+y*kw;
      mirrored_index = (kw-x-1) + y*kw;
      
      mirror[pixel_index] = frame[pixel_index] || frame[mirrored_index];
    }
  }
  
  return mirror;
}

boolean[] calculateTail(int tailLength){
  boolean[] tail = new boolean[kw*kh];
  
  // first, figure out how far back to go
  int startFrame = calcFrame(tailLength);
  
  // print("startFrame=" + startFrame);
  // println("  endFrame=" + frame);
  
  for(int x = 0; x < kw; x++) {
    for(int y = 0; y < kh; y++) {
      pixel_index = x+y*kw;
      // skip if it's already set
      if(!tail[pixel_index]){
        // go between the frames looking for a set pixel
        
        // standard
        if(startFrame<frame){
          for(int i=startFrame; i<frame; i++){          
            if(record[i][pixel_index]){
              tail[pixel_index] = true;
              break;
            }
          }
        }else{
          // go from startFrame to the end
          for(int i=startFrame; i<FRAME_MEMORY; i++){          
            if(record[i][pixel_index]){
              tail[pixel_index] = true;
              break;
            }
          }
          
          // go from 0 to frame
          for(int i=0; i<=frame; i++){          
            if(record[i][pixel_index]){
              tail[pixel_index] = true;
              break;
            }
          }
        }
      }
    }
  }
  
  return tail;
}

int[] shadow_colors = {color(255,0,0), color(255,150,0), color(255,255,0), color(0,255,0), color(0,0,255)};
PImage addImages (boolean[][] raw_datas, int offset){
  if(raw_datas == null) return new PImage();
  PImage image = new PImage(kw,kh,PConstants.RGB);
  
  for(int x = 0; x < kw; x++) {
    for(int y = 0; y < kh; y++) {
      pixel_index = x+y*kw;
      for(int i=0; i<raw_datas.length; i++){
        int pixel_offset_index = pixel_index + offset*i;
        if(pixel_offset_index < kw*kh && pixel_offset_index >= 0){
          if(raw_datas[i] != null && raw_datas[i][pixel_index]){
            image.pixels[pixel_offset_index] = shadow_colors[i];
          }
        }
        
      }
    }
  }
  
  // set everything that hasn't been set to white
  for(int i=0; i<kw*kh; i++){
    if(image.pixels[i]==0)
      image.pixels[i] = -1;
  }
  
  return image;
}


int pixel_index;
PImage getImage(int index){
  if(index > record.length-1) return new PImage();
  return translateImage(record[index]);
}

int calcFrame(int delay){
  int display_frame = frame-delay;
  if(display_frame < 0) display_frame = record.length + display_frame;
  if(display_frame > FRAME_MEMORY) display_frame = FRAME_MEMORY;
  return display_frame;
}

PImage tracker_image;
int delay = 1;
boolean displayText = false;
PImage img = new PImage(kw,kh,PConstants.RGB);
int tailLength = 1;

boolean playbackMode = false, playbackPlayed = false, bowMode = false, colorOffsetMode=false, startRecording = false, mirrorImage = false;
float fadeOut = 0;

// variables for multiply thing
int multiplyN = 1, mFrameIndex=0, mHeight=height, mWidth=width, mW, mH;
int mCounter=0, mSwitchAfter=5;
void draw() {
  if(playbackMode){
    if(playbackPlayed){
      if(!bowMode){
        fill(0, fadeOut);
        rect(0, 0, width, height);
        fadeOut = min(fadeOut+0.5, 100);
      }else{ 
        // BOW!
        if(fadeOut<100){
          // fade back to white
          fill(255, fadeOut);
          rect(0, 0, width, height);
          fadeOut = min(fadeOut+2, 100);
        }else{
          // play recorded bow video bow.mov
          // after it's faded back to white
          bowVideo.read();
          image(bowVideo, 0, 0);
        }
      }
    }else{
      playback.read();
      image(playback, 0, 0);
    
      // play faster in the middle than on the ends 
      if(playback.time() > 0.2*playback.duration() && 
        playback.time() < playback.duration() - 0.2*playback.duration()) 
        playback.speed(-3);
      else
        playback.speed(-0.5);
      
      if(playback.time() == 0)
        playbackPlayed = true;
    }
  }else{
    // update the image from the kinect
    tracker.updateImage(shadow_color,bgcolor);
    
    // record the image
    record[frame++] = tracker.pixels;
    if(frame > record.length-1) frame = 0;
    
    if(record[display_frame] != null){

      if(colorOffsetMode){
        // multiple time offset colors
        boolean[][] frames = {record[calcFrame(delay+80)], record[calcFrame(delay+60)], record[calcFrame(delay+40)], record[calcFrame(delay+20)], record[calcFrame(delay+0)]};
        img = addImages(frames, 0);
      }else{
        // mirror?
        if(mirrorImage){
          img = translateImage(mirror(record[calcFrame(delay)]));
    
        // standard
        }else if(tailLength <= 1)
          img = getImage(calcFrame(delay));
        else{
          img = translateImage(calculateTail(tailLength)); // tail the bits
        }
      }
      
      if(multiplyN>1){
        mCounter++;
        if(mCounter > mSwitchAfter){
          mCounter = 0;
          mFrameIndex += 1;
          if(mFrameIndex>(multiplyN*multiplyN-1)) mFrameIndex = 0;
          // println("mFrameIndex=" + mFrameIndex);
        }
        
        mHeight = height/multiplyN;
        mWidth = width/multiplyN;
        mW = mFrameIndex%multiplyN;
        mH = mFrameIndex/multiplyN;
        
        image(img,mW*mWidth,mH*mHeight,mWidth,mHeight);
      }else{        
        image(img,0,0);
      }
    }
  
    // Display some info
    if(displayText){
      fill(0);
      text("delay: " + delay + "  " +  "threshold" + tracker.getThreshold(),10,470);
      // text("threshold: " + tracker.getThreshold() + "    " +  "framerate: " + (int)frameRate,10,450);
    }

    // if(frame%30==0) mm.addFrame();
    if(startRecording && frame%30==0) mm.addFrame();
  }
}

void keyPressed() {
  int t = tracker.getThreshold();
  if (key == CODED) {
    if (keyCode == UP) {
      tracker.setThreshold(t+=5);
      println("t=" + t);
      
      // tailLength = min(tailLength+1, FRAME_MEMORY-1);
      // println("tailLength=" + tailLength);
    } 
    else if (keyCode == DOWN) {
      tracker.setThreshold(t-=5);
      println("t=" + t);
      
      // tailLength = max(tailLength-1, 1);
      // println("tailLength=" + tailLength);
    }
    if (keyCode == LEFT) {
      multiplyN = max(1, multiplyN-1);
      println("multiplyN=" + multiplyN);
      
      // delay = max(delay-1, 1);
      // println("delay=" + delay);
    } 
    else if (keyCode == RIGHT) {
      multiplyN = min(5, multiplyN+1);
      println("multiplyN=" + multiplyN);
      
      // delay = min(delay+1, FRAME_MEMORY);
      // println("delay=" + delay);   
    }
  }else if(key == ']'){
      mSwitchAfter = min(mSwitchAfter+1, 100);
      println("mSwitchAfter=" + mSwitchAfter);
  }else if(key == '['){
    mSwitchAfter = max(mSwitchAfter-1, 1);
    println("mSwitchAfter=" + mSwitchAfter);
  }else if(key == '0'){
      tailLength = 1;
  }else if(key == '9'){
    tailLength = 30;
  }else if(key == '1'){
  println("1!");
  // copies = 1;
  }else if(key == '2'){
    println("2!");
    // copies = 2;
  }else if(key == '4'){
    println("4!");
    // copies = 4;
  }else if(key == 'x'){
      int temp = shadow_color;
      shadow_color = bgcolor;
      bgcolor = temp;
    }else if(key == 'm'){
      mirrorImage = !mirrorImage;
      println("mirrorImage=" + mirrorImage);
    }else if(key == 'd'){
    displayText = !displayText;
  }else if(key == 'q'){
    delay = 1;
  }else if(key == 'w'){
    delay = 20;
  }else if(key == 'e'){
    delay = 40;
  }else if(key == 'r'){
    delay = 85;
  }else if(key == 't'){
      delay = 170;
    }else if(key == '/'){
      startRecording = true;
      println("recording");
    }else if(key == 'c'){
    // multiple time offset colors
    colorOffsetMode = !colorOffsetMode;
  }else if(key=='v'){
    // REVERSE, REVERSE!
    mm.finish();
    playback = new Movie(this, "playback.mov");
    playback.jump(playback.duration());
    playback.speed(-1);
    playbackMode = true;
  }else if(key=='b'){
    // Bow!
    bowMode = true;
    fadeOut = 0;
    
    bowVideo = new Movie(this, "bow.mov");
  }
}

void stop() {
  tracker.quit();
  super.stop();
}