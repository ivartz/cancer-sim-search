import sys
import pandas as pd
import numpy as np

d=pd.read_csv(sys.argv[1], delimiter="\t", encoding="utf-8")

# Trick to mark where there is no noise by setting "pres" parameter to "No"
#d["pres"] = np.where(d["pabs"] == 0.0, 1, d["pres"]) # No
#d["pres"] = np.where(d["pres"] == 0.05, 2, d["pres"]) # Intermediate
#d["pres"] = np.where(d["pres"] == 0.03, 3, d["pres"]) # High

d["pres"] = np.where(d["pabs"] == 0.0, "No", d["pres"]) # No
d["pres"] = np.where(d["pres"] == "0.05", "Intermediate", d["pres"]) # Intermediate
d["pres"] = np.where(d["pres"] == "0.03", "High", d["pres"]) # High

d["idf"] = np.where(d["idf"] == 1.0 , "Low", d["idf"]) # Low
d["idf"] = np.where(d["idf"] == "0.1", "High", d["idf"]) # High

d.reset_index(level=0, inplace=True)

d.rename(columns={"patient":"Patient","part":"Part","disp":"Magnitude [mm]","idf":"Brain coverage","pres":"Irregularity","cc":"Cross-Correlation"}, inplace=True)

idx = d.groupby(["Patient"])["Cross-Correlation"].transform(max) == d["Cross-Correlation"]

#print(d)

#print(d[idx])

d[idx].to_csv(sys.argv[2], sep = "\t", index=False)

