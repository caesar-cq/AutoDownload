import requests
r = requests.get(url='https://www.ncbi.nlm.nih.gov/genomes/Genome2BE/genome2srv.cgi?action=download&orgn=&report=organelles&group=--%20All%20Eukaryota%20--&subgroup=--%20All%20Eukaryota%20--&host=All&format=',timeout=100)
  
f=file("../temp/genomes_organelles.txt","w")
f.write(r.text)

f.close()
