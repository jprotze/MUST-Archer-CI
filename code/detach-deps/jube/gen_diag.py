import re
import string
import sys

import matplotlib.pyplot as plt
import matplotlib.transforms as transforms
import matplotlib.patches as mpatches
from matplotlib.ticker import (AutoMinorLocator, MultipleLocator)

import numpy as npy

input="time_csv.dat"
if len(sys.argv)>1:
    input=sys.argv[1]

suffix=""
if len(sys.argv)>2:
    suffix=sys.argv[2]

headers = []
base = {}
rdata = {}
odata = {}

gnt = gnp = 0
gts = set()

with open(input) as file: 
    try:
        for ln, line in enumerate(file):
            if(ln==4):
                print(base)
            cols = line.strip().split(",")
            if cols[0] == "":
                continue
            if cols[0] == '"class"':
                headers = cols
                continue
            ts = int(cols[1].split(" ")[1])
            gts.add(ts)
            gnt = nt = int(cols[2][1])
            gnp = np = int(cols[3][1])
            if cols[0] == '"base-none"':
                base[(ts,nt,np)]=cols[7:]
                rdata[(ts,nt,np)]={}
                odata[(ts,nt,np)]={}
            elif cols:
                if cols[0] not in rdata[(ts,nt,np)]:
                    rdata[(ts,nt,np)][cols[0]]={}
                    odata[(ts,nt,np)][cols[0]]={}
                rdata[(ts,nt,np)][cols[0]][tuple(cols[4:7])]=cols[7:]
                odata[(ts,nt,np)][cols[0]][tuple(cols[4:7])]=[ float(a)/float(b) if a else -1. for a,b in zip(cols[7:],base[(ts,nt,np)]) ][0::4]
    except:
        print(cols)
        raise

print (base)
print (odata)


#xes = npy.array(sorted((list(range(len(allapps)))*9)))

ll = ["Eager ", "Lazy "]
lt = ["thread ", "task "]
ld = ["pool ", "direct "]

xdata = [(l,t,d) for t in (0,1) for l in (0,1) for d in (0,1)]
xdatas = [(str(l),str(t),str(d)) for (l,t,d) in xdata]

#xlabels = [l+t+d for l in ll for t in lt for d in ld]
xlabels = [ll[l]+ld[d]+lt[t] for (l,t,d) in xdata]
#xlabels = [str(a) for a in xdata]

plotcolors=['#00549F', '#612158', '#CC071E', '#F6A800', '#FFED00', '#BDCD00', '#57AB27', '#006165']
markers = ["o" , "," , "v" , "^" , "<", ">"]
x = npy.arange(8)

for nt in (gnt,):
    np = gnp
    fig, ax = plt.subplots(1,figsize=(6,4))
    ax.set_ylabel('Rel. Runtime')

    for e,size in enumerate(gts):
        for ae,app in enumerate(odata[(size,nt,np)].keys()):
            data = npy.array([odata[(size,nt,np)][app][a][0] for a in xdatas]).flatten()
    #        data = npy.array([a[0] for a in odata[(size,nt,np)][app].values()]).flatten()
            ax.scatter(x-(1-e)/5, data, color=plotcolors[ae], marker=markers[e], s=10, label="%s (%i)"%(app[6:-1],size))

    ax.set_ylim(bottom=0,top=12.4)
    ax.legend(bbox_to_anchor=(0,1,1,1), loc="lower left", ncol=3, mode="expand")

    ax.set_xticks(x)
    ax.set_xticklabels(xlabels)
    plt.setp(ax.get_xticklabels(), rotation=30, ha="right")
    fig.tight_layout()

    plt.savefig('time-%i%s.pdf' % (nt,suffix))

    fig, ax = plt.subplots(1,figsize=(6,4))
    ax.set_ylabel('Rel. Memory Usage')

    for e,size in enumerate(gts):
        for ae,app in enumerate(odata[(size,nt,np)].keys()):
            data = npy.array([odata[(size,nt,np)][app][a][1] for a in xdatas]).flatten()
            ax.scatter(x-(1-e)/5, data, color=plotcolors[ae], marker=markers[e], s=10, label="%s (%i)"%(app[6:-1],size))

    ax.set_ylim(bottom=0)
    ax.legend(bbox_to_anchor=(0,1,1,1), loc="lower left", ncol=3, mode="expand")

    ax.set_xticks(x)
    ax.set_xticklabels(xlabels)
    plt.setp(ax.get_xticklabels(), rotation=30, ha="right")
    fig.tight_layout()

    plt.savefig('mem-%i%s.pdf' % (nt,suffix))

