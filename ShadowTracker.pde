class ShadowTracker {
  // Size of kinect image
  int kw = 640;
  int kh = 480;
  int threshold = 1020;
  // int threshold = 650;
  
  // Depth data
  int[] depth_data;
  
  public PImage display;
  public boolean[] pixels;
  
  ShadowTracker(){
    kinect.start();    
    kinect.enableDepth(true);
    // display = createImage(kw,kh,PConstants.RGB);    
  }
  
  int raw_depth, pixel_index, c;
  void updateImage(int shadow_color, int bg_color) {
    pixels = new boolean[kw*kh];
    
    depth_data = kinect.getRawDepth();
    
    // Being overly cautious here
    if(depth_data == null) return;
    
    for(int x = 0; x < kw; x++) {
      for(int y = 0; y < kh; y++) {
        pixel_index = x+y*kw;
        
        raw_depth = depth_data[pixel_index];
        
        // the shadow!
        if(raw_depth < threshold){
          // display.pixels[pixel_index] = shadow_color;
          pixels[pixel_index] = true;
        }
        // else{
        //  // display.pixels[pixel_index] = bg_color;
        //  // pixels[pixel_index] = false; // maybe don't need this?
        // }
      }
    }
  }
  
  void quit(){kinect.quit();}
  int getThreshold(){return threshold;}
  void setThreshold(int t){threshold=t;}
}

