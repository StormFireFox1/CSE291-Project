#!/usr/bin/env python3
import pandas as pd
import json
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import os
import numbers
import math

def extract_values(dct, lst=[], keys=[]):
    if not isinstance(dct, (list, dict)):
        lst.append(('-'.join(keys), dct))
    elif isinstance(dct, list) and len(dct) <= 20:
        for i in dct:
            extract_values(i, lst, keys)
    elif isinstance(dct, dict):
        for k, v in dct.items():
            keys.append(k)
            extract_values(v, lst, keys)
            keys.remove(k)
    return lst

dir = "charts"

ec2 = "data/hashcat_atop_profile_ec2_1717051536.jsonl"
ecs = "data/hashcat_atop_profile_ecs_1717052067.jsonl"
eks = "data/hashcat_atop_profile_eks_1717055859.jsonl"
# ec2 = "data/redis_profile_ec2_202405300137.jsonl"
# ecs = "data/redis_profile_ecs_202405300647.jsonl"
# eks = "data/redis_profile_eks_202405300458.jsonl"
truncate = 25
app = "hashcat"

try:
    os.makedirs(f"{dir}/{app}")
except OSError:
    pass

sns.set_theme()

data = {}
with open(ec2) as f:
    data['ec2'] = [json.loads(line) for line in f]
with open(ecs) as f:
    data['ecs'] = [json.loads(line) for line in f]
with open(eks) as f:
    data['eks'] = [json.loads(line) for line in f]

toplot = {}
for k, v in data.items():
    toplot[k] = {}
    for i, row in enumerate(v):
        # stupid Python, have to do =[] otherwise it breaks
        for key, value in extract_values(row, lst=[], keys=[]):
            if isinstance(key, str) and isinstance(value, numbers.Number):
                if key not in toplot[k]:
                    toplot[k][key] = []
                if len(toplot[k][key]) <= i:
                    toplot[k][key].append(value)
services = []
for kd, vd in data.items():
    services.append(kd)
for k, v in toplot[services[0]].items():
    data = {}
    max = -math.inf
    for service in services:
        # yes I know it crashes here but idc cuz it works for the ones we care about
        if len(toplot[service][k]) > max:
            max = len(toplot[service][k])
    max = min(max, truncate)
    for service in services:
        array = [0]*max
        arr = toplot[service][k][1:max] # first data point is fucked for some reason
        array[:len(arr)] = arr
        data[service] = array
    if k == "CPU-utime" or k == "CPU-stime":
        print(k)
        for service in services:
            print(service)
            stime = 0
            utime = 0
            time = toplot[service][k][1:max] # first data point is fucked for some reason
            integral = 0
            for trap in range(1, len(time)):
                integral += (time[trap - 1] + time[trap]) / 2
            print(integral)
    title = f"{app}/{k}"
    name = f"{dir}/{title}.png"
    df = pd.DataFrame(data)
    plot = sns.lineplot(df, errorbar=None, )
    plot.set_title(title)
    fig = plot.get_figure()
    fig.savefig(name)
    fig.clf() # why???
