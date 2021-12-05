import java.util.*;

class ChartData {

  private String k;          // = "vv_100"; // me.getKey();
  private float target;      // = 50; //delays.get(k);
  private float val;         // = 10; // prevDelays.getOrDefault(k, 0.0);
  
  private int place;         // = 5; //(int) map(val, 0, maxDelay, 1, 5);
  private int targetPlace;   // = 0;//(int) map(target, 0, maxDelay, 1, 5);
  
  private float w;           // = map(val, 0, maxDelay, 0, 1000);
  private float targetW;     // = map(target, 0, maxDelay, 0, 1000);

  private float y;           // = place * yBase;
  private float targetY;     // = targetPlace * yBase;

  private float max;
  private float yBase;

  public ChartData(String k, float value, float targetValue, int place, int targetPlace, float max, float yBase) {
    this.k = k;
    this.val = value;
    this.target = targetValue;
    this.place = place;
    this.targetPlace = targetPlace;
    
    this.w = map(val, 0, max, 0, 1000);
    this.targetW = map(target, 0, max, 0, 1000);
    this.y = place * yBase;
    this.targetY = targetPlace * yBase;
    
    this.max = max;
    this.yBase = yBase;
  }
  
  public int getCurrent() {
    return (int) this.target;
  }
  
  public boolean isSettled() {
    if (val == target && place == targetPlace) {
      return true;
    }
    float dy = targetY - y;
    float dw = targetW - w;
    return Math.abs(dy) <= 1 && Math.abs(dw) <= 1; 
  }
  
  public void show(float x, float ease, color c) {
    noStroke();
    fill(c, 200);
    
    float dy = targetY - y;
    y += dy * ease;
     
    float dw = targetW - w;
    w += dw * ease / 2;
    
    int paddingTop = 50;
    
    rect(x, y + paddingTop, w, yBase - 4);
    fill(#000000);
    textAlign(RIGHT);
    text(k, x - 8, y + paddingTop + yBase / 2);
    textAlign(LEFT);
    text(String.format("%.2f", target), x + w + 8, y + paddingTop + yBase / 2);
  }
  
  @Override
  public String toString() {
    return "{ k: " + this.k + ", val: " + this.val + ", target: " + this.target + ", place: " + this.place + ", targetPlace: " + this.targetPlace + "\n";
  }
}
