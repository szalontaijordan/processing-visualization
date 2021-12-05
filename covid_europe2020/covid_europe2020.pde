import java.util.*;
import java.text.DateFormat;
import java.time.format.DateTimeFormatter;
import java.time.LocalDate;
import java.time.Duration;
import controlP5.*;

ControlP5 cp5;

PShape europeSVG;
Table table;
HashMap<String, Integer> stats = new HashMap<String,Integer>();

List<DataRow> data;
int maxCases = -1;

LocalDate fromDate;
LocalDate toDate;

Scene currentScene;
Set<String> selectedCountries = new HashSet<>();

final int padding = 128;

void setup() {
  size(680, 620);

  europeSVG = loadShape("europe.svg");
  setupData();
  setStats();
  
  setupControls();
  
  currentScene = Scene.Map;
  // currentScene = Scene.Chart;
  selectedCountries.add("hu");
}

void mouseClicked() {
  stats.keySet().stream()
    .map((key) -> getCountry(europeSVG, key))
    .filter((child) -> child != null)
    .filter((child) -> child.contains(mouseX, mouseY))
    .map((country) -> country.getName())
    .forEach((country) -> {
      if (selectedCountries.contains(country)) {
        selectedCountries.remove(country);
      } else {
        selectedCountries.add(country);
      }
      
    });
    
  if (currentScene.equals(Scene.Map)) {
    drawMap();
  }

}

void setupData() {
  table = loadTable("data.csv", "header");
  data = new ArrayList<DataRow>();

  try {
    for (TableRow row: table.rows()) {
      if (row.getString("continentExp").equals("Europe") && !row.getString("geoId").equals("RU")) {
        data.add(new DataRow(row));
      }
    }
  } catch(Exception e) {
    println(e.getMessage());
  }
  
  if (data == null) {
    println("failed to read data");
    System.exit(0);
  }
  
  Collections.sort(data);
  println(data.get(0));
}

void setMax() {
  maxCases = (int) stats.values().stream()
    .reduce((acc, cases) -> Math.max(acc, cases))
    .get();
  
}

void setStats() {
    stats = new HashMap<String, Integer>();
    
    data.stream()
      .filter((row) -> dateRestriction(row.getDate()))
      .forEach((row) -> {
        String cc = row.getGeoId();
        int count = row.getCases();
  
        if (stats.get(cc) == null) {
          stats.put(cc, count);
        } else {
          stats.put(cc, stats.get(cc) + count);
        }
      });    
      
    setMax();
}

List<Controller> mapControllers;
Controller goBackButton;

int tox = 40;
int fromx = 600;

void setupControls() {
  mapControllers = new ArrayList<>();
  cp5 = new ControlP5(this);

  cp5.addSlider("dateSlider1")
     .setPosition(padding / 2, 534)
     .setWidth(680 - padding)
     .setHeight(16)
     .setRange(0, data.size() - 1)
     .setValue(data.size())
     .setNumberOfTickMarks(data.size())
     .setHandleSize(32)
     .setSliderMode(Slider.FLEXIBLE);
     
  cp5.addSlider("dateSlider2")
     .setPosition(padding / 2, 550)
     .setWidth(680 - padding)
     .setHeight(16)
     .setRange(0, data.size() - 1)
     .setValue(0)
     .setNumberOfTickMarks(data.size())
     .setHandleSize(32)
     .setSliderMode(Slider.FLEXIBLE);
     
  cp5.addButton("goButton")
     .setValue(0)
     .setPosition(240,590)
     .setLabel("Go")
     .setSize(200,24);
     
  cp5.addButton("goBackButton")
     .setValue(0)
     .setPosition(240,590)
     .setLabel("Go Back")
     .setSize(200,24);
     
  mapControllers.add(cp5.getController("dateSlider1"));
  mapControllers.add(cp5.getController("dateSlider2"));
  mapControllers.add(cp5.getController("goButton"));
  
  goBackButton = cp5.getController("goBackButton");
  goBackButton.hide();
  
  cp5.getController("dateSlider1").setLabelVisible(false);
  // cp5.getController("dateSlider1").setColorBackground(#e2f9fe);
  
  cp5.getController("dateSlider2").setLabelVisible(false);
  // cp5.getController("dateSlider2").setColorBackground(#e2f9fe);

  cp5.getController("dateSlider1").onDrag((event) -> {
    fromx = mouseX;
    setStats();
  });
  cp5.getController("dateSlider2").onDrag((event) -> {
    tox = mouseX;
    setStats();
  });
  
  cp5.getController("goButton").onClick((event) -> {
    currentScene = Scene.Chart;
    
    // mapControllers.stream().forEach((controller) -> controller.hide());
    goBackButton.show();
  });
  
  cp5.getController("goBackButton").onClick((event) -> {
    currentScene = Scene.Map;
    // mapControllers.stream().forEach((controller) -> controller.show());
    goBackButton.hide();
  });
}

