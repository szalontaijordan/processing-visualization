class Train {

  /*
  "delay": 2,
  "lat": 47.19125,
  "lon": 20.1363,
  "type": "MAV",
  "line": "120A",
  "relation": "Hegyeshalom - Záhony"
  
  */
  private final int delay;
  private final float lat;
  private final float lon;
  private final String line;
  private final String relation;
  
  public Train(TableRow row) {
    this.delay = row.getInt("delay");
    this.lat = row.getFloat("lat");
    this.lon = row.getFloat("lon");
    this.line = row.getString("line");
    this.relation = row.getString("relation");
  }
  
  public Train(JSONObject obj) {
    this.delay = obj.getInt("delay");
    this.lat = obj.getFloat("lat");
    this.lon = obj.getFloat("lon");
    this.line = obj.getString("line");
    this.relation = obj.getString("relation");
  }
  
  public float getLat() {
    return this.lat;
  }
  
  public float getLon() {
    return this.lon; 
  }
  
  public String getLine() {
    return this.line;
  }
  
  public int getDelay() {
    return this.delay;
  }
  
  public String getInfo() {
    String info = this.relation;
    
    if (this.delay > 0) {
      info += "\nKésés: " + this.delay + " perc";  
    }
    
    return info;
  }
  
  @Override
  public String toString() {
    return this.lat + ", " + this.lon;
  }
}
