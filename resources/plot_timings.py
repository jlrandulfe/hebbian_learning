#!/usr/bin/env python3
"""
Script for drawing the evolution of a neuron kinematics
"""
# Standard libraries
import os
# Third-party libraries
import matplotlib.pyplot as plt
import numpy as np
from scipy import signal


def format_plotting():
    plt.rcParams['figure.figsize'] = (10, 8)
    plt.rcParams['font.size'] = 22
    #    plt.rcParams['font.family'] = 'Times New Roman'
    plt.rcParams['axes.labelsize'] = plt.rcParams['font.size']
    plt.rcParams['axes.titlesize'] = 1.2 * plt.rcParams['font.size']
    plt.rcParams['legend.fontsize'] = 0.7 * plt.rcParams['font.size']
    plt.rcParams['xtick.labelsize'] = 0.6 * plt.rcParams['font.size']
    plt.rcParams['ytick.labelsize'] = 0.6 * plt.rcParams['font.size']
    plt.rcParams['savefig.dpi'] = 1000
    plt.rcParams['savefig.format'] = 'eps'
    plt.rcParams['xtick.major.size'] = 3
    plt.rcParams['xtick.minor.size'] = 3
    plt.rcParams['xtick.major.width'] = 1
    plt.rcParams['xtick.minor.width'] = 1
    plt.rcParams['ytick.major.size'] = 3
    plt.rcParams['ytick.minor.size'] = 3
    plt.rcParams['ytick.major.width'] = 1
    plt.rcParams['ytick.minor.width'] = 1
    plt.rcParams['legend.frameon'] = True
    plt.rcParams['legend.loc'] = 'upper center'
    plt.rcParams['axes.linewidth'] = 1
    plt.rcParams['lines.linewidth'] = 1
    plt.rcParams['lines.markersize'] = 3

    plt.gca().spines['right'].set_color('none')
    plt.gca().spines['top'].set_color('none')
    return


def main():
    """
    Plot the histogram of the firing times of an agent
    """
    # Import and scale data
    data = np.genfromtxt("data/firing_times_u_rest.csv", delimiter=",", skip_header=1)
    n, bins, patches = plt.hist(data, bins=100, range=(0, 2000), edgecolor="k")

    # Set plots layout
    format_plotting()

    script_path = os.path.dirname(os.path.realpath(__file__))
    plt.savefig('{}/results/firing_times.eps'.format(script_path),
                bbox_inches='tight')

    print("Data mean: {}".format(data.mean()))
    print("Data std. deviation: {}".format(data.std()))
    print("Data median: {}".format(np.median(data)))
    plt.show()
    return


if __name__ == "__main__":
    main()
