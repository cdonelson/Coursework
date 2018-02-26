////Curtis Donelson, CMSC 401 assignment #4
import java.util.Scanner;
import java.util.Arrays;
import java.util.List;
import java.util.ArrayList;

public class cmsc401
{
  public static void main(String[] args)
  {   
    Scanner sc = new Scanner(System.in);
    int numCities = sc.nextInt(); 
    int numRoads = sc.nextInt();
    int motelCost[] = new int[numCities+1];
    int cityNumber[] = new int[numCities+1];
    motelCost[0] = motelCost[1] = motelCost[2] = 0;
    cityNumber[0] = 0;
    cityNumber[1] = 1;
    cityNumber[2] = 2;
    List<City> blackNodes = new ArrayList<City>();
    List<City> whiteNodes = new ArrayList<City>();
    City zeroCity = new City(0,0);                // Keep city numbers = index by keeping 0 index zeroed
    whiteNodes.add(zeroCity);
    blackNodes.add(zeroCity);
    
    for (int i = 3; i <= numCities; i++)   // Read in city numbers and motel costs
    {
      cityNumber[i] = sc.nextInt();
      motelCost[i] = sc.nextInt();
    }
    
    for (int z = 1; z <= numCities; z++)   // populate City nodes
    { 
      City tempCity = new City(cityNumber[z], motelCost[z]);
      whiteNodes.add(tempCity);
    }
    
    int gasCost[][] = new int[numCities+1][numCities+1];  // create gasCost/adjacency matrix
    for (int[] row : gasCost)
    { Arrays.fill(row, 0); } 
    int cityOne, cityTwo, gasPrice; 
    for (int j = 1; j <= numRoads; j++)      // Read in intercity gasCosts 
    {
      cityOne = sc.nextInt();
      cityTwo = sc.nextInt();
      gasPrice = sc.nextInt();
      gasCost[cityOne][cityTwo] = gasPrice;
      gasCost[cityTwo][cityOne] = gasPrice;
    }

    int totalCost[][] = new int[numCities+1][numCities+1];  //totalCost matrix for traveling from any city to another
    for (int a = 1; a <=numCities; a++)
    {
      for (int b = 1; b <=numCities; b++)
      {
        totalCost[a][b] = gasCost[a][b] + motelCost[b];
      }
    } 
    
    int costFromStart[] = new int[numCities+1];  // costFromStart array holds shortest mileage beetween start city and all others
    Arrays.fill(costFromStart, 999);
    costFromStart[0]=costFromStart[1]=0;
    int currentCity = 1;
    int nextCity = 0;
    boolean blackNodesBool[] = new boolean[numCities+1];  // blackNodesBool boolean array to track if city is finalized
    Arrays.fill(blackNodesBool, false);
    blackNodesBool[0] = true;
    int closestWhiteNode = 999;   // closestWhiteNode tracks distance of closest node not yet blacked out
    
    while(blackNodes.size() <= numCities)
    {
      for(int g = 1; g <= numCities; g++)  // start ID of next city to check
      {
        if(blackNodesBool[g] == false)   // if city has not been cleared already...
        {
          if(costFromStart[g] < closestWhiteNode)   // if cost from S to this city is less than cWN
          {           
            currentCity = g;                       // setes current city to be this closer city
            closestWhiteNode = costFromStart[g];   // updates the closest distance
          }
        }
      }
      closestWhiteNode = 1000;
      blackNodes.add(whiteNodes.get(currentCity));
      for(int f = 1; f <=numCities; f++) // begins check of neighbors
      {
        if(gasCost[currentCity][f] > 0)   // checks for neighbors of current city
        {
          if(costFromStart[currentCity] + totalCost[currentCity][f] < costFromStart[f]) // updates cost from S array
          {
            costFromStart[f] = totalCost[currentCity][f] + costFromStart[currentCity];
          }
        }
      }
      blackNodesBool[currentCity] = true;   // notes when a node has turned black
//      currentCity = nextCity;               // moves to nextCity for 
    }
    System.out.println(costFromStart[2]);
  }
}

class City
{
  private int cityNum;
  private int motelCost;
  private City prevCity;
  
  public City(int inCityNum)
  {
    this.cityNum = inCityNum;
    this.prevCity = null;
  }
  
  public City(int inCityNum, int inMotelCost)
  {
    this.cityNum = inCityNum;
    this.motelCost = inMotelCost;
    this.prevCity = null;
  }
  
  public int getCityNum()
  { return this.cityNum; }
  
  public void setCityNum(int inCityNum)
  { this.cityNum = inCityNum; }
  
  public int getMotelCost()
  { return this.motelCost; }
  
  public void setMotelCost(int inMotelCost)
  { this.motelCost = inMotelCost; }
  
  public City getPrevCity()
  { return this.prevCity; }
    
  public void setPrevCity(City inCity)
  { this.prevCity = inCity; }
  
  public void printCity()
  {
    System.out.println("City number: " + this.cityNum + ".  Motel cost: " + this.motelCost + ". Previous city: " +
                       this.prevCity);
  }
}