import sys
import pandas as pd

#f="/mnt/HDD3TB/derivatives/cancer-sim-search-SAILOR_PROCESSED_MNI-001-QUUyOkRb-longitudinal/01_02/001-QUUyOkRb/results-cc.txt"

d=pd.read_csv(sys.argv[1], delimiter="\t", encoding="utf-8")
#d=pd.read_csv(f, delimiter="\t", encoding="utf-8")

thr=0.7

max_value = d["cc"].max()
min_value = d["cc"].min()
d["ccnorm"] = (d["cc"] - min_value) / (max_value - min_value)

d=d[d["ccnorm"] >= thr]

d2=d.copy()

d2["disp"] = d["disp"].abs()
max_value = d2["disp"].max()
min_value = d2["disp"].min()
d2["disp"] = (d2["disp"] - min_value) / (max_value - min_value) 

max_value = d["idf"].max()
min_value = d["idf"].min()
d2["idf"] = (d["idf"] - min_value) / (max_value - min_value) 

d2["avgdi"] = d2[["disp", "idf"]].mean(axis=1) 

idx=d2.sort_values(by="avgdi", ascending=False).index

#print(d.loc[d2["avgdi"].idxmax()])
#print(d2.loc[idx])
#print(d2.loc[idx].iloc[0])
#print(d.loc[idx])

print(d.loc[idx].iloc[0])