PShape getCountry(PShape eu, String cc) {
  return eu.getChild(cc.toLowerCase());
}

boolean dateRestriction(LocalDate rowDate) {
  if (fromDate == null && toDate == null) {
    return true;
  }
  return (rowDate.isBefore(toDate) || rowDate.isEqual(toDate))
    && (rowDate.isAfter(fromDate) || rowDate.isEqual(fromDate));
}

int curr;

void drawEU() {
  background(#e2f9fe);
  fill(#e2f9fe);
  stroke(#232323);
  shape(europeSVG, 0, 0);
}

void draw() {
  int fromDateIndex = (int) (cp5.getController("dateSlider1").getValue());
  int toDateIndex = (int) (cp5.getController("dateSlider2").getValue());
  
  if (fromDateIndex > toDateIndex) {
    fromDate = data.get(toDateIndex).getDate();
    toDate = data.get(fromDateIndex).getDate();
  } else {
    fromDate = data.get(fromDateIndex).getDate();
    toDate = data.get(toDateIndex).getDate();
  }
  
  if (currentScene.equals(Scene.Map)) {
    drawMap();
  }
  
  if (currentScene.equals(Scene.Chart)) {
    drawChart();
  }
  
  if (fromDate != null) {
    fill(#000000);
    textAlign(CENTER);
    text(data.get(toDateIndex).getDate().toString(), Math.max(40, tox), 580);
  }
  
  if (toDate != null) {
    fill(#000000);
    textAlign(CENTER);
    text(data.get(fromDateIndex).getDate().toString(), Math.min(fromx, 580), 530);
  }
}

void drawChart() {
  background(#e2f9fe);
  
  final int range = 1 + ((int) Duration.between(fromDate.atStartOfDay(), toDate.atStartOfDay()).toDays());
  final Map<String, float[]> chartData = new HashMap<>();
  
  selectedCountries.stream()
    .forEach((cc) -> {
        float[] y = new float[range];
        data.stream()
          .filter((row) -> row.getGeoId().toLowerCase().equals(cc.toLowerCase()))
          .filter((row) -> dateRestriction(row.getDate()))
          .forEach((row) -> {
            // println(row.getDate());
            // println(fromDate);
            LocalDate a = fromDate.isBefore(row.getDate()) ? fromDate : row.getDate();
            LocalDate b = a == fromDate ? row.getDate() : fromDate;
            int idx = (int) Duration.between(a.atStartOfDay(), b.atStartOfDay()).toDays();
            y[idx] = row.getCases();
          });
          
        for (int i = 1; i < y.length; i++) {
          // some values are reported negative to correct previous false values
          // substracting that from previous day
          if (y[i] < 0 && y[i - 1] > 0) {
            y[i - 1] = Math.max(0, y[i - 1] - y[i]);
            y[i] = y[i - 1];
          }
          
          // if there is no data, take the previous
          if (y[i] == 0 && y[i - 1] != 0) {
            y[i] = y[i - 1];
          }
        }  
        chartData.put(cc, y);
    });
    
  final int max = data.stream()
    .filter((row) -> selectedCountries.contains(row.getGeoId().toLowerCase()))
    .filter((row) -> dateRestriction(row.getDate()))
    .map((row) -> row.getCases())
    .reduce((acc, cases) -> Math.max(acc, cases))
    .orElse(0);
  
  color from = color(204, 102, 0);
  color to = color(0, 102, 153);
  
  Map<String, Float> colors = new HashMap<>();
  List<String> selectedList = new ArrayList<>(selectedCountries);
  
  for (int i = 0; i < selectedCountries.size(); i++) {
    String cc = selectedList.get(i);
    float step = (i+1) * 1.0 / selectedCountries.size();
    colors.put(cc, step);
  }
  
  chartData.entrySet().stream()
    .forEach((entry) -> {
      // println(entry.getKey());
      // println(Arrays.toString(entry.getValue()));
      color col = lerpColor(from, to, colors.get(entry.getKey()));

      drawCountry(entry.getValue(), max, col, padding, range);
    });
  
  // origo
  textAlign(RIGHT);
  text("0", padding / 2 - 8, 500);
  circle(padding / 2, 500, 3);
  // draw y axis
  line(padding / 2, 50, padding / 2, 500);
  final int numYTicks = 12;
  final int yStep = max / numYTicks;

  for (int i = 1; i <= numYTicks; i++) {
    float tick = map(i, 1, numYTicks, 50, 500);
    
    stroke(#000000);
    circle(padding / 2, tick, 4);
    
    text(Integer.toString(Math.abs(numYTicks - i) * yStep), padding / 2 - 8, tick);
    stroke(color(35, 35, 35, 35));
    line(padding / 2, tick, 680 - padding / 2, tick);
  }
  
  // draw x axis
  line(padding / 2, 500, 680 - padding / 2, 500);
  final int numXTicks = 12;

  for (int i = 1; i <= numXTicks; i++) {
    float tick = map(i, 1, numXTicks, padding / 2, 680 - padding / 2);
    
    stroke(#000000);
    circle(tick, 500, 4);
  }
  
  // draw moving horizontal legend
  if (inChart(mouseX, mouseY)) {
    stroke(color(64, 64, 64, 128));
    int x = paddingBoundary(mouseX);
    line(x, 50, x, 500);
    fill(color(255, 255, 255, 64));
    
    int rectX = x - 84;
    rect(rectX, 80, 64, 20 + 20 * selectedCountries.size());
    
    for (int i = 0; i < selectedList.size(); i++) {
      String cc = selectedList.get(i).toUpperCase();
      fill(#000000);
      int y = (i+1)*16+100;
      text(cc, rectX + 20, y);
      
      color countryColor = lerpColor(from, to, colors.get(selectedList.get(i)));
      fill(countryColor);
      stroke(#ffffff);
      rect(rectX + 24, y - 8, 8, 8);
    }
    
    textAlign(LEFT);
    fill(#000000);
    text(getXDateString(mouseX, range), rectX + 4, 94);
  }
}

int xMin = padding / 2;
int xMax = 680 - padding / 2;
int yMin = 50;
int yMax = 500;

String getXDateString(int x, int range) {
  if (fromDate == null || toDate == null) {
    return "";
  }
  
  LocalDate date = fromDate.isBefore(toDate) ? fromDate : toDate;
  int index = (int) map(x, xMin, xMax, 0, range);
  return date.plusDays(index).toString();
}

boolean inChart(int x, int y) {
  return xMin <= x && x <= xMax
    && yMin <= y && y <= yMax;
}

int paddingBoundary(int x) {
  if (x < padding / 2) {
    return padding / 2;
  }
  if (x > 680 - padding / 2) {
    return 680 - padding / 2;
  }
  return x;
}

void drawCountry(float[] y, int max, color col, int padding, int range) {
  fill(col);
  stroke(col);
  
  List<Float> tmp = new ArrayList<>();
  for (int x = 0; x <= y.length; x++) {
    if (tmp.size() == 4) {
      line(tmp.get(0), tmp.get(1), tmp.get(2), tmp.get(3));
      tmp.remove(0);
      tmp.remove(0);
    }
    
    if (x == y.length) {
      break;
    }
   
    float xi = map(x, 0, y.length, padding / 2, 680 - padding / 2);
    float yi = 500 - map(y[x], 0, max, 0, 400);
    
    circle(xi, yi, 2);
    
    int fourMonths = 30*4;
    
    if (range <= fourMonths) {
      if (dist(xi, yi, mouseX, mouseY) <= 4) {
        circle(xi, yi, 8);
        text(Integer.toString((int) y[x]), mouseX - 10, mouseY - 10);
      } else {
        circle(xi, yi, 4);
      }
    }
    
    tmp.add(xi);
    tmp.add(yi);
  }
  
}

void drawStats(color from, color to) {
  if (fromDate != null && toDate != null) {
    // noStroke();
    // fill(#ffffff);
    // rect(20, 140, 140, 55);
    
    // fill(#000000);
    // String dateString = fromDate.toString() + " - " + toDate.toString();
    
    // textAlign(LEFT);
    // text(dateString, 30, 160);
    // text("Max: " + Integer.toString(maxCases), 30, 176);
  }
   
  noStroke();
  for (int i = 100; i >= 1; i--) {
    fill(lerpColor(to, from, i / 100.0));
    rect(20, 200, 20, 2*i);
  }

  fill(#000000);
  textAlign(LEFT);
  text("0", 42, 400);
  text(Integer.toString(maxCases), 42, 200);
}

void drawMap() {
  color from = #ffe3e3;
  color to = color(#990000);

  drawEU();
  drawStats(from, to);
  strokeWeight(4);

  for (Map.Entry<String, Integer> me : stats.entrySet()) {
    String cc = (String) me.getKey();
    PShape c = getCountry(europeSVG, cc);
    int val = me.getValue();
    
    if (c != null && val > 0) {
      float scaled = map(val, 0, maxCases, 0, 1);
      c.disableStyle();      
      
      if (c.contains(mouseX, mouseY)) {
        curr = val;
        fill(#ffffff);
        stroke(#00ff00);
        strokeWeight(2);
      } else {
        stroke(#ffffff);
        strokeWeight(1);
      }
      
      fill(lerpColor(from, to, scaled));
      
      if (selectedCountries.contains(cc.toLowerCase())) {
        fill(#0000ff);
        shape(c);
      } else {
        shape(c);
      }
      
      c.enableStyle();
    }
  }
}
