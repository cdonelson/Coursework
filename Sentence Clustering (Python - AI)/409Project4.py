import re
import math
from Porter_Stemmer_Python import PorterStemmer

# Accepts a list of n-variables where i=0 is the CoG.  Returns new CoG based off of i=1,2...n-1,n variables
# m tracks the number of variables.  The "-2" reflects the fact that inList includes two values that should not
# be considered: i=0 (the original CoG) and i=n (the new pattern requiring an update to the CoG).  This maintains original formula

# Determine radius of clusters
maxRadius   = 3.50
alpha       = 0.75

def UpdateCOG(inList):
    m = len(inList)-2
    for index,col in enumerate(inList[0]):
        inList[0][index] = (m*inList[0][index] + alpha*inList[-1][index])/(m+1)
    return inList[0]

def VectorDist(inArrayOne, inArrayTwo):
    distance = 0.0
    for colIndex, column in enumerate(inArrayOne):
        distance += (inArrayOne[colIndex] - inArrayTwo[colIndex])**2
    return math.sqrt(distance)

def RunFCAN(patternArray,maxRadius):

    # List of lists to represent unique clusters.  Each sublist is a cluster whose first element is its weights
    clusterList = []
    for rowIndex, row in enumerate(patternArray):  # Loop through each pattern and assign it to a cluster
        print("------------------------------")
        tempList = []
        clusterFlag = 0
        minDist = 99999.9
        minCluster = -1
        if(rowIndex == 0):  # First pattern assigned automatically because there are no other clusters to compare with
            tempList.append(row[:])
            tempList.append(row[:])
            clusterList.append(tempList[:])
            print("Created cluster 0")
        else:
            for clusterIndex, cluster in enumerate(clusterList):    # Checks distance to each cluster already in clusterList
                distToCluster = VectorDist(row,clusterList[clusterIndex][0])
                print("Check distance between row ",rowIndex," and cluster ",clusterIndex,": ",distToCluster)
                if (distToCluster < minDist) and (distToCluster < maxRadius):    # If cluster CoG is closest one seen...
                    minDist = distToCluster   # Update closest distance
                    minCluster = clusterIndex                                 # Update closest cluster
                    print("Update closest cluster for row ", rowIndex," to cluster ",clusterIndex)
                    clusterFlag = 1
            if clusterFlag == 0:
                tempList.append(row[:])
                tempList.append(row[:])
                clusterList.append(tempList[:])
                print("Created cluster ",len(clusterList)-1)
            else:
                clusterList[minCluster].append(row)
                clusterList[minCluster][0] = UpdateCOG(clusterList[minCluster])
                print("Added row ",rowIndex," to cluster", minCluster)
                #print("Center of Gravity: ", clusterList[minCluster][0])

    with open("sentences.txt", encoding="utf8") as f:
        sentenceList = f.read().splitlines()
    for clusterIndex,cluster in enumerate(clusterList):
        print("Cluster ",clusterIndex," contains ",len(clusterList[clusterIndex])-1," elements.")
        for rowIndex, row in enumerate(patternArray):
            if patternArray[rowIndex] in clusterList[clusterIndex]:
                print("Sentence ",rowIndex,"     ",sentenceList[rowIndex])

def duplicates(features):
  exists = set()
  duplicates = set(x for x in features if x in exists or exists.add(x))
  return list(duplicates)

def print_TDM(termDocMatrix):
    for rowIndex, row in enumerate(featureVector):
        print (str(row) + ",", end='')
        for x in range(len(termDocMatrix)):
            print (str(termDocMatrix[x][rowIndex]) + ",", end='')
        print ()

#####################
##   Core Logic    ##
#####################

ps = PorterStemmer()
filename = "sentences.txt"
stopfile = "stop_words.txt"

with open(filename, encoding="utf8") as f:
    sentenceList = f.read().splitlines()
with open(stopfile, encoding="utf8") as f:
    stopWords = f.read().splitlines()

sentVectors = []  # List to hold processed sentences as vectors (functions as a list of lists)
featureVector = []  # List to hold the feature vector containing all processed words as stems

# Process fulltext sentences into useable words; lowercase, remove non-letters, etc.
for sentIndex,sent in enumerate(sentenceList):
    tempSent = re.sub('[^a-zA-Z\s]','',sentenceList[sentIndex])
    tempSent = tempSent.lower()
    tempSent = ' '.join(tempSent.split())
    sentVectors.append(tempSent.split())

# Moves through sentVectors and pops off any stopWords as found in "stop-words.txt"
for rowIndex in range(len(sentVectors)):
    colIndex = 0
    while colIndex < len(sentVectors[rowIndex]):    # A while statement that moves through each word in a sentence.  I used "while" so that if I pop off a stopword it won't go out of bounds
        if sentVectors[rowIndex][colIndex] in stopWords:
            sentVectors[rowIndex].pop(colIndex)
        else:
            sentVectors[rowIndex][colIndex] = ps.stem(sentVectors[rowIndex][colIndex],0,len(sentVectors[rowIndex][colIndex])-1)    # Stems each non-stop word
            featureVector.append(sentVectors[rowIndex][colIndex])                                                                  # Adds word to featureVector
            colIndex += 1
    rowIndex += 1

print ("Initial Feature Vector Size: ", len(featureVector))
featureVector = duplicates(featureVector) # Use only features which are duplicated (i.e. exist in 2 or more sentences)
print ("Final Feature Vector Size: ", len(featureVector))
print (featureVector)

# Build the Term Document Matrix
termDocMatrix = [[0 for col in range(len(featureVector))] for row in range(len(sentVectors))]  # Populates a Term Document Matrix with zeroes
for rowIndex, row in enumerate(sentVectors):                         #  The fun part: Moves down each row (which is a processed sentence vector)
    for wordIndex, word in enumerate(sentVectors[rowIndex]):        #  Moves horizontally across each word in that sentence
        for colIndex, col in enumerate(featureVector):              #  Looks to see if a word is in a feature Vector
            if sentVectors[rowIndex][wordIndex] == featureVector[colIndex]:    # If it is....
                termDocMatrix[rowIndex][colIndex] += 1                        #  Add 1 to the Term Doc Matrix at that row (sentence) and that feature

# Print the TDM in CSV format for showing in a table
#print_TDM(termDocMatrix)

# Send frequency vectors to FCAN for clustering, printing results
RunFCAN(termDocMatrix,maxRadius)
