import java.util.*;

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
}
