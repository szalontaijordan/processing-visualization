import java.util.*;
import java.util.function.UnaryOperator;
import java.time.LocalDate;
import java.text.SimpleDateFormat;

PShape hu;
int scale = 3;
final int W = 3450 / scale;
final int H = 2170 / scale;

Table translates;

DataLoader loader;
List<Train> trains;
Set<String> mainLines;
Map<String, Float> delays;
Map<String, Integer> counts;

Set<String> water = Set.of(
  "Duna_folyam",
  "Szentendrei_Duna",
  "Rackevei_Duna",
  "Tisza",
  "Balaton",
  "Velencei_to",
  "Ferto_to",
  "Kiskorei_viztarozo"
);

void setup() {
  println(W + "x" + H);
  size(1150, 723);
  hu = loadShape("hu3.svg");
  translates = loadTable("translates.csv", "header");
  
  loader = new DataLoader();
  requestData();
} 

float zoom = 0.0;
int deltaX = 0;
int deltaY = 0;
int tdeltaX = 0;
int tdeltaY = 0;

int mapX = 1213;
int mapY = 579;
int trainsX = 0;
int trainsY = 0;

float strechX = 0.23;
float strechY = 0.17;

int timer;
int intervalSeconds = 2;

void draw(){
  background(#ffffff);
  
  if (millis() - timer >= intervalSeconds * 1000) {
    thread("requestData");
    timer = millis();
  }
  
  PShape map = hu.getChild("alapterkep");

  drawHungary(map);
  drawTrainLines(map);
  
  // zoom buttons
  // ...
  
  // trains
  if (shouldDrawTrains) {
    drawTrains();
  }
}

void drawTrains() {
  float h = 2059 * (1.0 + strechY) * (0.3 + zoom);
  float w = 3116 * (1.0 + strechX) * (0.3 + zoom);

  final float scaleH = h / deltaLat;
  final float scaleW = w / deltaLon;
  
  trains.stream().forEach(train -> {        
    strokeWeight(1);
    stroke(#232323);

    float trainDeltaX = trainsX * (1.0 + strechX) * (0.3 + zoom);
    float trainDeltaY = trainsY * (1.0 + strechY) * (0.3 + zoom);

    float x = (train.getLon() - minLon) * scaleW + trainDeltaX;
    float y = h - ((train.getLat() - minLat) * scaleH) + trainDeltaY;
    // ellipseMode(CENTER);
    
    getFillForDelay(train);
    circle(x, y, 10);
    
    if (dist(x, y, mouseX, mouseY) < 10) {
      fill(#000000);
      drawInfoBox(train);
    }
  });
}

void drawInfoBox(Train train) {
  fill(color(255, 255, 255, 240));
  strokeWeight(1);
  stroke(#000000);
  
  int boxW = 200;
  int boxH = 40;
  
  rect(mouseX - boxW - 8, mouseY - boxH - 8, boxW, boxH, 16);
  fill(#000000);
  text(train.getInfo(), mouseX - boxW, mouseY - boxH + 8);
}

void drawHungary(PShape map) {
  Arrays.asList(map.getChildren()).stream()
    .forEach(child -> {
      show(() -> {
        child.disableStyle();
        
        if (water.contains(child.getName())) {
          noStroke();
        } else if (child.getName().equals("orszaghatar")) {
          strokeWeight(2);
          stroke(#000000);
        } else {
          stroke(color(128, 128, 128));          
        }
        noFill();
        shape(child);
        child.enableStyle();
      });
    });  
}

void drawTrainLines(PShape map) {
  Arrays.asList(map.getChildren()).stream()
    .filter(child -> child.getName() != null)
    .filter(child -> child.getName().startsWith("vv"))
    // .filter(child -> mainLines.contains(child.getName()))
    .skip(0)
    .limit(L)
    .forEach(child -> {
      drawTrainLine(child);
    });
}

void getFillForDelay(Train train) {
  int lineDelay = train.getDelay();
  
  if (lineDelay == 0) {
    fill(#b3d7ff);
  } else if (1 <= lineDelay && lineDelay < 5) {
    fill(#ceffcc);
  } else if (5 <= lineDelay && lineDelay < 15) {
    fill(#f5ff38);
  } else if (15 <= lineDelay && lineDelay < 30) {
    fill(#ffbf00);
  } else if (30 <= lineDelay && lineDelay < 60) {
    fill(#ff0000);
  } else if (60 <= lineDelay && lineDelay < 100) {
    fill(#9c0000);
  } else {
    println(lineDelay);
    fill(#000000);
  }
}

Map[] getStats() {
  Map<String, Float> delays = new HashMap<>();
  Map<String, Integer> counts = new HashMap<>();

  trains.stream().forEach(train -> {
    String line = "vv_" + train.getLine();
    Float current = delays.get(line);
    
    if (current == null) {
      delays.put(line, 1.0 * train.getDelay());
      counts.put(line, 1);
    } else {
      delays.put(line, current + train.getDelay());
      counts.put(line, counts.get(line) + 1);
    }
  });
  
  delays.entrySet().stream().forEach(me -> {
    delays.put(me.getKey(), me.getValue() / counts.get(me.getKey()));
  });
  
  return new Map[]{
    delays,
    counts
  };
}

float getMaxDelay() {
  return delays.values().stream().reduce((acc, val) -> Math.max(acc, val)).orElse(0.0);
}

void show(Runnable paint) {
  pushMatrix();
  scale((1.0 + strechX) * (0.3 + zoom), (1.0 + strechY) * (0.3 + zoom));
  translate(mapX, mapY);
  paint.run();
  popMatrix();
}

void drawTrainLine(String id, PShape map) {
  PShape trainLine = map.getChild(id);
  drawTrainLine(trainLine);
}

float DX = 103.0;
float DY = 544.0;

void drawTrainLine(PShape trainLine) {
  if (trainLine == null) {
    return;
  }

  final int count = trainLine.getVertexCount();
  final color from = #00ff00;
  final color to = #ff0000;
  final float minStroke = 1.0;
  final float maxStroke = 14;
  
  // final String lineName = "vv_" + trainLine.getName().replaceAll("[A-Za-z_]", "");
  final String lineName = trainLine.getName().toLowerCase();
  
  strokeJoin(ROUND);
  for (int i = 1; i < count; i++) {
    PVector first = trainLine.getVertex(i - 1);
    PVector last = trainLine.getVertex(i);
    
    final int I = i;
    show(() -> {
      translateIfNeeded(trainLine);
      
      int minDelay = 0;
      float maxDelay = getMaxDelay();

      // delay
      Float lineDelay = delays.get(lineName);
      float colorBase = lineDelay == null || lineDelay == 0
        ? 0
        : map(lineDelay, minDelay, maxDelay, 0, 1);

      // trains per line
      Integer lineCount = counts.get(lineName);  
      float countBase = lineCount == null || lineCount == 0
        ? minStroke
        : map(lineCount, 0, 100, minStroke, maxStroke);
      
      float strokeSize = getStrokeSize(I, count, count/16, countBase);
      color strokeColor = lerpColor(from, to, colorBase);

      strokeWeight(strokeSize);
      stroke(strokeColor);
      line(first.x, first.y, last.x, last.y);
    });
  }

}

void translateIfNeeded(PShape trainLine) {
  TableRow tr = null;
  for (TableRow row : translates.rows()) {
    if (row.getString("id").equals(trainLine.getName())) {
      tr = row;
    }
  }
  if (tr != null) {
    float xx = tr.getFloat("x");
    float yy = tr.getFloat("y");
    translate(xx + DX, yy + DY);
  }
}
/*
boolean isMouseOnLineBetween(PVector A, PVector B) {
  PVector mouse = new PVector(mouseX, mouseY);
  PVector V = B.sub(A);
  PVector N = new PVector(V.y, -1* V.x);
  float C = N.dot(A);
  return mouse.dot(N) - C == 0;
}
*/

float getStrokeSize(int i, int count, int parts, float baseStrokeSize) {
  float strokeSize = baseStrokeSize;
  for (int xi = 1; xi <= parts / 2; xi++) {
    float lower = (1.0*xi / parts) * count;
    float upper = (1 - (1.0*xi / parts)) * count;
    
    if (lower <= i && i <= upper) {
      strokeSize = xi * baseStrokeSize;
    }
  }
  return strokeSize;
}

void mousePressed() {
  deltaX = mouseX - mapX; 
  deltaY = mouseY - mapY;
  tdeltaX = mouseX - trainsX;
  tdeltaY = mouseY - trainsY;
}

void mouseDragged() {
  mapX = mouseX - deltaX; 
  mapY = mouseY - deltaY; 
  trainsX = mouseX - tdeltaX;
  trainsY = mouseY - tdeltaY;
}

void mouseWheel(MouseEvent event) {
  float delta = 0.003;
  
  if (event.getCount() > 0) {
    zoom = Math.max(-1, zoom - delta);
  } else if (event.getCount() < 0) {
    zoom = Math.min(4, zoom + delta);
  }
}

int L = 1000;

boolean shouldDrawTrains = false;

void keyPressed() {
  float delta = 0.001;

  if (key == 't') {
    shouldDrawTrains = !shouldDrawTrains;
  } else if (key == 'f') {
    DY -= 1.0;
  } else if (key == 'r') {
    DX += 1.0;
  } else if (key == 'l') {
    L++;
  } else if (key == '+') {
    zoom = Math.min(4, zoom + delta);
  } else if (key == '-') {
    zoom = Math.max(-1, zoom - delta);
  } else if (key == 'a') {
    strechX += delta;
    println("a");
  } else if (key == 'w') {
    strechY += delta;
    println("w");
  } else if (key == 'd') {
    strechX -= delta;
  } else if (key == 's') {
    strechY -= delta;
  } else if (key == ' ') {
    println(mapX);
    println(mapY);
    println(strechX);
    println(strechY);
  }
}

float deltaLat;
float deltaLon;
float minLat;
float maxLat;
float minLon;
float maxLon;

void requestData() {
  trains = loader.loadTrains();
  Map[] stats = getStats();
  delays = stats[0];
  counts = stats[1];
  /*minLat = trains.stream().map(train -> train.getLat()).reduce((acc, lat) -> Math.min(acc, lat)).orElse(0.0);
  maxLat = trains.stream().map(train -> train.getLat()).reduce((acc, lat) -> Math.max(acc, lat)).orElse(0.0);
  
  minLon = trains.stream().map(train -> train.getLon()).reduce((acc, lat) -> Math.min(acc, lat)).orElse(0.0);
  maxLon = trains.stream().map(train -> train.getLon()).reduce((acc, lat) -> Math.max(acc, lat)).orElse(0.0);*/
  minLon = 16.2022982113;
  minLat = 45.7594811061;
 
  maxLon = 22.710531447;
  maxLat = 48.6238540716;
  
  deltaLat = Math.abs(minLat - maxLat);
  deltaLon = Math.abs(minLon - maxLon);
  
  mainLines = new HashSet<>();
  trains.stream().forEach(train -> mainLines.add("vv_" + train.getLine()));
}
