import java.util.*;
import java.text.DateFormat;
import java.time.format.DateTimeFormatter;
import java.time.LocalDate;

class DataRow implements Comparable<DataRow> {
  
  private LocalDate date;
  
  private int cases;
  private int deaths;
  private String countriesAndTerritories;
  private String geoId;
  private String countryterritoryCode;
  private int popData2019;
  private String continentExp;
  private float cumulative14daysFor1000;
  
  public DataRow(TableRow row) throws Exception {
    this.setDateFromRow(row);
    this.cases = row.getInt("cases");
    this.deaths = row.getInt("deaths");
    this.countriesAndTerritories = row.getString("countriesAndTerritories");
    this.geoId = row.getString("geoId");
    this.countryterritoryCode = row.getString("countryterritoryCode");
    this.popData2019 = row.getInt("popData2019");
    this.continentExp = row.getString("continentExp");  
    this.cumulative14daysFor1000 = row.getFloat("Cumulative_number_for_14_days_of_COVID-19_cases_per_100000");
  }

  public LocalDate getDate() {
    return this.date;
  }

  public String getContinent() {
    return this.continentExp;
  }

  public int getCases() {
    return this.cases;
  }

    public String getGeoId() {
    return this.geoId;
  }

  @Override
  public int compareTo(DataRow otherRow) {
    return otherRow.getDate().isBefore(this.date)
      ? 1
      : this.date.isBefore(otherRow.getDate())
        ? -1
        : 0;
  }

  @Override
  public String toString() {
      String s = "";

      DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd");
      String formattedString = this.date.format(formatter);
      s += formattedString;

      return s;
  }

  private void setDateFromRow(TableRow row) throws Exception {
    int day = row.getInt("day");
    int month = row.getInt("month");
    int year = row.getInt("year");
    
    DateTimeFormatter df = DateTimeFormatter.ofPattern("dd-MM-yyyy");
    String dd = day < 10 ? "0" + day : Integer.toString(day);
    String MM = month < 10 ? "0" + month : Integer.toString(month);
    
    String input = dd + "-" + MM + "-" + year;
    
    LocalDate localDate = LocalDate.parse(input, df);

    this.date = localDate;
  }
  
}
