# -*- coding: utf-8 -*-
"""
Calculation of win percentage for specific pair of starting hands. 
Demonstrates the speed of Python versus Julia. 
Python is able to read csv files much faster (0.5-1.0 seconds, versus 4.3 seconds) using Pandas.
Python is also able to store data in "pickle" format which can be accessed even faster (0.3 seconds).
"""

# python equivalent of evaluation code.

# first with pandas. speed ~0.5-1.0 seconds
import pandas as pd

# example for hands: (4♢, 8♢) and (6♠, 5♣)
hand_1 = pd.read_csv("484.csv", header = None)
hand_2 = pd.read_csv("934.csv", header = None)

hand_1_filtered = hand_1[((hand_1 != 0).astype(int) * (hand_2 != 0).astype(int)).astype(bool)].dropna()
hand_2_filtered = hand_2[((hand_1 != 0).astype(int) * (hand_2 != 0).astype(int)).astype(bool)].dropna()

h1_win_pct = (hand_1_filtered > hand_2_filtered).astype(int).mean()[0]
h2_win_pct = (hand_2_filtered > hand_1_filtered).astype(int).mean()[0]
tie_pct = 1 - h1_win_pct - h2_win_pct



# repeat with pickled datafiles. speed ~0.3 seconds 
import pickle

# pickle hand 1 and 2
outfile = open('hand_1', 'wb')
pickle.dump(hand_1, outfile)
outfile.close()

outfile = open('hand_2', 'wb')
pickle.dump(hand_2, outfile)
outfile.close()


# load files from pickel

infile = open('hand_1', 'rb')
hand_1 = pickle.load(infile)
infile.close()

infile = open('hand_2', 'rb')
hand_2 = pickle.load(infile)
infile.close()

hand_1_filtered = hand_1[((hand_1 != 0).astype(int) * (hand_2 != 0).astype(int)).astype(bool)].dropna()
hand_2_filtered = hand_2[((hand_1 != 0).astype(int) * (hand_2 != 0).astype(int)).astype(bool)].dropna()

h1_win_pct = (hand_1_filtered > hand_2_filtered).astype(int).mean()[0]
h2_win_pct = (hand_2_filtered > hand_1_filtered).astype(int).mean()[0]
tie_pct = 1 - h1_win_pct - h2_win_pct