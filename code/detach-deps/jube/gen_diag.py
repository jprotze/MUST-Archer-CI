import re
import string
import sys

import matplotlib.pyplot as plt
import matplotlib.transforms as transforms
import matplotlib.patches as mpatches
from matplotlib.ticker import (AutoMinorLocator, MultipleLocator)

import numpy as np

input="time_csv.dat"
if len(sys.argv)>1:
    input=sys.argv[1]

headers = []
base = {}
data = {}
odata = {}

with open(input) as file: 
    for line in file:
        cols = line.strip().split(",")
        if cols[0] == '"class"':
            headers = cols
            continue
        ts = int(cols[1][15])
        nt = int(cols[2][1])
        np = int(cols[3][1])
        if cols[0] == '"base-none"':
            base[(ts,nt,np)]=cols[7:]
            data[(ts,nt,np)]={}
            odata[(ts,nt,np)]={}
        else:
            if cols[0] not in data[(ts,nt,np)]:
                data[(ts,nt,np)][cols[0]]={}
                odata[(ts,nt,np)][cols[0]]={}
            data[(ts,nt,np)][cols[0]][tuple(cols[4:7])]=cols[7:]
            odata[(ts,nt,np)][cols[0]][tuple(cols[4:7])]=[ float(a)/float(b) for a,b in zip(cols[7:],base[(ts,nt,np)]) ][0::4]

print (base)
print (odata)


fig, ax = plt.subplots(1,figsize=(6,4))
ax.set_ylabel('Runtime in seconds')
x = np.arange(8)
#xes = np.array(sorted((list(range(len(allapps)))*9)))
plotcolor=['#00549F', '#612158', '#CC071E', '#F6A800', '#FFED00', '#BDCD00', '#57AB27', '#006165']
markers = ["o" , "," , "v" , "^" , "<", ">"]

for e,size in enumerate(7,8,9):
    for ae,app in enumerate(odata[(size,8,4)].keys()):
        data = np.array([a[0] for a in odata[(size,8,4)][app].values()]).flatten()
        ax.scatter(x-(1-e)/5, data, color=plotcolors[i], marker=markers[ae], s=1, label="%s(%i)"%(app,size))


plt.savefig('base.pdf')