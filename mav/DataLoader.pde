import java.util.*;
import java.util.function.BiConsumer;

class DataLoader {

    public DataLoader() {
    }
    
    public List<Train> loadTrains() {
      List<Train> trains = new ArrayList<>();
      
      try {
        Table table = loadTable("https://mav-delay.vercel.app/api/trains?type=csv", "csv,header");
        
        
        for (TableRow row: table.rows()) {
          trains.add(new Train(row));
        }
        
      } catch (Exception e) {
        println("Cannot reach API");
      }
      
      return trains;
    }
    
    public Map<String, List<List<Train>>> loadPerformance() {
      JSONObject report = loadJSONObject("https://raw.githubusercontent.com/szalontaijordan/mav-delay/master/report.json");
      JSONArray best = report.getJSONArray("best");
      JSONArray worst = report.getJSONArray("worst");
      
      List<List<Train>> bestTrains = new ArrayList<>();
      List<List<Train>> worstTrains = new ArrayList<>();
      
      BiConsumer<JSONArray, List<List<Train>>> fill = (JSONArray arr, List<List<Train>> addTo) -> {
        // int top = arr.size();
        int top = 15;
          
        for (int i = 0; i < top; i++) {
          List<Train> l = new ArrayList<>();
          JSONArray trains = arr.getJSONArray(i);
          
          for (int j = 0; j < trains.size(); j++) {
            l.add(new Train(trains.getJSONObject(j)));
          }
          addTo.add(l);
        }
      };
      
      fill.accept(best, bestTrains);
      fill.accept(worst, worstTrains);
      
      return Map.of("best", bestTrains, "worst", worstTrains);
    }
}
