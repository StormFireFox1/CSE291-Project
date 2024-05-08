# Visualization Code

Python scripts and Jupyter notebooks to handle visualizing profiling data from `atop`.

## Usage

First, obtain an `atop` profile file from our profiling dumps. Then, run:

```sh
atop -r "<ATOP PROFILE LOG FILE>" -J ALL > atop-profile.jsonl
```

Then, you may use the Jupyter notebook to appropriately handle the data.
