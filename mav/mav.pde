import java.util.*;
import java.util.stream.IntStream;
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
List<ChartData> raceChart;
Map<String, Integer> counts;
Map<Integer, PVector> trainsXY;

List<List<ChartData>> history;
int showing = 0;
int selected = 0;
int pit = -1;
boolean autoFollow = true;

int playTimer;
boolean playing = false;

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

int dataTimer;

int intervalSeconds = 2;

int tmpx = 75;
float ease = 0.05;
float Y_BASE = 40.0;
int TOP_TRAINS = 15;

float sliderx;
float slidery;

boolean showingHu = true;

void draw(){
  background(#ffffff);
  calcTrains();
  float dataTimeDiff = millis() - dataTimer;
  if (dataTimeDiff >= intervalSeconds * 1000) {
    thread("requestData");
    dataTimer = millis();
  }
  
  if (showingHu) {
    drawFullHungary();
  } else {
    drawRaceChart();
  }
}

void drawFullHungary() {
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

void drawRaceChart() {
  // draw chart
  // fix delays
  strokeWeight(1);
  List<Integer> fixDelays = List.of(0, 15, 30, 60, 90);
  fixDelays.stream().forEach(d -> {
    float linex = map(d, 0, getMaxDelay(), 0, 1000) + tmpx;
    
    if (linex <= 1050) {
      stroke(color(128, 128, 128, 128));
      textAlign(CENTER);
      text(d.toString(), linex, Y_BASE - 8);
    
      line(linex, Y_BASE, linex, (TOP_TRAINS + 1) * Y_BASE + 16);
    }
  });
 
  int current = autoFollow ? showing : selected;
  List<ChartData> chart = history.size() == 0 ? null : history.get(current - 1);
  if (chart != null) {
    chart.stream().forEach(data -> data.show(tmpx, ease, getFillForDelay(data.getCurrent())));
    
    float playTimeDiff = millis() - playTimer;
    boolean allSettled = chart.stream().map(data -> data.isSettled()).reduce((acc, data) -> data && acc).orElse(false);
    if (playing && allSettled && playTimeDiff >= 500) {
      play();
      playTimer = millis();
    }
    
  }
  
  // draw slider
  stroke(#000000);
  strokeWeight(1);
  float sliderY = (TOP_TRAINS + 1) * Y_BASE + 46;
  line(tmpx, sliderY - 8, tmpx, sliderY + 8);
  line(tmpx, sliderY, 1050, sliderY);
  line(tmpx, sliderY - 8, tmpx, sliderY + 8);
  line(1050, sliderY - 8, 1050, sliderY + 8);
  
  for (int i = 1; i <= showing; i++) {
    float tickx = map(i, 1, showing, tmpx, 1050);
    line(tickx, sliderY - 4, tickx, sliderY + 4);
    if (i == current) {
      sliderx = tickx;
      slidery = sliderY;
    }
  }
  circle(sliderx, slidery, 8);
}

void drawTrains() {
  if (trainsXY == null) {
    return;
  }
  trainsXY.entrySet().stream().forEach(me -> {
    if (me.getKey() < trains.size()) {
      Train train = trains.get(me.getKey());
      PVector vec = me.getValue();
      
      stroke(#000000);
      strokeWeight(1);
      getFillForDelay(train);
      circle(vec.x, vec.y, 10);
    }
  });
}

void calcTrains() {
  trainsXY = new HashMap<>();
  float h = 2059 * (1.0 + strechY) * (0.3 + zoom);
  float w = 3116 * (1.0 + strechX) * (0.3 + zoom);

  final float scaleH = h / deltaLat;
  final float scaleW = w / deltaLon;
  
  for (int i = 0; i < trains.size(); i++) {
    Train train = trains.get(i); 
    strokeWeight(1);
    stroke(#232323);

    float trainDeltaX = trainsX * (1.0 + strechX) * (0.3 + zoom);
    float trainDeltaY = trainsY * (1.0 + strechY) * (0.3 + zoom);

    float x = (train.getLon() - minLon) * scaleW + trainDeltaX;
    float y = h - ((train.getLat() - minLat) * scaleH) + trainDeltaY;
    
    if (dist(x, y, mouseX, mouseY) < 10) {
      fill(#000000);
      drawInfoBox(train);
    }
    
    trainsXY.put(i, new PVector(x, y));
  };
}

void drawInfoBox(Train train) {
  if (train == null) {
    return;
  }
  fill(color(255, 255, 255, 240));
  strokeWeight(1);
  stroke(#000000);
  
  int boxW = 200;
  int boxH = 40;
  
  try {
    rect(mouseX - boxW - 8, mouseY - boxH - 8, boxW, boxH, 16);
    fill(#000000);
    text(train.getInfo(), mouseX - boxW, mouseY - boxH + 8);
  } catch (Exception e) {
  }
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

color getFillForDelay(int lineDelay) {
  if (lineDelay == 0) {
    return #b3d7ff;
  } else if (1 <= lineDelay && lineDelay < 5) {
    return #ceffcc;
  } else if (5 <= lineDelay && lineDelay < 15) {
    return #f5ff38;
  } else if (15 <= lineDelay && lineDelay < 30) {
    return #ffbf00;
  } else if (30 <= lineDelay && lineDelay < 60) {
    return #ff0000;
  } else if (60 <= lineDelay && lineDelay < 100) {
    return #9c0000;
  }
  println(lineDelay);
  return #000000;
}

void getFillForDelay(Train train) {
  int lineDelay = train.getDelay();
  fill(getFillForDelay(lineDelay));
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
    // delays.put(me.getKey(), (float) (Math.random() * 70));
  });
  
  return new Map[]{
    delays,
    counts
  };
}

float getMaxDelay() {
  if (delays == null) {
    return 0;
  }
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

List<PVector> getVerticesOfTrainLine(PShape trainLine) {
  List<PVector> vertices = new ArrayList<>();
  final int count = trainLine.getVertexCount();
  
  for (int i = 1; i < count; i++) {
    PVector vec = trainLine.getVertex(i);

    TableRow tr = isTranslateNeeded(trainLine);
    if (tr != null) {
      float xx = tr.getFloat("x");
      float yy = tr.getFloat("y");
      vec.add(new PVector(xx + DX, yy + DY));
    }
    vec.add(mapX, mapY);
    vec.set(vec.x * (1.0 + strechX) * (0.3 + zoom), vec.y * (1.0 + strechY) * (0.3 + zoom));
    
    
    vertices.add(vec);
  }
  
  return vertices;
}

void drawTrainLine(PShape trainLine) {
  if (trainLine == null) {
    return;
  }

  strokeJoin(ROUND);
  List<PVector> vertices = getVerticesOfTrainLine(trainLine);
  
  for (int i = 1; i < vertices.size(); i++) {
    PVector first = vertices.get(i - 1);
    PVector last = vertices.get(i);
    
    float strokeSize = 1.0;
    float mult = map(getCloseTrains(first, 20).size(), 0, 10, 1, 2);

    if (hasCloseTrain(first, 10) && hasCloseTrain(last, 10)) {
      strokeWeight(14 * mult);
      stroke(getLocalDelayColor(first, 10));
    } else if (hasCloseTrain(first, 20) && hasCloseTrain(last, 20)) {
      strokeWeight(8 * mult);
      stroke(getLocalDelayColor(first, 15));
    } else if (hasCloseTrain(first, 30) && hasCloseTrain(last, 30)) {
      strokeWeight(4 * mult);
      stroke(getLocalDelayColor(first, 20));
    } else {
      strokeWeight(strokeSize);
    }
    
    line(first.x, first.y, last.x, last.y);
  }

}

List<Train> getCloseTrains(PVector vec, int d) {
  List<Train> closeTrains = new ArrayList<>();
  
  try {
    for (int i = 0; i < trains.size(); i++) {
      if (trainsXY.getOrDefault(i, new PVector(Integer.MAX_VALUE, Integer.MAX_VALUE)).dist(vec) <= d) {
        closeTrains.add(trains.get(i));
      }
    }
  } catch (Exception e) {
  }

  return closeTrains;
}

color getLocalDelayColor(PVector vec) {
  return getLocalDelayColor(vec, 30);
}

color getLocalDelayColor(PVector vec, int d) {
  List<Train> closeTrains = getCloseTrains(vec, d);  
  final color from = #00ff00;
  final color to = #ff0000;
  
  int minDelay = 0;
  float maxDelay = getMaxDelay();

  if (closeTrains.size() == 0) {
    return from;
  }

  // delay
  float lineDelay = closeTrains.stream().map(train -> 1.0*train.getDelay()).reduce((acc, t) -> acc + t).orElse(0.0) / closeTrains.size();
  
  float maxBound = d == 10
    ? 1
    : d == 15
      ? 0.5
      : 0.25;
  float colorBase = lineDelay == 0
    ? 0
    : map(lineDelay, minDelay, maxDelay, 0, maxBound);
 
  return lerpColor(from, to, colorBase);
}

boolean hasCloseTrain(PVector vec, int d) {
  if (trainsXY == null) {
    return false;
  }
  try {
    for (Map.Entry<Integer, PVector> me: trainsXY.entrySet()) {
      if (me.getValue().dist(vec) <= d) {
        return true;
      }
    }
  } catch (Exception e) {
  }
  
  return false;
}

TableRow isTranslateNeeded(PShape trainLine) {
  TableRow tr = null;
  for (TableRow row : translates.rows()) {
    if (row.getString("id").equals(trainLine.getName())) {
      tr = row;
    }
  }
  return tr;
}

void translateIfNeeded(PShape trainLine) {
  TableRow tr = isTranslateNeeded(trainLine);
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

boolean shouldDrawTrains = true;

void keyPressed() {
  float delta = 0.001;
  
  if (key == 'y') {
    autoFollow = false;
    selected = Math.max(1, selected - 1);
  } else if (key == 'x') {
    autoFollow = false;
    selected = Math.min(showing, selected + 1);
  } else if (key == 'c') {
    autoFollow = true;
  } else if (key == 'p') {
    autoFollow = false;
    playing = true;
    pit = selected;
    ease = 0.5;
    selected = 1;
  }

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
    showingHu = !showingHu;
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
  if (history == null) {
    history = new ArrayList<>();
  }
  trains = loader.loadTrains();
  calcTrains();
  Map[] stats = getStats();
  
  raceChart = calculateChart(delays, stats[0], TOP_TRAINS);
  history.add(raceChart);
  showing++;
  if (autoFollow) {
    selected = showing;
    pit = showing;
  }
  
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

List<ChartData> calculateChart(Map<String, Float> prev, Map<String, Float> current, int top) {
  final float maxDelay = getMaxDelay();
  
  List<Map.Entry<String, Float>> empty = new ArrayList(current.size());
  Collections.fill(empty, null);

  List<Map.Entry<String, Float>> prevSorted = prev == null
    ? new ArrayList<>(current.entrySet())
    : new ArrayList<>(prev.entrySet());

  Collections.sort(prevSorted, (a, b) -> b.getValue().compareTo(a.getValue()));
  
  List<Map.Entry<String, Float>> currentSorted = new ArrayList<>(current.entrySet());
  Collections.sort(currentSorted, (a, b) -> b.getValue().compareTo(a.getValue()));
  
  List<ChartData> data = new ArrayList<>();
  
  for (int i = 0; i < Math.min(current.size(), top); i++) {
    Map.Entry<String, Float> c = currentSorted.get(i);

    int prevIndex = -1;
    for (int j = 0; j < top; j++) {
      if (prevSorted.get(j) != null && prevSorted.get(j).getKey().equals(c.getKey())) {
        prevIndex = j;
      }
    }

    Map.Entry<String, Float> p = prevIndex == -1 ? null : prevSorted.get(prevIndex);
    
    String k = c.getKey();
    float value = p == null ? 0 : p.getValue();
    float targetValue = c.getValue();
    int place = p == null ? top : prevIndex;
    int targetPlace = i;
    
    ChartData d = new ChartData(k, value, targetValue, place, targetPlace, maxDelay, Y_BASE);
    
    data.add(d);
  }
  
  //  println(data);
  return data;
}

void play() {
  if (selected + 1 < pit) {
    selected++;
  } else {
    playing = false;
    ease = 0.05;
    pit = showing;
  }
}
